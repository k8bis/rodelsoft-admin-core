-- =====================================================================
-- RodelSoft Admin - 55-migrate_pos_v2_initial.sql
-- Migración estructural POS -> INV-3B FINAL
-- Solo para entornos existentes (si NO se recrea pos_db)
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '-06:00';

USE pos_db;

-- =====================================================================
-- 1) pos_client_settings -> modelo oficial limpio
-- =====================================================================

-- 1.1) asegurar catalog_source + catalog_integration_url
ALTER TABLE pos_client_settings
  ADD COLUMN IF NOT EXISTS catalog_source ENUM('pos','stocks') NOT NULL DEFAULT 'pos'
  AFTER ticket_footer_text,
  ADD COLUMN IF NOT EXISTS catalog_integration_url VARCHAR(500) NULL
  AFTER catalog_source;

-- 1.2) eliminar banderas obsoletas del modelo previo
ALTER TABLE pos_client_settings
  DROP COLUMN IF EXISTS inventory_integration_enabled,
  DROP COLUMN IF EXISTS default_inventory_mode;

-- =====================================================================
-- 1.3) pos_sales -> snapshots de contexto de venta
-- =====================================================================
ALTER TABLE pos_sales
  ADD COLUMN IF NOT EXISTS catalog_source_snapshot ENUM('pos','stocks') NOT NULL DEFAULT 'pos'
  AFTER cashier_name_snapshot,
  ADD COLUMN IF NOT EXISTS catalog_integration_url_snapshot VARCHAR(500) NULL
  AFTER catalog_source_snapshot;

-- =====================================================================
-- 2) pos_prices -> crear catálogo comercial general
-- =====================================================================
CREATE TABLE IF NOT EXISTS pos_prices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  catalog_source ENUM('pos','stocks') NOT NULL,
  catalog_item_id INT NOT NULL,

  display_name_snapshot VARCHAR(200) NOT NULL,
  sku_snapshot VARCHAR(50) NULL,
  category_name_snapshot VARCHAR(150) NULL,

  product_type_snapshot ENUM('physical','service') NOT NULL DEFAULT 'physical',
  inventory_mode_snapshot ENUM('pos_legacy','stocks_api','none') NOT NULL DEFAULT 'pos_legacy',
  stock_item_id_snapshot INT NULL,

  sale_price DECIMAL(12,2) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_pos_prices_client_source_item (client_id, catalog_source, catalog_item_id),
  KEY idx_pos_prices_client (client_id),
  KEY idx_pos_prices_client_active (client_id, is_active),
  KEY idx_pos_prices_client_source (client_id, catalog_source),
  KEY idx_pos_prices_client_stock_item (client_id, stock_item_id_snapshot)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 2.1) Si la tabla ya existía con columna price, renombrar a sale_price
-- =====================================================================
SET @has_price := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_prices'
    AND COLUMN_NAME = 'price'
);

SET @has_sale_price := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_prices'
    AND COLUMN_NAME = 'sale_price'
);

SET @sql := IF(
  @has_price > 0 AND @has_sale_price = 0,
  'ALTER TABLE pos_prices CHANGE COLUMN price sale_price DECIMAL(12,2) NOT NULL',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================================
-- 2.2) Si existía is_sellable en pos_prices, eliminarla
-- =====================================================================
SET @has_is_sellable_pp := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_prices'
    AND COLUMN_NAME = 'is_sellable'
);

SET @sql := IF(
  @has_is_sellable_pp > 0,
  'ALTER TABLE pos_prices DROP COLUMN is_sellable',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================================
-- 3) Backfill simple desde pos_products -> pos_prices
-- (solo si existen productos y aún no existen precios)
-- =====================================================================
INSERT INTO pos_prices (
  client_id,
  catalog_source,
  catalog_item_id,
  display_name_snapshot,
  sku_snapshot,
  category_name_snapshot,
  product_type_snapshot,
  inventory_mode_snapshot,
  stock_item_id_snapshot,
  sale_price,
  is_active
)
SELECT
  p.client_id,
  'pos',
  p.id,
  p.name,
  p.sku,
  c.name,
  COALESCE(p.product_type, 'physical'),
  COALESCE(p.inventory_mode, 'pos_legacy'),
  p.stock_item_id,
  0.00,
  COALESCE(p.is_active, 1)
FROM pos_products p
LEFT JOIN pos_categories c
  ON c.id = p.category_id
LEFT JOIN pos_prices pp
  ON pp.client_id = p.client_id
 AND pp.catalog_source = 'pos'
 AND pp.catalog_item_id = p.id
WHERE pp.id IS NULL;

-- =====================================================================
-- 4) Reestructurar pos_sale_items:
--    - eliminar FK vieja a pos_products
--    - agregar pos_price_id + snapshots nuevos
-- =====================================================================

-- 4.1 agregar columnas nuevas
ALTER TABLE pos_sale_items
  ADD COLUMN IF NOT EXISTS pos_price_id INT NULL AFTER sale_id,
  ADD COLUMN IF NOT EXISTS catalog_source ENUM('pos','stocks') NOT NULL DEFAULT 'pos' AFTER pos_price_id,
  ADD COLUMN IF NOT EXISTS catalog_item_id INT NOT NULL DEFAULT 0 AFTER catalog_source,
  ADD COLUMN IF NOT EXISTS catalog_source_snapshot ENUM('pos','stocks') NOT NULL DEFAULT 'pos' AFTER catalog_item_id,
  ADD COLUMN IF NOT EXISTS catalog_item_id_snapshot INT NOT NULL DEFAULT 0 AFTER catalog_source_snapshot,
  ADD COLUMN IF NOT EXISTS category_name_snapshot VARCHAR(150) NULL AFTER sku_snapshot;

-- 4.2 intentar mapear ventas viejas a pos_prices por producto POS
UPDATE pos_sale_items psi
INNER JOIN pos_products p
  ON p.id = psi.product_id
INNER JOIN pos_prices pp
  ON pp.client_id = p.client_id
 AND pp.catalog_source = 'pos'
 AND pp.catalog_item_id = p.id
SET
  psi.pos_price_id = pp.id,
  psi.catalog_source = 'pos',
  psi.catalog_item_id = p.id,
  psi.catalog_source_snapshot = 'pos',
  psi.catalog_item_id_snapshot = p.id
WHERE psi.pos_price_id IS NULL;

-- 4.3 si quedaron nulos (por datos inconsistentes demo), forzar con primer precio del cliente si existe
UPDATE pos_sale_items psi
INNER JOIN pos_sales s
  ON s.id = psi.sale_id
INNER JOIN (
  SELECT client_id, MIN(id) AS fallback_pos_price_id
  FROM pos_prices
  GROUP BY client_id
) fb
  ON fb.client_id = s.client_id
SET psi.pos_price_id = fb.fallback_pos_price_id
WHERE psi.pos_price_id IS NULL;

-- 4.4 quitar FK vieja si existe (nota: puede requerir nombre exacto en algunos entornos)
SET @fk_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_sale_items'
    AND CONSTRAINT_NAME = 'fk_pos_sale_items_product'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql := IF(
  @fk_exists > 0,
  'ALTER TABLE pos_sale_items DROP FOREIGN KEY fk_pos_sale_items_product',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4.5 quitar columna vieja product_id si existe
SET @has_product_id := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_sale_items'
    AND COLUMN_NAME = 'product_id'
);

SET @sql := IF(
  @has_product_id > 0,
  'ALTER TABLE pos_sale_items DROP COLUMN product_id',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4.6 hacer obligatoria la nueva FK
ALTER TABLE pos_sale_items
  MODIFY COLUMN pos_price_id INT NOT NULL;

-- 4.7 crear FK si no existe
SET @fk_pos_price_exists := (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_sale_items'
    AND CONSTRAINT_NAME = 'fk_pos_sale_items_pos_price'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
);

SET @sql := IF(
  @fk_pos_price_exists = 0,
  'ALTER TABLE pos_sale_items ADD CONSTRAINT fk_pos_sale_items_pos_price FOREIGN KEY (pos_price_id) REFERENCES pos_prices(id) ON DELETE RESTRICT',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4.8 índice para reporteo multi-source
SET @idx_exists := (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_sale_items'
    AND INDEX_NAME = 'idx_pos_sale_items_catalog_source_item'
);

SET @sql := IF(
  @idx_exists = 0,
  'ALTER TABLE pos_sale_items ADD KEY idx_pos_sale_items_catalog_source_item (catalog_source, catalog_item_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4.9 backfill defensivo para columnas nuevas si quedaron en 0
UPDATE pos_sale_items
SET
  catalog_source = catalog_source_snapshot,
  catalog_item_id = catalog_item_id_snapshot
WHERE catalog_item_id = 0;

-- =====================================================================
-- 5) Limpiar pos_products: quitar columnas obsoletas si existen
-- =====================================================================
SET @has_product_price := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_products'
    AND COLUMN_NAME = 'price'
);

SET @sql := IF(
  @has_product_price > 0,
  'ALTER TABLE pos_products DROP COLUMN price',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_product_is_sellable := (
  SELECT COUNT(*)
  FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'pos_products'
    AND COLUMN_NAME = 'is_sellable'
);

SET @sql := IF(
  @has_product_is_sellable > 0,
  'ALTER TABLE pos_products DROP COLUMN is_sellable',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- =====================================================================
-- 6) Seed defensivo de settings faltantes
-- =====================================================================
INSERT INTO pos_client_settings (
  client_id,
  company_display_name,
  ticket_footer_text,
  inventory_integration_enabled,
  default_inventory_mode,
  catalog_source
)
SELECT DISTINCT
  p.client_id,
  'RodelSoft',
  'Gracias por su compra',
  0,
  'pos_legacy',
  'pos'
FROM pos_products p
LEFT JOIN pos_client_settings s
  ON s.client_id = p.client_id
WHERE s.id IS NULL;

-- =====================================================================
-- 7) Backfill de pos_sales snapshots de contexto
-- =====================================================================
UPDATE pos_sales s
SET
  s.catalog_source_snapshot = COALESCE(
    (
      SELECT psi.catalog_source_snapshot
      FROM pos_sale_items psi
      WHERE psi.sale_id = s.id
      ORDER BY psi.id ASC
      LIMIT 1
    ),
    'pos'
  )
WHERE s.catalog_source_snapshot IS NULL
   OR s.catalog_source_snapshot = '';