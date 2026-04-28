-- =====================================================================
-- RodelSoft Admin - 60-stocks-schema.sql
-- FASE INV-2A
-- Esquema base oficial de stocks_db para Rodel-Stocks v1
-- =====================================================================

SET NAMES utf8mb4;
SET time_zone = '-06:00';

USE stocks_db;

-- =====================================================================
-- 1) CATEGORÍAS DE INVENTARIO
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY uq_stock_categories_client_name (client_id, name),
  KEY idx_stock_categories_client (client_id),
  KEY idx_stock_categories_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 2) ITEMS DE INVENTARIO / SERVICIOS
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  category_id INT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT NULL,
  item_type ENUM('physical','service') NOT NULL,
  brand VARCHAR(100) NULL,
  model VARCHAR(100) NULL,
  color VARCHAR(50) NULL,
  sku VARCHAR(50) NULL,
  barcode VARCHAR(50) NULL,
  track_inventory TINYINT(1) NOT NULL DEFAULT 1,
  is_sellable TINYINT(1) NOT NULL DEFAULT 1,
  is_purchasable TINYINT(1) NOT NULL DEFAULT 1,
  unit_of_measure VARCHAR(30) NOT NULL DEFAULT 'piece',
  min_stock DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_stock_items_category
    FOREIGN KEY (category_id) REFERENCES stock_categories(id)
    ON DELETE SET NULL,

  UNIQUE KEY uq_stock_items_client_sku (client_id, sku),
  UNIQUE KEY uq_stock_items_client_barcode (client_id, barcode),
  KEY idx_stock_items_client (client_id),
  KEY idx_stock_items_category (category_id),
  KEY idx_stock_items_type (item_type),
  KEY idx_stock_items_active (is_active),
  KEY idx_stock_items_track_inventory (track_inventory),
  KEY idx_stock_items_sellable (is_sellable)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 3) BALANCES ACTUALES
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_balances (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  stock_item_id INT NOT NULL,
  on_hand_qty DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  reserved_qty DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  CONSTRAINT fk_stock_balances_item
    FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
    ON DELETE CASCADE,

  UNIQUE KEY uq_stock_balances_client_item (client_id, stock_item_id),
  KEY idx_stock_balances_client (client_id),
  KEY idx_stock_balances_item (stock_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 4) MOVIMIENTOS / KARDEX
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_movements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  stock_item_id INT NOT NULL,
  movement_type ENUM(
    'purchase_entry',
    'manual_entry',
    'sale_exit',
    'manual_exit',
    'adjustment_plus',
    'adjustment_minus',
    'sale_cancel_reversal'
  ) NOT NULL,
  quantity DECIMAL(12,3) NOT NULL,
  reference_type ENUM('purchase_order','pos_sale','manual') NOT NULL,
  reference_id INT NULL,
  source_app VARCHAR(100) NULL,
  source_app_id INT NULL,
  created_by VARCHAR(100) NULL,
  notes VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_stock_movements_item
    FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
    ON DELETE RESTRICT,

  KEY idx_stock_movements_client (client_id),
  KEY idx_stock_movements_item (stock_item_id),
  KEY idx_stock_movements_type (movement_type),
  KEY idx_stock_movements_reference (reference_type, reference_id),
  KEY idx_stock_movements_source (source_app, source_app_id),
  KEY idx_stock_movements_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 5) ÓRDENES DE COMPRA (v1 ligera)
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_purchase_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  supplier_name VARCHAR(200) NOT NULL,
  status ENUM('draft','received_partial','received_full','cancelled') NOT NULL DEFAULT 'draft',
  notes TEXT NULL,
  created_by VARCHAR(100) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP,

  KEY idx_stock_po_client (client_id),
  KEY idx_stock_po_status (status),
  KEY idx_stock_po_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS stock_purchase_order_items (
  id INT AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id INT NOT NULL,
  stock_item_id INT NOT NULL,
  ordered_qty DECIMAL(12,3) NOT NULL,
  received_qty DECIMAL(12,3) NOT NULL DEFAULT 0.000,
  unit_cost DECIMAL(12,4) NOT NULL DEFAULT 0.0000,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT fk_stock_poi_po
    FOREIGN KEY (purchase_order_id) REFERENCES stock_purchase_orders(id)
    ON DELETE CASCADE,

  CONSTRAINT fk_stock_poi_item
    FOREIGN KEY (stock_item_id) REFERENCES stock_items(id)
    ON DELETE RESTRICT,

  KEY idx_stock_poi_po (purchase_order_id),
  KEY idx_stock_poi_item (stock_item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================================
-- 6) SINCRONIZACIÓN DE VENTAS EXTERNAS (idempotencia)
-- =====================================================================
CREATE TABLE IF NOT EXISTS stock_external_sale_sync (
  id INT AUTO_INCREMENT PRIMARY KEY,
  client_id INT NOT NULL,
  source_app VARCHAR(100) NOT NULL,
  source_app_id INT NULL,
  external_sale_id INT NOT NULL,
  sync_status ENUM('applied','cancelled') NOT NULL DEFAULT 'applied',
  processed_at DATETIME NULL,
  cancelled_at DATETIME NULL,
  cancelled_by VARCHAR(100) NULL,
  cancellation_reason VARCHAR(255) NULL,
  response_snapshot JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

  UNIQUE KEY uq_stock_ext_sale_sync (client_id, source_app, external_sale_id),
  KEY idx_stock_ext_sale_sync_status (sync_status),
  KEY idx_stock_ext_sale_sync_processed (processed_at),
  KEY idx_stock_ext_sale_sync_cancelled (cancelled_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;