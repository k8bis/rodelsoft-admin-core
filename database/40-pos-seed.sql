-- =====================================================================
-- RodelSoft Admin - 40-pos-seed.sql
-- Seed oficial POS DB (INV-3B FINAL)
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '-06:00';

USE pos_db;

-- =====================================================================
-- CATEGORÍAS DEMO
-- =====================================================================
INSERT INTO pos_categories (
  id,
  client_id,
  name,
  description,
  color,
  is_active
) VALUES
  (1, 4, 'Bebidas', 'Bebidas y refrescos', '#0066FF', 1),
  (2, 4, 'Snacks', 'Botanas y snacks', '#10B981', 1)
ON DUPLICATE KEY UPDATE
  client_id = VALUES(client_id),
  name = VALUES(name),
  description = VALUES(description),
  color = VALUES(color),
  is_active = VALUES(is_active);

-- =====================================================================
-- SETTINGS DEMO
-- =====================================================================
INSERT INTO pos_client_settings (
  id,
  client_id,
  company_display_name,
  ticket_footer_text,
  inventory_integration_enabled,
  default_inventory_mode,
  catalog_source
) VALUES
  (1, 4, 'RodelSoft Demo', 'Gracias por su compra', 0, 'pos_legacy', 'pos')
ON DUPLICATE KEY UPDATE
  company_display_name = VALUES(company_display_name),
  ticket_footer_text = VALUES(ticket_footer_text),
  inventory_integration_enabled = VALUES(inventory_integration_enabled),
  default_inventory_mode = VALUES(default_inventory_mode),
  catalog_source = VALUES(catalog_source);

-- =====================================================================
-- PRODUCTOS BASE POS (SIN PRECIO / SIN is_sellable)
-- =====================================================================
INSERT INTO pos_products (
  id,
  client_id,
  name,
  description,
  product_type,
  track_inventory,
  inventory_mode,
  stock_item_id,
  cost,
  sku,
  barcode,
  category_id,
  stock_quantity,
  min_stock,
  is_active,
  image_url
) VALUES
  (
    1, 4, 'Coca Cola', 'Refresco 355ml',
    'physical', 1, 'pos_legacy', NULL,
    9.00, '1212', '1212', 1, 84.000, 10.000, 1, NULL
  ),
  (
    2, 4, 'Sprite', 'Refresco 355ml',
    'physical', 1, 'pos_legacy', NULL,
    9.00, '1213', '1213', 1, 92.000, 10.000, 1, NULL
  ),
  (
    3, 4, 'Chaparrita', 'Refresco 355ml',
    'physical', 1, 'pos_legacy', NULL,
    9.00, '1211', '1211', 1, 90.000, 10.000, 1, NULL
  ),
  (
    4, 4, 'Pepsi', 'Refresco 355ml',
    'physical', 1, 'pos_legacy', NULL,
    9.00, '1200', '1200', 1, 95.000, 10.000, 1, NULL
  ),
  (
    5, 4, 'Papas Clásicas', 'Bolsa de papas 45g',
    'physical', 1, 'pos_legacy', NULL,
    12.00, 'SNK001', 'SNK001', 2, 50.000, 8.000, 1, NULL
  ),
  (
    6, 4, 'Promo Cortesía', 'Artículo de regalo / cortesía',
    'service', 0, 'none', NULL,
    0.00, 'FREE001', 'FREE001', 2, 0.000, 0.000, 1, NULL
  )
ON DUPLICATE KEY UPDATE
  client_id = VALUES(client_id),
  name = VALUES(name),
  description = VALUES(description),
  product_type = VALUES(product_type),
  track_inventory = VALUES(track_inventory),
  inventory_mode = VALUES(inventory_mode),
  stock_item_id = VALUES(stock_item_id),
  cost = VALUES(cost),
  sku = VALUES(sku),
  barcode = VALUES(barcode),
  category_id = VALUES(category_id),
  stock_quantity = VALUES(stock_quantity),
  min_stock = VALUES(min_stock),
  is_active = VALUES(is_active),
  image_url = VALUES(image_url);

-- =====================================================================
-- CATÁLOGO COMERCIAL GENERAL (POS local demo)
-- FUENTE DE VENTA PARA EL POS
-- =====================================================================
INSERT INTO pos_prices (
  id,
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
) VALUES
  (1, 4, 'pos', 1, 'Coca Cola', '1212', 'Bebidas', 'physical', 'pos_legacy', NULL, 10.00, 1),
  (2, 4, 'pos', 2, 'Sprite', '1213', 'Bebidas', 'physical', 'pos_legacy', NULL, 10.00, 1),
  (3, 4, 'pos', 3, 'Chaparrita', '1211', 'Bebidas', 'physical', 'pos_legacy', NULL, 10.00, 1),
  (4, 4, 'pos', 4, 'Pepsi', '1200', 'Bebidas', 'physical', 'pos_legacy', NULL, 10.00, 1),
  (5, 4, 'pos', 5, 'Papas Clásicas', 'SNK001', 'Snacks', 'physical', 'pos_legacy', NULL, 18.00, 1),
  (6, 4, 'pos', 6, 'Promo Cortesía', 'FREE001', 'Snacks', 'service', 'none', NULL, 0.00, 1)
ON DUPLICATE KEY UPDATE
  client_id = VALUES(client_id),
  catalog_source = VALUES(catalog_source),
  catalog_item_id = VALUES(catalog_item_id),
  display_name_snapshot = VALUES(display_name_snapshot),
  sku_snapshot = VALUES(sku_snapshot),
  category_name_snapshot = VALUES(category_name_snapshot),
  product_type_snapshot = VALUES(product_type_snapshot),
  inventory_mode_snapshot = VALUES(inventory_mode_snapshot),
  stock_item_id_snapshot = VALUES(stock_item_id_snapshot),
  sale_price = VALUES(sale_price),
  is_active = VALUES(is_active);