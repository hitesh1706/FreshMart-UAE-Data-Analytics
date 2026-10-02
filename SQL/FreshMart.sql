create database FreshMart_UAE;
use FreshMart_UAE;
CREATE TABLE customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    age INT NOT NULL,
    city VARCHAR(50) NOT NULL,
    emirate VARCHAR(50) NOT NULL,
    segment VARCHAR(30) NOT NULL,
    loyalty_status VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(30),
    join_date DATE NOT NULL
);
CREATE TABLE employees (
    employee_id VARCHAR(10) PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female') NOT NULL,
    age INT NOT NULL,
    job_role VARCHAR(50) NOT NULL,
    store_id VARCHAR(10) NOT NULL,
    store_name VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    status ENUM('Active', 'Inactive') NOT NULL
);

CREATE TABLE stores (
    store_id VARCHAR(10) PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    store_type VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    emirate VARCHAR(50) NOT NULL,
    store_size_sqft INT NOT NULL,
    daily_customer_capacity INT NOT NULL,
    opening_date DATE NOT NULL,
    store_manager VARCHAR(100) NOT NULL,
    manager_id VARCHAR(10),
    status ENUM('Active', 'Inactive') NOT NULL
);

CREATE TABLE products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    size VARCHAR(30),
    unit_cost DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    profit_margin DECIMAL(5,2) NOT NULL,
    barcode VARCHAR(30) UNIQUE NOT NULL,
    expiry_required ENUM('Yes','No') NOT NULL,
    launch_date DATE NOT NULL,
    status ENUM('Active','Discontinued') NOT NULL,
    supplier_id VARCHAR(10) NOT NULL
);

CREATE TABLE suppliers (
    supplier_id VARCHAR(10) PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_type VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    city VARCHAR(50) NOT NULL,
    emirate VARCHAR(50) NOT NULL,
    contact_person VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(30),
    contract_start_date DATE NOT NULL,
    payment_terms VARCHAR(50) NOT NULL,
    status ENUM('Active', 'Inactive') NOT NULL
);

CREATE TABLE promotions (
    promotion_id VARCHAR(12) PRIMARY KEY,
    promotion_name VARCHAR(100) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('Active','Expired','Upcoming') NOT NULL
);

CREATE TABLE order_items (
    order_item_id VARCHAR(12) PRIMARY KEY,
    order_id VARCHAR(12) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) NOT NULL,
    discount_amount DECIMAL(10,2) NOT NULL,
    final_unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(12,2) NOT NULL
);

CREATE TABLE reviews (
    review_id VARCHAR(12) PRIMARY KEY,
    order_id VARCHAR(12) NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_comment TEXT,
    review_date DATE NOT NULL
);

select count(*) from customers;

CREATE TABLE orders (
    order_id VARCHAR(12) PRIMARY KEY,
    customer_id VARCHAR(10) NOT NULL,
    store_id VARCHAR(10) NOT NULL,

    order_date VARCHAR(10) NOT NULL,
    delivery_date VARCHAR(10),

    order_status ENUM(
        'Delivered',
        'Cancelled',
        'Processing',
        'Returned',
        'Shipped'
    ) NOT NULL,

    delivery_type ENUM(
        'Standard',
        'Express',
        'Pickup'
    ) NOT NULL,

    payment_method ENUM(
        'Card',
        'Apple Pay',
        'Cash on Delivery',
        'Google Pay',
        'Wallet'
    ) NOT NULL,

    shipping_fee DECIMAL(10,2) NOT NULL,
    total_items INT NOT NULL,
    total_discount DECIMAL(10,2) NOT NULL,
    order_total DECIMAL(12,2) NOT NULL
);

  CREATE TABLE inventory (
    inventory_id VARCHAR(12) PRIMARY KEY,
    store_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,
    current_stock INT NOT NULL,
    reorder_level INT NOT NULL,
    reorder_status ENUM('Yes','No') NOT NULL,
    last_stock_update DATE NOT NULL
);

CREATE TABLE payments (
    payment_id VARCHAR(12) PRIMARY KEY,
    order_id VARCHAR(12) NOT NULL,
    payment_method ENUM(
        'Card',
        'Apple Pay',
        'Google Pay',
        'Cash on Delivery',
        'Wallet'
    ) NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL,
    payment_status ENUM(
        'Paid',
        'Pending',
        'Refunded'
    ) NOT NULL,
    payment_date DATE NOT NULL
);

 CREATE TABLE returns (
    return_id VARCHAR(12) PRIMARY KEY,
    order_id VARCHAR(12) NOT NULL,
    customer_id VARCHAR(10) NOT NULL,
    return_date DATE NOT NULL,
    return_reason VARCHAR(100) NOT NULL,
    return_status ENUM(
        'Approved',
        'Rejected',
        'Refund Completed'
    ) NOT NULL
);
select count(*) from suppliers;

SELECT email, COUNT(*) AS cnt
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'inventory', COUNT(*) FROM inventory
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'promotions', COUNT(*) FROM promotions
UNION ALL
SELECT 'returns', COUNT(*) FROM returns
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'stores', COUNT(*) FROM stores
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers;

SELECT customer_id,COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*)>1;
SELECT order_id,COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*)>1;

SELECT product_id,COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*)>1;
SELECT COUNT(*) AS missing_customers
FROM orders o
LEFT JOIN customers c
ON o.customer_id=c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_store
FROM orders o
LEFT JOIN stores s
ON o.store_id=s.store_id
WHERE s.store_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM order_items oi
LEFT JOIN orders o
ON oi.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM order_items oi
LEFT JOIN products p
ON oi.product_id=p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM payments p
LEFT JOIN orders o
ON p.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM payments p
LEFT JOIN orders o
ON p.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM reviews r
LEFT JOIN orders o
ON r.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS missing_customers
FROM reviews r
LEFT JOIN customers c
ON r.customer_id=c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_orders
FROM returns r
LEFT JOIN orders o
ON r.order_id=o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS missing_customers
FROM returns r
LEFT JOIN customers c
ON r.customer_id=c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM inventory i
LEFT JOIN products p
ON i.product_id=p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS missing_store
FROM inventory i
LEFT JOIN stores s
ON i.store_id=s.store_id
WHERE s.store_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM promotions p
LEFT JOIN products pr
ON p.product_id=pr.product_id
WHERE pr.product_id IS NULL;

SELECT COUNT(*) AS missing_supplier
FROM products p
LEFT JOIN suppliers s
ON p.supplier_id=s.supplier_id
WHERE s.supplier_id IS NULL;

SELECT COUNT(*) AS missing_store
FROM employees e
LEFT JOIN stores s
ON e.store_id=s.store_id
WHERE s.store_id IS NULL;

SELECT DISTINCT store_id
FROM orders
WHERE store_id NOT IN (
    SELECT store_id
    FROM stores
);

SELECT DISTINCT store_id
FROM inventory
WHERE store_id NOT IN (
    SELECT store_id
    FROM stores
);

SELECT DISTINCT store_id
FROM employees
WHERE store_id NOT IN (
    SELECT store_id
    FROM stores
);
SELECT
    CONCAT('[', store_id, ']') AS store_id,
    LENGTH(store_id) AS len,
    HEX(store_id) AS hex_value
FROM stores
WHERE store_id IN ('ST002','ST027');
SELECT
    CONCAT('[', store_id, ']') AS store_id,
    LENGTH(store_id) AS len,
    HEX(store_id) AS hex_value
FROM orders
WHERE store_id IN ('ST002','ST027')
LIMIT 5;
SELECT DISTINCT o.store_id
FROM orders o
LEFT JOIN stores s
ON o.store_id = s.store_id
WHERE s.store_id IS NULL;
SELECT DISTINCT i.store_id
FROM inventory i
LEFT JOIN stores s
ON i.store_id = s.store_id
WHERE s.store_id IS NULL;
SELECT DISTINCT e.store_id
FROM employees e
LEFT JOIN stores s
ON e.store_id = s.store_id
WHERE s.store_id IS NULL;

SELECT *
FROM stores
WHERE store_id = 'ST027';
SELECT *
FROM orders
WHERE store_id = 'ST027'
LIMIT 5;
SELECT o.store_id, s.store_id
FROM orders o
LEFT JOIN stores s
ON o.store_id = s.store_id
WHERE o.store_id = 'ST027'
LIMIT 10;

SHOW CREATE TABLE orders;

SELECT *
FROM stores
WHERE store_id='ST027';

SELECT *
FROM stores
WHERE store_id='ST002';

SELECT store_id
FROM stores
ORDER BY store_id;

INSERT INTO stores
(store_id, store_name, store_type, city, emirate,
 store_size_sqft, daily_customer_capacity,
 opening_date, store_manager, manager_id, status)
VALUES
('ST002','FreshMart ST002','Supermarket','Dubai','Dubai',
 4500,500,'2022-01-01','TBD',NULL,'Active'),

('ST027','FreshMart ST027','Supermarket','Dubai','Dubai',
 4500,500,'2022-01-01','TBD',NULL,'Active');
 
SELECT COUNT(*) AS missing_store
FROM employees e
LEFT JOIN stores s
ON e.store_id=s.store_id
WHERE s.store_id IS NULL;

use freshmart_uae;

SELECT DISTINCT o.customer_id
FROM orders o
LEFT JOIN customers c
ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- Orders without Stores
-- Inventory without Stores
-- Employees without Stores
SELECT COUNT(*)
FROM employees e
LEFT JOIN stores s
ON e.store_id = s.store_id
WHERE s.store_id IS NULL;

USE freshmart_uae;

-- ===========================
-- PRODUCTS
-- ===========================

ALTER TABLE products
ADD CONSTRAINT fk_products_supplier
FOREIGN KEY (supplier_id)
REFERENCES suppliers(supplier_id);

-- ===========================
-- EMPLOYEES
-- ===========================

ALTER TABLE employees
ADD CONSTRAINT fk_employees_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

-- ===========================
-- ORDERS
-- ===========================

ALTER TABLE orders
ADD CONSTRAINT fk_orders_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

ALTER TABLE orders
ADD CONSTRAINT fk_orders_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

-- ===========================
-- ORDER ITEMS
-- ===========================

ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE order_items
ADD CONSTRAINT fk_orderitems_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

-- ===========================
-- INVENTORY
-- ===========================

ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_store
FOREIGN KEY (store_id)
REFERENCES stores(store_id);

ALTER TABLE inventory
ADD CONSTRAINT fk_inventory_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);

-- ===========================
-- PAYMENTS
-- ===========================

ALTER TABLE payments
ADD CONSTRAINT fk_payments_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- ===========================
-- RETURNS
-- ===========================

ALTER TABLE returns
ADD CONSTRAINT fk_returns_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE returns
ADD CONSTRAINT fk_returns_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- ===========================
-- REVIEWS
-- ===========================

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_order
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

ALTER TABLE reviews
ADD CONSTRAINT fk_reviews_customer
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- ===========================
-- PROMOTIONS
-- ===========================

ALTER TABLE promotions
ADD CONSTRAINT fk_promotions_product
FOREIGN KEY (product_id)
REFERENCES products(product_id);


SELECT
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'freshmart_uae'
AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;

