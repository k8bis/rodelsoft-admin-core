import os
from urllib.parse import urljoin, urlparse

import jwt
import requests
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import Response, JSONResponse
from sqlalchemy import text

from db import SessionLocal

app = FastAPI(title="RodelSoft Dynamic App Router")

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM", "HS256")

if not SECRET_KEY:
    raise RuntimeError("SECRET_KEY no configurada en dynamic-app-router")

HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "content-encoding",
    "content-length",
    "host",
}


# ==========================================================
# Helpers de DB
# ==========================================================

def normalize_public_url(value: str | None) -> str:
    """
    Normaliza public_url para comparación y uso interno.
    Ej:
      '/ext/stocks'   -> '/ext/stocks/'
      'ext/stocks/'   -> '/ext/stocks/'
    """
    if not value:
        return ""

    v = value.strip()

    if not v.startswith("/"):
        v = "/" + v

    if not v.endswith("/"):
        v = v + "/"

    return v


def get_dynamic_apps(db):
    """
    Devuelve todas las apps activas en modo dynamic_proxy.
    Se usará para resolver por prefijo de public_url.
    """
    rows = db.execute(
        text("""
            SELECT
                id,
                name,
                slug,
                internal_url,
                entry_path,
                COALESCE(health_path, '/health') AS health_path,
                COALESCE(is_active, 1) AS is_active,
                COALESCE(launch_mode, 'redirect') AS launch_mode,
                public_url
            FROM applications
            WHERE COALESCE(is_active, 1) = 1
              AND COALESCE(launch_mode, 'redirect') = 'dynamic_proxy'
        """)
    ).mappings().all()

    return rows


def get_app_by_slug(db, slug: str):
    """
    Compatibilidad retro:
    si existe una app antigua que aún dependa de /ext/{slug}/
    y no tiene public_url usable, se puede resolver por slug.
    """
    row = db.execute(
        text("""
            SELECT
                id,
                name,
                slug,
                internal_url,
                entry_path,
                COALESCE(health_path, '/health') AS health_path,
                COALESCE(is_active, 1) AS is_active,
                COALESCE(launch_mode, 'redirect') AS launch_mode,
                public_url
            FROM applications
            WHERE slug = :slug
              AND COALESCE(is_active, 1) = 1
              AND COALESCE(launch_mode, 'redirect') = 'dynamic_proxy'
            LIMIT 1
        """),
        {"slug": slug},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail=f"No existe app dinámica activa para slug='{slug}'")

    return row


def resolve_app_by_request_path(db, request_path: str):
    """
    Resuelve la app por el prefijo MÁS ESPECÍFICO de public_url.

    Ej:
      request_path = '/ext/stocks/'
      public_url   = '/ext/stocks/'        -> match

      request_path = '/ext/stocks/health'
      public_url   = '/ext/stocks/'        -> match

    Si no encuentra por public_url:
      fallback retro a /ext/{slug}/
    """
    apps = get_dynamic_apps(db)

    # 1) Intento principal: match por public_url (prefijo más largo)
    candidates = []

    for row in apps:
        public_url = normalize_public_url(row.get("public_url"))

        if not public_url:
            continue

        if request_path == public_url[:-1] or request_path.startswith(public_url):
            candidates.append((len(public_url), row, public_url))

    if candidates:
        # prefijo más específico / más largo
        candidates.sort(key=lambda x: x[0], reverse=True)
        _, row, public_url = candidates[0]
        return row, public_url

    # 2) Fallback retro: /ext/{slug}/...
    # request_path esperado empieza con /ext/
    prefix = "/ext/"
    if not request_path.startswith(prefix):
        raise HTTPException(status_code=404, detail="Ruta fuera de /ext/")

    remainder = request_path[len(prefix):]  # ej: 'rodel-stocks/health'
    if not remainder:
        raise HTTPException(status_code=404, detail="Ruta /ext/ incompleta")

    slug = remainder.split("/", 1)[0].strip()
    if not slug:
        raise HTTPException(status_code=404, detail="Slug vacío en ruta /ext/")

    row = get_app_by_slug(db, slug)
    derived_public_url = f"/ext/{slug}/"

    return row, derived_public_url


# ==========================================================
# Seguridad / contexto
# ==========================================================

def get_current_user(db, request: Request):
    token = request.cookies.get("jwt")

    if not token:
        auth = request.headers.get("authorization") or request.headers.get("Authorization")
        if auth and auth.lower().startswith("bearer "):
            token = auth[7:].strip()

    if not token:
        raise HTTPException(status_code=401, detail="No autenticado (jwt ausente)")

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except jwt.PyJWTError as e:
        raise HTTPException(status_code=401, detail=f"JWT inválido: {str(e)}")

    username = payload.get("sub")
    if not username:
        raise HTTPException(status_code=401, detail="JWT sin 'sub'")

    row = db.execute(
        text("""
            SELECT id, username
            FROM users
            WHERE username = :username
            LIMIT 1
        """),
        {"username": username},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=401, detail="Usuario no encontrado")

    return row


def user_has_active_membership(db, user_id: int, client_id: int) -> bool:
    row = db.execute(
        text("""
            SELECT 1
            FROM user_client_memberships
            WHERE user_id = :user_id
              AND client_id = :client_id
              AND status = 'active'
            LIMIT 1
        """),
        {
            "user_id": user_id,
            "client_id": client_id,
        },
    ).first()

    return row is not None


def user_has_permission(db, user_id: int, client_id: int, app_id: int) -> bool:
    row = db.execute(
        text("""
            SELECT 1
            FROM permissions
            WHERE user_id = :user_id
              AND client_id = :client_id
              AND app_id = :app_id
            LIMIT 1
        """),
        {
            "user_id": user_id,
            "client_id": client_id,
            "app_id": app_id,
        },
    ).first()

    return row is not None


def has_active_subscription(db, client_id: int, app_id: int) -> bool:
    row = db.execute(
        text("""
            SELECT 1
            FROM client_app_subscriptions
            WHERE client_id = :client_id
              AND app_id = :app_id
              AND is_enabled = 1
              AND status IN ('trial', 'active')
              AND (end_date IS NULL OR end_date >= NOW())
            LIMIT 1
        """),
        {
            "client_id": client_id,
            "app_id": app_id,
        },
    ).first()

    return row is not None


def is_html_navigation_request(request: Request, tail_path: str) -> bool:
    """
    Detecta si la petición parece ser la navegación principal HTML.
    No se usa para assets.
    """
    if request.method.upper() != "GET":
        return False

    accept = (request.headers.get("accept") or "").lower()

    if "text/html" in accept:
        return True

    if not tail_path:
        return True

    return False


# ==========================================================
# Helpers de proxy
# ==========================================================

def strip_public_prefix(request_path: str, public_prefix: str) -> str:
    """
    Convierte:
      request_path='/ext/stocks/'       + public_prefix='/ext/stocks/' => ''
      request_path='/ext/stocks/health' + public_prefix='/ext/stocks/' => 'health'
      request_path='/ext/stocks/docs/'  + public_prefix='/ext/stocks/' => 'docs/'
    """
    public_prefix = normalize_public_url(public_prefix)

    if request_path == public_prefix[:-1]:
        return ""

    if request_path.startswith(public_prefix):
        return request_path[len(public_prefix):]

    raise HTTPException(
        status_code=404,
        detail=f"La ruta '{request_path}' no corresponde al prefijo público '{public_prefix}'",
    )

def build_target_url(
    internal_url: str,
    tail_path: str,
    query_string: str | None = None,
    public_prefix: str | None = None,
) -> str:
    """
    Construye URL destino para backend interno.

    En la implementación ACTUAL de rodel-stocks, la app interna todavía
    espera el prefijo público (/ext/stocks/) también en el backend.

    Por eso:
    - /ext/stocks        -> internal_url + /ext/stocks/
    - /ext/stocks/       -> internal_url + /ext/stocks/
    - /ext/stocks/health -> internal_url + /ext/stocks/health
    """
    base = (internal_url or "").strip()
    if not base:
        raise HTTPException(status_code=500, detail="internal_url vacío")

    base = base.rstrip("/")

    normalized_public = normalize_public_url(public_prefix or "")
    public_no_leading = normalized_public.lstrip("/").rstrip("/")

    tail = (tail_path or "").lstrip("/")

    if public_no_leading:
        if not tail:
            target = f"{base}/{public_no_leading}/"
        else:
            target = f"{base}/{public_no_leading}/{tail}"
    else:
        if not tail:
            target = f"{base}/"
        else:
            target = f"{base}/{tail}"

    if query_string:
        target = f"{target}?{query_string}"

    return target

def filter_request_headers(request: Request, app_id: int, public_prefix: str):
    headers = {}

    for key, value in request.headers.items():
        k = key.lower()
        if k in HOP_BY_HOP_HEADERS:
            continue
        headers[key] = value

    # Contexto útil hacia la app destino
    headers["X-Rodel-App-Id"] = str(app_id)
    headers["X-Forwarded-Prefix"] = normalize_public_url(public_prefix)[:-1]  # sin slash final
    headers["X-Forwarded-Host"] = request.headers.get("host", "")
    headers["X-Forwarded-Proto"] = request.headers.get("x-forwarded-proto", request.url.scheme)

    return headers


def rewrite_location(value: str, public_prefix: str, internal_url: str) -> str:
    """
    Reescribe redirects emitidos por la app destino.

    Casos:
      '/login'                           -> '/ext/stocks/login'
      'login'                            -> '/ext/stocks/login'
      '/'                                -> '/ext/stocks/'
      'http://172.30.0.1:8091/ext/stocks/' -> '/ext/stocks/'
      'http://172.30.0.1:8091/login'       -> '/ext/stocks/login'

    Si es absoluta pero NO pertenece al mismo backend interno, se deja intacta.
    """
    if not value:
        return value

    prefix = normalize_public_url(public_prefix)[:-1]  # '/ext/stocks'
    internal_base = (internal_url or "").rstrip("/")

    # ----------------------------------------------------------
    # 1) URL absoluta: si apunta al MISMO backend interno, reescribir
    # ----------------------------------------------------------
    lower = value.lower()
    if lower.startswith("http://") or lower.startswith("https://"):
        parsed_value = urlparse(value)
        parsed_internal = urlparse(internal_base)

        same_origin = (
            parsed_value.scheme == parsed_internal.scheme
            and parsed_value.netloc == parsed_internal.netloc
        )

        if not same_origin:
            return value

        backend_path = parsed_value.path or "/"

        # Caso exacto raíz interna -> prefijo público
        if backend_path == "/" or backend_path == "":
            rewritten = prefix + "/"
        else:
            # Si backend ya devuelve /ext/stocks/... no duplicar prefijo
            normalized_public = normalize_public_url(public_prefix)
            if backend_path == normalized_public[:-1] or backend_path.startswith(normalized_public):
                rewritten = backend_path
            else:
                rewritten = prefix + (backend_path if backend_path.startswith("/") else f"/{backend_path}")

        if parsed_value.query:
            rewritten += f"?{parsed_value.query}"

        return rewritten

    # ----------------------------------------------------------
    # 2) URL relativa / absoluta-path
    # ----------------------------------------------------------
    if value == "/":
        return prefix + "/"

    if value.startswith("/"):
        normalized_public = normalize_public_url(public_prefix)
        if value == normalized_public[:-1] or value.startswith(normalized_public):
            return value
        return prefix + value

    return prefix + "/" + value

# ==========================================================
# Endpoints
# ==========================================================

@app.get("/health")
def health():
    return {"ok": True, "service": "dynamic-app-router"}


@app.api_route("/ext/{full_path:path}", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
@app.api_route("/ext", methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS", "HEAD"])
async def dynamic_proxy(request: Request, full_path: str = ""):
    db = SessionLocal()

    try:
        request_path = request.url.path

        app_row, public_prefix = resolve_app_by_request_path(db, request_path)

        internal_url = (app_row["internal_url"] or "").strip()
        app_id = int(app_row["id"])

        if not internal_url:
            raise HTTPException(status_code=500, detail="La aplicación no tiene internal_url configurado")

        tail_path = strip_public_prefix(request_path, public_prefix)

        # Blindaje FASE 6.0.A:
        # Solo exigir contexto/seguridad en navegación HTML principal.
        if is_html_navigation_request(request, tail_path):
            client_id_raw = request.query_params.get("client_id")
            app_id_raw = request.query_params.get("app_id")

            if not client_id_raw or not app_id_raw:
                raise HTTPException(status_code=400, detail="Falta contexto app_id/client_id")

            try:
                client_id = int(client_id_raw)
                requested_app_id = int(app_id_raw)
            except ValueError:
                raise HTTPException(status_code=400, detail="Contexto app_id/client_id inválido")

            if requested_app_id != app_id:
                raise HTTPException(status_code=400, detail="app_id no corresponde a la app resuelta")

            user = get_current_user(db, request)
            user_id = int(user["id"])

            if not user_has_active_membership(db, user_id, client_id):
                raise HTTPException(status_code=403, detail="Sin membresía activa para ese cliente")

            if not user_has_permission(db, user_id, client_id, app_id):
                raise HTTPException(status_code=403, detail="Sin permiso para esa app/cliente")

            if not has_active_subscription(db, client_id, app_id):
                raise HTTPException(status_code=403, detail="Suscripción inactiva para esa app/cliente")

        target_url = build_target_url(
            internal_url=internal_url,
            tail_path=tail_path,
            query_string=request.url.query,
            public_prefix=public_prefix,
        )
        
        print(f"[dynamic-app-router] request_path={request_path} public_prefix={public_prefix} tail_path={tail_path} -> target_url={target_url}")

        body = await request.body()

        headers = filter_request_headers(request, app_id, public_prefix)

        resp = requests.request(
            method=request.method,
            url=target_url,
            headers=headers,
            data=body if body else None,
            cookies=request.cookies,
            allow_redirects=False,
            timeout=30,
        )
        
        current_public_url = request.url.path
        if request.url.query:
            current_public_url = f"{current_public_url}?{request.url.query}"

        response_headers = {}
        for key, value in resp.headers.items():
            k = key.lower()
            if k in HOP_BY_HOP_HEADERS:
                continue

            if k == "location":
                original_location = value
                value = rewrite_location(value, public_prefix, internal_url)
                print(f"[dynamic-app-router] upstream Location: {original_location} -> rewritten: {value}")

                # Evitar loop de redirect al mismo recurso público
                if value == current_public_url:
                    print(f"[dynamic-app-router] Redirect loop detectado. Se elimina Location idéntico: {value}")
                    continue
                
            response_headers[key] = value

        return Response(
            content=resp.content,
            status_code=resp.status_code,
            headers=response_headers,
            media_type=resp.headers.get("content-type"),
        )

    except HTTPException:
        raise
    except requests.RequestException as e:
        print(f"[dynamic-app-router] Error proxy: {e}")
        return JSONResponse(
            status_code=502,
            content={"ok": False, "detail": f"Error conectando a app destino: {str(e)}"},
        )
    except Exception as e:
        print(f"[dynamic-app-router] ERROR inesperado: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno dynamic-app-router: {str(e)}")
    finally:
        db.close()
