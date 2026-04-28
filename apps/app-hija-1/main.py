# apps/app-hija-1/main.py
import time
from fastapi import FastAPI
from sqlalchemy import text

from db import engine, wait_for_db

from routes.public import router as public_router
from routes.internal import router as internal_router
from routes.admin import router as admin_router


app = FastAPI(title="App Hija 1 - FastAPI")

@app.on_event("startup")
def _startup():
    try:
        wait_for_db()
    except Exception as e:
        print(f"[startup] DB no disponible: {e}")
        raise

app.include_router(public_router)
app.include_router(internal_router)
app.include_router(admin_router)
