-- =====================================================================
-- RodelSoft Admin - 00-init.sql
-- Bootstrap oficial Fase 4.3 + INV-2A
-- Crea DB de Control Plane + DB de POS + DB de Stocks
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '-06:00';

-- Control Plane DB
CREATE DATABASE IF NOT EXISTS proyecto_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- POS DB
CREATE DATABASE IF NOT EXISTS pos_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

-- Stocks DB
CREATE DATABASE IF NOT EXISTS stocks_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

GRANT ALL PRIVILEGES ON pos_db.* TO 'proyecto_user'@'%';
GRANT ALL PRIVILEGES ON stocks_db.* TO 'proyecto_user'@'%';

FLUSH PRIVILEGES;