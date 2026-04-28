-- =====================================================================
-- RodelSoft Admin - 30-pos-schema.sql
-- POS DB - Esquema oficial limpio (INV-3B FINAL)
-- Fuente de verdad para ambientes nuevos
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '-06:00';

CREATE DATABASE IF NOT EXISTS pos_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE pos_db;

-- =====================================================================
-- LIMPIEZA CONTROLADA (solo para recreación de ambiente POS)
-- =====================================================================
DROP TABLE IF EXISTS pos_sale_items;
DROP TABLE IF EXISTS pos_sales;
DROP TABLE IF EXISTS pos_prices;
DROP TABLE IF EXISTS pos_client_settings;
DROP TABLE IF EXISTS pos_inventory_movements;
DROP TABLE IF EXISTS pos_products;
DROP TABLE IF EXISTS pos_categories;

-- =====================================================================
-- CATEGORÍAS POS (origen local POS)
-- =====================================================================
CREATE TABLE pos_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL DEFAULT 1,
  name VARCHAR(100) NOT NULL,
  description TEXT NULL,
  color VARCHAR(7) NOT NULL DEFAULT '#0066FF',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_pos_categories_client_name (client_id, name),
  KEY idx_pos_categories_client (client_id),
  KEY idx_pos_categories_client_active (client_id, is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- PRODUCTOS POS (solo origen local POS, NO catálogo comercial final)
-- =====================================================================
CREATE TABLE pos_products (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL DEFAULT 1,

  name VARCHAR(200) NOT NULL,
  description TEXT NULL,

  product_type ENUM('physical','service') NOT NULL DEFAULT 'physical',
  track_inventory TINYINT(1) NOT NULL DEFAULT 1,
  inventory_mode ENUM('pos_legacy','stocks_api','none') NOT NULL DEFAULT 'pos_legacy',
  stock_item_id INT NULL,

  cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  sku VARCHAR(50) NULL,
  barcode VARCHAR(50) NULL,
  category_id INT NULL,
  stock_quantity DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  min_stock DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  image_url VARCHAR(500) NULL,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_pos_products_category
    FOREIGN KEY (category_id) REFERENCES pos_categories(id)
    ON DELETE SET NULL,

  UNIQUE KEY uq_pos_products_client_sku (client_id, sku),
  UNIQUE KEY uq_pos_products_client_barcode (client_id, barcode),
  KEY idx_pos_products_client (client_id),
  KEY idx_pos_products_client_active (client_id, is_active),
  KEY idx_pos_products_client_category (client_id, category_id),
  KEY idx_pos_products_client_stock_item (client_id, stock_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- SETTINGS POR CLIENTE
-- =====================================================================
CREATE TABLE pos_client_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,

  company_display_name VARCHAR(200) NULL,
  ticket_footer_text TEXT NULL,

  -- FUENTE DE VERDAD DEL ORIGEN MAESTRO DEL CATÁLOGO
  catalog_source ENUM('pos','stocks') NOT NULL DEFAULT 'pos',

  -- URL base viva del servicio Stocks por cliente
  -- Solo aplica cuando catalog_source = 'stocks'
  catalog_integration_url VARCHAR(500) NULL,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_pos_client_settings_client (client_id),
  KEY idx_pos_client_settings_catalog_source (catalog_source)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- CATÁLOGO COMERCIAL GENERAL / PRECIOS DE VENTA
-- FUENTE DE VERDAD COMERCIAL PARA POS
-- =====================================================================
CREATE TABLE pos_prices (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,

  -- origen real del ítem
  catalog_source ENUM('pos','stocks') NOT NULL,
  catalog_item_id INT NOT NULL,

  -- snapshots comerciales mínimos para no depender totalmente del origen
  display_name_snapshot VARCHAR(200) NOT NULL,
  sku_snapshot VARCHAR(50) NULL,
  category_name_snapshot VARCHAR(150) NULL,

  product_type_snapshot ENUM('physical','service') NOT NULL DEFAULT 'physical',
  inventory_mode_snapshot ENUM('pos_legacy','stocks_api','none') NOT NULL DEFAULT 'pos_legacy',
  stock_item_id_snapshot INT NULL,

  -- precio comercial
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
-- VENTAS
-- =====================================================================
CREATE TABLE pos_sales (
  id INT AUTO_INCREMENT PRIMARY KEY,

  sale_number VARCHAR(50) NOT NULL,

  client_id INT NOT NULL,
  app_id INT NOT NULL,
  created_by VARCHAR(100) NOT NULL,

  subtotal_snapshot DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_snapshot DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_snapshot DECIMAL(12,2) NOT NULL DEFAULT 0.00,

  customer_name_snapshot VARCHAR(200) NULL,
  cashier_name_snapshot VARCHAR(200) NULL,
  -- snapshot de contexto de origen del catálogo al momento de la venta
  catalog_source_snapshot ENUM('pos','stocks') NOT NULL DEFAULT 'pos',
  catalog_integration_url_snapshot VARCHAR(500) NULL,

  total_amount DECIMAL(12,2) NOT NULL,
  tax_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  payment_method VARCHAR(50) NOT NULL DEFAULT 'cash',
  status VARCHAR(20) NOT NULL DEFAULT 'completed',
  notes TEXT NULL,

  cancelled_at DATETIME NULL,
  cancelled_by VARCHAR(100) NULL,
  cancellation_reason VARCHAR(255) NULL,
  inventory_reverted_at DATETIME NULL,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_pos_sales_sale_number (sale_number),
  KEY idx_pos_sales_client (client_id),
  KEY idx_pos_sales_client_created (client_id, created_at),
  KEY idx_pos_sales_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- DETALLE DE VENTA
-- LIGA A pos_prices (NO a pos_products)
-- =====================================================================
CREATE TABLE pos_sale_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT NOT NULL,

  -- NUEVO MODELO INV-3B
  pos_price_id INT NOT NULL,

  -- referencia explícita del origen e ítem vendido (además del pos_price_id)
  catalog_source ENUM('pos','stocks') NOT NULL,
  catalog_item_id INT NOT NULL,

  -- snapshots transaccionales
  catalog_source_snapshot ENUM('pos','stocks') NOT NULL,
  catalog_item_id_snapshot INT NOT NULL,

  product_name_snapshot VARCHAR(200) NOT NULL,
  sku_snapshot VARCHAR(50) NULL,
  category_name_snapshot VARCHAR(150) NULL,
  product_type_snapshot ENUM('physical','service') NOT NULL DEFAULT 'physical',
  inventory_mode_snapshot ENUM('pos_legacy','stocks_api','none') NOT NULL DEFAULT 'pos_legacy',
  stock_item_id_snapshot INT NULL,

  quantity DECIMAL(12,3) NOT NULL,
  unit_price_snapshot DECIMAL(12,2) NOT NULL,
  line_total_snapshot DECIMAL(12,2) NOT NULL,

  -- compatibilidad visual / reporteo interno
  unit_price DECIMAL(12,2) NOT NULL,
  total_price DECIMAL(12,2) NOT NULL,

  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_pos_sale_items_sale
    FOREIGN KEY (sale_id) REFERENCES pos_sales(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_pos_sale_items_pos_price
    FOREIGN KEY (pos_price_id) REFERENCES pos_prices(id)
    ON DELETE RESTRICT,

  KEY idx_pos_sale_items_sale (sale_id),
  KEY idx_pos_sale_items_pos_price (pos_price_id),
  KEY idx_pos_sale_items_stock_item (stock_item_id_snapshot)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;