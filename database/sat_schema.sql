-- =========================================================
-- SAT CFDI 4.0 - CATALOGOS NORMALIZADOS
-- Tablas:
--   1) sat_regimen_fiscal
--   2) sat_uso_cfdi
--   3) sat_uso_cfdi_regimen
-- Vista:
--   1) vw_sat_uso_cfdi_con_regimenes
-- =========================================================

-- =========================================================
-- LIMPIEZA (opcional si estas recreando)
-- =========================================================
DROP VIEW IF EXISTS vw_sat_uso_cfdi_con_regimenes;

DROP TABLE IF EXISTS sat_uso_cfdi_regimen;
DROP TABLE IF EXISTS sat_uso_cfdi;
DROP TABLE IF EXISTS sat_regimen_fiscal;

-- =========================================================
-- 1) TABLA: sat_regimen_fiscal
-- =========================================================
CREATE TABLE sat_regimen_fiscal (
    c_regimen_fiscal VARCHAR(3) NOT NULL PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    aplica_fisica TINYINT(1) NOT NULL DEFAULT 0,
    aplica_moral TINYINT(1) NOT NULL DEFAULT 0,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2) TABLA: sat_uso_cfdi
-- =========================================================
CREATE TABLE sat_uso_cfdi (
    c_uso_cfdi VARCHAR(5) NOT NULL PRIMARY KEY,
    descripcion VARCHAR(255) NOT NULL,
    aplica_fisica TINYINT(1) NOT NULL DEFAULT 0,
    aplica_moral TINYINT(1) NOT NULL DEFAULT 0,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 3) TABLA: sat_uso_cfdi_regimen
-- Relacion N:M entre uso CFDI y regimen fiscal receptor
-- =========================================================
CREATE TABLE sat_uso_cfdi_regimen (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    c_uso_cfdi VARCHAR(5) NOT NULL,
    c_regimen_fiscal VARCHAR(3) NOT NULL,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT uq_sat_uso_cfdi_regimen UNIQUE (c_uso_cfdi, c_regimen_fiscal),

    CONSTRAINT fk_sat_uso_cfdi_regimen_uso
        FOREIGN KEY (c_uso_cfdi)
        REFERENCES sat_uso_cfdi(c_uso_cfdi)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_sat_uso_cfdi_regimen_regimen
        FOREIGN KEY (c_regimen_fiscal)
        REFERENCES sat_regimen_fiscal(c_regimen_fiscal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_sat_uso_cfdi_regimen_regimen ON sat_uso_cfdi_regimen (c_regimen_fiscal);
CREATE INDEX idx_sat_uso_cfdi_regimen_uso ON sat_uso_cfdi_regimen (c_uso_cfdi);

-- =========================================================
-- VISTA: consulta agregada de regimenes por uso CFDI
-- =========================================================
CREATE VIEW vw_sat_uso_cfdi_con_regimenes AS
SELECT
    u.c_uso_cfdi,
    u.descripcion,
    u.aplica_fisica,
    u.aplica_moral,
    u.fecha_inicio_vigencia,
    u.fecha_fin_vigencia,
    GROUP_CONCAT(ur.c_regimen_fiscal ORDER BY ur.c_regimen_fiscal SEPARATOR ',') AS regimenes_csv
FROM sat_uso_cfdi u
LEFT JOIN sat_uso_cfdi_regimen ur
    ON ur.c_uso_cfdi = u.c_uso_cfdi
GROUP BY
    u.c_uso_cfdi,
    u.descripcion,
    u.aplica_fisica,
    u.aplica_moral,
    u.fecha_inicio_vigencia,
    u.fecha_fin_vigencia;

-- =========================================================
-- CONSULTA UTIL PARA POS:
-- Obtener usos CFDI validos por tipo persona + regimen fiscal
-- Ejemplo PF / regimen 612
-- =========================================================
-- SELECT
--     u.c_uso_cfdi,
--     u.descripcion
-- FROM sat_uso_cfdi u
-- INNER JOIN sat_uso_cfdi_regimen ur
--     ON ur.c_uso_cfdi = u.c_uso_cfdi
-- INNER JOIN sat_regimen_fiscal r
--     ON r.c_regimen_fiscal = ur.c_regimen_fiscal
-- WHERE ur.c_regimen_fiscal = '612'
--   AND (
--         ('FISICA' = 'FISICA' AND u.aplica_fisica = 1)
--         OR
--         ('FISICA' = 'MORAL' AND u.aplica_moral = 1)
--       )
--   AND u.fecha_inicio_vigencia <= CURDATE()
--   AND (u.fecha_fin_vigencia IS NULL OR u.fecha_fin_vigencia >= CURDATE())
-- ORDER BY u.c_uso_cfdi;