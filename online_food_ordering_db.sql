-- ============================================================================
-- ONLINE FOOD ORDERING SYSTEM - DATABASE SCHEMA & INITIAL DATA
-- National Vocational Training Institute (NVTI Baddegama)
-- Software Developer NVQ Level 4 — M5: Developing Web Applications
-- Supervised by: E.A.R. Lakshman
-- Developed by: Group 5
-- Target DBMS: MySQL Server (Compatible with XAMPP / phpMyAdmin)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS `online_food_ordering_db` 
DEFAULT CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `online_food_ordering_db`;

-- Drop tables if they already exist (in reverse order of foreign key dependencies)
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `expenses`;
DROP TABLE IF EXISTS `delivery`;
DROP TABLE IF EXISTS `payments`;
DROP TABLE IF EXISTS `order_status_history`;
DROP TABLE IF EXISTS `order_item_modifications`;
DROP TABLE IF EXISTS `order_details`;
DROP TABLE IF EXISTS `orders`;
DROP TABLE IF EXISTS `food_ingredients`;
DROP TABLE IF EXISTS `ingredients`;
DROP TABLE IF EXISTS `food_items`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `customers`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================================
-- 1. USERS TABLE
-- Handles authentication & role-based access (Admin, Customer, Cashier, Kitchen, Delivery)
-- ============================================================================
CREATE TABLE `users` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL, -- Stores hashed passwords (e.g., bcrypt)
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `role` ENUM('Admin', 'Customer', 'Cashier', 'Kitchen', 'Delivery') NOT NULL DEFAULT 'Customer',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 2. CUSTOMERS TABLE
-- Stores detailed profile information for registered customer accounts
-- ============================================================================
CREATE TABLE `customers` (
  `customer_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `phone` VARCHAR(20) NOT NULL,
  `address` TEXT NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_customers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 3. CATEGORIES TABLE
-- Stores food categories (e.g., Rice & Curry, Burgers, Beverages, Desserts)
-- ============================================================================
CREATE TABLE `categories` (
  `category_id` INT AUTO_INCREMENT PRIMARY KEY,
  `category_name` VARCHAR(100) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `status` ENUM('Active', 'Inactive') NOT NULL DEFAULT 'Active',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 4. FOOD_ITEMS TABLE (FOOD)
-- Main catalog for food menu items with price and image path
-- ============================================================================
CREATE TABLE `food_items` (
  `food_id` INT AUTO_INCREMENT PRIMARY KEY,
  `category_id` INT NOT NULL,
  `food_name` VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `image` VARCHAR(255) DEFAULT 'default_food.png',
  `status` ENUM('Available', 'Unavailable') NOT NULL DEFAULT 'Available',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_food_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`category_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 5. INGREDIENTS TABLE
-- Customizable options and extra add-ons/ingredients for food items
-- ============================================================================
CREATE TABLE `ingredients` (
  `ingredient_id` INT AUTO_INCREMENT PRIMARY KEY,
  `ingredient_name` VARCHAR(100) NOT NULL,
  `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `status` ENUM('Available', 'Unavailable') NOT NULL DEFAULT 'Available'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 6. FOOD_INGREDIENTS TABLE
-- Junction table associating food items with their standard default ingredients
-- ============================================================================
CREATE TABLE `food_ingredients` (
  `food_ingredient_id` INT AUTO_INCREMENT PRIMARY KEY,
  `food_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  `is_default` TINYINT(1) NOT NULL DEFAULT 1, -- 1 = standard component, 0 = optional add-on
  CONSTRAINT `fk_food_ing_food` FOREIGN KEY (`food_id`) REFERENCES `food_items` (`food_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_food_ing_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 7. ORDERS TABLE
-- Tracks online and direct cashier orders with order source and status
-- ============================================================================
CREATE TABLE `orders` (
  `order_id` INT AUTO_INCREMENT PRIMARY KEY,
  `customer_id` INT NULL, -- NULL for direct cashier orders without registered account
  `cashier_id` INT NULL,  -- NULL for online customer orders, populated if created/processed by cashier
  `order_type` ENUM('Online', 'Direct') NOT NULL DEFAULT 'Online',
  `order_date` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` ENUM('Pending', 'Preparing', 'Ready', 'Delivered', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Pending',
  `total_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_orders_cashier` FOREIGN KEY (`cashier_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 8. ORDER_DETAILS TABLE
-- Specific food items, quantities, unit prices, and sub-totals for each order
-- ============================================================================
CREATE TABLE `order_details` (
  `order_detail_id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `food_id` INT NOT NULL,
  `quantity` INT NOT NULL DEFAULT 1,
  `unit_price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `sub_total` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  CONSTRAINT `fk_ord_details_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ord_details_food` FOREIGN KEY (`food_id`) REFERENCES `food_items` (`food_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 9. ORDER_ITEM_MODIFICATIONS TABLE
-- Captures ingredient customizations (Add / Remove) & price adjustments per order item
-- ============================================================================
CREATE TABLE `order_item_modifications` (
  `modification_id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_detail_id` INT NOT NULL,
  `ingredient_id` INT NOT NULL,
  `modification_type` ENUM('Add', 'Remove', 'Extra') NOT NULL,
  `price_adjustment` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  CONSTRAINT `fk_mod_order_detail` FOREIGN KEY (`order_detail_id`) REFERENCES `order_details` (`order_detail_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_mod_ingredient` FOREIGN KEY (`ingredient_id`) REFERENCES `ingredients` (`ingredient_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 10. ORDER_STATUS_HISTORY TABLE
-- Audit log of order status updates along with who modified the status
-- ============================================================================
CREATE TABLE `order_status_history` (
  `status_history_id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `changed_by` INT NULL, -- References users.user_id
  `status` ENUM('Pending', 'Preparing', 'Ready', 'Delivered', 'Completed', 'Cancelled') NOT NULL,
  `changed_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_history_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_history_user` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 11. PAYMENTS TABLE
-- Records order payments, payment methods, received status, and cashier link
-- ============================================================================
CREATE TABLE `payments` (
  `payment_id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `received_by` INT NULL, -- Cashier or system user who processed payment
  `payment_method` ENUM('Cash', 'Card', 'Online', 'QR') NOT NULL DEFAULT 'Cash',
  `amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `payment_status` ENUM('Pending', 'Paid', 'Failed', 'Refunded') NOT NULL DEFAULT 'Paid',
  `paid_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_payments_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_payments_user` FOREIGN KEY (`received_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 12. DELIVERY TABLE
-- Tracks delivery details, assigned delivery staff, and delivery progression
-- ============================================================================
CREATE TABLE `delivery` (
  `delivery_id` INT AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT NOT NULL,
  `delivery_staff_id` INT NULL, -- References user with role 'Delivery'
  `delivery_address` TEXT NOT NULL,
  `delivery_status` ENUM('Assigned', 'Out for Delivery', 'Delivered', 'Failed') NOT NULL DEFAULT 'Assigned',
  `assigned_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `delivered_at` DATETIME NULL,
  CONSTRAINT `fk_delivery_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_delivery_staff` FOREIGN KEY (`delivery_staff_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- 13. EXPENSES TABLE
-- Administrative expense tracking for operational financial reporting
-- ============================================================================
CREATE TABLE `expenses` (
  `expense_id` INT AUTO_INCREMENT PRIMARY KEY,
  `recorded_by` INT NULL, -- Admin or Cashier user who recorded the expense
  `description` TEXT NOT NULL,
  `amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
  `expense_date` DATE NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_expenses_user` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================================
-- SAMPLE DATA INSERTION (For Testing & Prototype Verification)
-- Passwords below are hashed representations of default passwords (e.g. 'password123')
-- ============================================================================

-- 1. Insert Users
INSERT INTO `users` (`user_id`, `username`, `password`, `email`, `role`) VALUES
(1, 'admin', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'admin@restaurant.com', 'Admin'),
(2, 'cashier1', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'cashier@restaurant.com', 'Cashier'),
(3, 'kitchen1', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'kitchen@restaurant.com', 'Kitchen'),
(4, 'delivery1', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'delivery@restaurant.com', 'Delivery'),
(5, 'janithya', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'janithya@gmail.com', 'Customer'),
(6, 'deshapriya', '$2y$10$e0MYzXyjpJS7Pd0RVvHwHe11.758C/n15t/Z1uL/N7.t.Kx.1J1.', 'deshapriya@gmail.com', 'Customer');

-- 2. Insert Customers
INSERT INTO `customers` (`customer_id`, `user_id`, `name`, `phone`, `address`) VALUES
(1, 5, 'T.V.C. Janithya', '0771234567', 'No 45, Main Street, Baddegama, Galle'),
(2, 6, 'M.D.S.U. Deshapriya', '0719876543', 'No 88, Galle Road, Hikkaduwa');

-- 3. Insert Categories
INSERT INTO `categories` (`category_id`, `category_name`, `description`, `status`) VALUES
(1, 'Main Dishes', 'Delicious and authentic Sri Lankan and international main courses', 'Active'),
(2, 'Burgers & Sandwiches', 'Gourmet burgers and freshly made sandwiches', 'Active'),
(3, 'Beverages', 'Refreshing cold and hot drinks, juices, and shakes', 'Active'),
(4, 'Desserts', 'Sweet treats and traditional desserts', 'Active');

-- 4. Insert Food Items
INSERT INTO `food_items` (`food_id`, `category_id`, `food_name`, `description`, `price`, `image`, `status`) VALUES
(1, 1, 'Chicken Fried Rice', 'Flavorful basmati rice wok-fried with chicken, eggs, and fresh veggies', 1200.00, 'fried_rice.jpg', 'Available'),
(2, 1, 'Kottu Roti (Chicken)', 'Chopped flatbread wok-fried with spices, chicken, and egg', 1000.00, 'kottu_chicken.jpg', 'Available'),
(3, 2, 'Crispy Chicken Burger', 'Crispy chicken patty with lettuce, cheese, and special sauce', 850.00, 'chicken_burger.jpg', 'Available'),
(4, 3, 'Fresh Mango Juice', 'Pure 100% natural mango pulp juice with ice', 350.00, 'mango_juice.jpg', 'Available'),
(5, 4, 'Chocolate Sundae', 'Rich chocolate ice cream with fudge sauce and sprinkles', 450.00, 'choco_sundae.jpg', 'Available');

-- 5. Insert Ingredients
INSERT INTO `ingredients` (`ingredient_id`, `ingredient_name`, `price`, `status`) VALUES
(1, 'Extra Cheese', 150.00, 'Available'),
(2, 'Fried Egg', 80.00, 'Available'),
(3, 'Onions', 0.00, 'Available'),
(4, 'Chilli Flakes', 0.00, 'Available'),
(5, 'Extra Chicken Portion', 300.00, 'Available');

-- 6. Insert Food Ingredients (Default associations)
INSERT INTO `food_ingredients` (`food_ingredient_id`, `food_id`, `ingredient_id`, `is_default`) VALUES
(1, 1, 2, 1), -- Chicken Fried Rice default egg
(2, 1, 3, 1), -- Chicken Fried Rice default onions
(3, 2, 3, 1), -- Kottu default onions
(4, 3, 1, 1), -- Burger default cheese
(5, 3, 3, 1); -- Burger default onions

-- 7. Insert Orders
INSERT INTO `orders` (`order_id`, `customer_id`, `cashier_id`, `order_type`, `order_date`, `status`, `total_amount`) VALUES
(1, 1, NULL, 'Online', '2026-08-03 12:30:00', 'Delivered', 1430.00),
(2, 2, NULL, 'Online', '2026-08-03 13:15:00', 'Preparing', 1000.00),
(3, NULL, 2, 'Direct', '2026-08-03 14:00:00', 'Completed', 850.00);

-- 8. Insert Order Details
INSERT INTO `order_details` (`order_detail_id`, `order_id`, `food_id`, `quantity`, `unit_price`, `sub_total`) VALUES
(1, 1, 1, 1, 1200.00, 1200.00), -- 1 Chicken Fried Rice
(2, 1, 4, 1, 350.00, 350.00),   -- 1 Mango Juice
(3, 2, 2, 1, 1000.00, 1000.00), -- 1 Kottu
(4, 3, 3, 1, 850.00, 850.00);   -- 1 Burger

-- 9. Insert Order Item Modifications
INSERT INTO `order_item_modifications` (`modification_id`, `order_detail_id`, `ingredient_id`, `modification_type`, `price_adjustment`) VALUES
(1, 1, 2, 'Extra', 80.00),   -- Extra fried egg on Fried Rice (+80)
(2, 1, 3, 'Remove', 0.00);   -- Remove onions on Fried Rice

-- 10. Insert Order Status History
INSERT INTO `order_status_history` (`status_history_id`, `order_id`, `changed_by`, `status`, `changed_at`) VALUES
(1, 1, 5, 'Pending', '2026-08-03 12:30:00'),
(2, 1, 3, 'Preparing', '2026-08-03 12:35:00'),
(3, 1, 3, 'Ready', '2026-08-03 12:50:00'),
(4, 1, 4, 'Delivered', '2026-08-03 13:15:00'),
(5, 2, 6, 'Pending', '2026-08-03 13:15:00'),
(6, 2, 3, 'Preparing', '2026-08-03 13:20:00'),
(7, 3, 2, 'Completed', '2026-08-03 14:05:00');

-- 11. Insert Payments
INSERT INTO `payments` (`payment_id`, `order_id`, `received_by`, `payment_method`, `amount`, `payment_status`, `paid_at`) VALUES
(1, 1, NULL, 'Online', 1430.00, 'Paid', '2026-08-03 12:31:00'),
(2, 2, NULL, 'Cash', 1000.00, 'Pending', '2026-08-03 13:15:00'),
(3, 3, 2, 'Cash', 850.00, 'Paid', '2026-08-03 14:00:00');

-- 12. Insert Delivery Record
INSERT INTO `delivery` (`delivery_id`, `order_id`, `delivery_staff_id`, `delivery_address`, `delivery_status`, `assigned_at`, `delivered_at`) VALUES
(1, 1, 4, 'No 45, Main Street, Baddegama, Galle', 'Delivered', '2026-08-03 12:52:00', '2026-08-03 13:15:00'),
(2, 2, 4, 'No 88, Galle Road, Hikkaduwa', 'Assigned', '2026-08-03 13:22:00', NULL);

-- 13. Insert Expenses
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `description`, `amount`, `expense_date`) VALUES
(1, 1, 'Purchase of fresh vegetables and chicken stock', 15000.00, '2026-08-01'),
(2, 1, 'LPG Gas cylinder refills (2 units)', 9500.00, '2026-08-02'),
(3, 2, 'Kitchen packaging boxes & takeaway bags', 4200.00, '2026-08-03');

-- ============================================================================
-- USEFUL VIEWS FOR REPORTS & DASHBOARDS
-- ============================================================================

-- View: Daily Sales Summary Report
CREATE OR REPLACE VIEW `v_daily_sales_summary` AS
SELECT 
    DATE(o.order_date) AS `sales_date`,
    o.order_type,
    COUNT(o.order_id) AS `total_orders`,
    SUM(o.total_amount) AS `total_revenue`
FROM `orders` o
WHERE o.status IN ('Delivered', 'Completed')
GROUP BY DATE(o.order_date), o.order_type;

-- View: Order Details & Customization Breakdown
CREATE OR REPLACE VIEW `v_order_details_breakdown` AS
SELECT 
    o.order_id,
    o.order_type,
    o.status AS `order_status`,
    c.name AS `customer_name`,
    fi.food_name,
    od.quantity,
    od.unit_price,
    od.sub_total,
    GROUP_CONCAT(CONCAT(oim.modification_type, ': ', ing.ingredient_name, ' (Rs.', oim.price_adjustment, ')') SEPARATOR '; ') AS `customizations`
FROM `orders` o
LEFT JOIN `customers` c ON o.customer_id = c.customer_id
JOIN `order_details` od ON o.order_id = od.order_id
JOIN `food_items` fi ON od.food_id = fi.food_id
LEFT JOIN `order_item_modifications` oim ON od.order_detail_id = oim.order_detail_id
LEFT JOIN `ingredients` ing ON oim.ingredient_id = ing.ingredient_id
GROUP BY od.order_detail_id;

-- End of Database Script
