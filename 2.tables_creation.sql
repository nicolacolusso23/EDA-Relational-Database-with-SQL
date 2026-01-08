-- ==========================================================================================
-- DIMENSION TABLES
-- ==========================================================================================

-- Stores Table

-- Stores information for each restaurant location including contact details, region, opening date, and manager.

-- This dimension is useful for store-level reporting, sales aggregation, and regional analysis.

CREATE TABLE IF NOT EXISTS stores_table (
    store_id INTEGER PRIMARY KEY,
    store_name TEXT NOT NULL UNIQUE,
    address TEXT,
    region TEXT,
    phone_number TEXT,
    opening_date DATE,
    manager_name TEXT
);


-- Items Table

-- Menu items information including name, category, price, and vegetarian flag.

-- Useful for sales analysis, menu engineering, and dietary segmentation.

CREATE TABLE IF NOT EXISTS items_table (
    item_id INTEGER PRIMARY KEY,
    item_name TEXT NOT NULL UNIQUE,
    category TEXT,
    price NUMERIC(10,2) NOT NULL,
    is_vegetarian BOOLEAN DEFAULT FALSE
);


-- Discounts Table

-- Information about discounts and promotions, with percentage, validity period, and unique identifier.

-- Supports analysis of promotional impact, discount usage, and customer segmentation.

CREATE TABLE IF NOT EXISTS discounts_table (
    discount_id INTEGER PRIMARY KEY,
    discount_name TEXT NOT NULL UNIQUE,
    discount_percentage NUMERIC(5,2) NOT NULL,
    valid_from DATE,
    valid_until DATE
);


-- Customers Table

-- Stores customer information including name, email, date of birth, and loyalty membership status.

-- This dimension enables loyalty program analysis, top-customer identification, and marketing segmentation.

CREATE TABLE IF NOT EXISTS customers_table (
    customer_id INTEGER PRIMARY KEY,
    customer_name TEXT NOT NULL,
    date_of_birth DATE,
    email TEXT UNIQUE,
    loyalty_member BOOLEAN DEFAULT FALSE
);
