
/*
    This file contains the SQL statements to create the Gold views
    in the data warehouse.

    Note:
    If the script is run multiple times, it will drop the existing
    views and create new ones.
*/


/* ============================================================
   CREATE DIM_PRODUCTS VIEW
   ============================================================ */

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    p.product_id,
    COALESCE(p.product_name, 'Unknown') AS product_name,
    COALESCE(b.brand_name, 'Unknown') AS brand_name,
    COALESCE(c.category_name, 'Unknown') AS category_name,
    p.model_year,
    p.list_price
FROM silver.products p
LEFT JOIN silver.brands b ON p.brand_id = b.brand_id
LEFT JOIN silver.categories c ON p.category_id = c.category_id;
GO


/* ============================================================
   CREATE DIM_CUSTOMERS VIEW
   ============================================================ */

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.phone,
    c.email,
    c.street,
    c.city,
    c.state,
    c.zip_code
FROM silver.customers c;
GO


/* ============================================================
   CREATE DIM_STORES VIEW
   ============================================================ */

IF OBJECT_ID('gold.dim_stores', 'V') IS NOT NULL
    DROP VIEW gold.dim_stores;
GO

CREATE VIEW gold.dim_stores AS
SELECT
    s.store_id,
    s.store_name,
    s.phone,
    s.email,
    s.street,
    s.city,
    s.state,
    CASE
        WHEN s.zip_code = '0' THEN 'n/a'
        ELSE s.zip_code    
    END AS zip_code
FROM silver.stores s;
GO


/* ============================================================
   CREATE DIM_STAFFS VIEW
   ============================================================ */

IF OBJECT_ID('gold.dim_staffs', 'V') IS NOT NULL
    DROP VIEW gold.dim_staffs;
GO

CREATE VIEW gold.dim_staffs AS
SELECT
    s.staff_id,
    s.first_name,
    s.last_name,
    s.email,
    s.phone,
    s.active,
    CASE
        WHEN str.store_name IS NULL THEN 'Unknown'
        ELSE str.store_name
    END AS store_name,
    CASE
        WHEN TRIM(CONCAT(sup.first_name, ' ', sup.last_name)) IS NULL THEN 'Unknown'
        ELSE TRIM(CONCAT(sup.first_name, ' ', sup.last_name))

    END AS manager_name
FROM silver.staffs s
LEFT JOIN gold.dim_stores str ON s.store_id = str.store_id
LEFT JOIN silver.staffs sup ON s.manager_id = sup.staff_id;
GO


/* ============================================================
   CREATE DIM_DATE VIEW
   ============================================================ */

IF OBJECT_ID('gold.dim_date', 'V') IS NOT NULL
    DROP VIEW gold.dim_date;
GO

CREATE VIEW gold.dim_date AS

WITH CTE_dates AS
(
    SELECT order_date AS full_date
    FROM silver.orders
    WHERE order_date IS NOT NULL

    UNION

    SELECT required_date AS full_date
    FROM silver.orders
    WHERE required_date IS NOT NULL

    UNION

    SELECT shipped_date AS full_date
    FROM silver.orders
    WHERE shipped_date IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY full_date) AS date_key,
    full_date,
    DAY(full_date) AS day,
    MONTH(full_date) AS month,
    DATENAME(MONTH, full_date) AS month_name,
    DATEPART(QUARTER, full_date) AS quarter,
    YEAR(full_date) AS year
FROM CTE_dates;
GO


/* ============================================================
   CREATE FACT_INVENTORY VIEW
   ============================================================ */

IF OBJECT_ID('gold.fact_inventory', 'V') IS NOT NULL
    DROP VIEW gold.fact_inventory;
GO

CREATE VIEW gold.fact_inventory AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY stk.store_id, stk.product_id
    ) AS inventory_key,

    str.store_id,
    p.product_id,

    stk.quantity

FROM silver.stocks stk

LEFT JOIN gold.dim_products p ON stk.product_id = p.product_id

LEFT JOIN gold.dim_stores str ON stk.store_id = str.store_id;
GO


/* ============================================================
   CREATE FACT_SALES VIEW
   ============================================================ */

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY o.order_id, i.product_id
    ) AS sales_key,
    CASE
        WHEN o.order_id IS NULL THEN -1
        ELSE o.order_id
    END AS order_id,
    CASE
        WHEN i.order_item_sk IS NULL THEN -1
        ELSE i.order_item_sk
    END AS order_item_sk,
    CASE
        WHEN inv.inventory_key IS NULL THEN -1
        ELSE inv.inventory_key
    END AS inventory_key,
    CASE
        WHEN c.customer_id IS NULL THEN -1
        ELSE c.customer_id
    END AS customer_id,
    CASE
        WHEN p.product_id IS NULL THEN -1
        ELSE p.product_id
    END AS product_id,
    CASE
        WHEN s.store_id IS NULL THEN -1
        ELSE s.store_id
    END AS store_id,
    CASE
        WHEN sf.staff_id IS NULL THEN -1
        ELSE sf.staff_id
    END AS staff_id,

    d_order.date_key AS order_date_key,
    d_required.date_key AS required_date_key,
    d_shipped.date_key AS shipped_date_key,

    o.order_status,

    i.quantity,
    i.list_price,
    i.discount,

    CAST(
        i.quantity * i.list_price * (1 - i.discount)
        AS DECIMAL(10, 2)
    ) AS sales_amount

FROM silver.orders o

LEFT JOIN silver.order_items i ON o.order_id = i.order_id

LEFT JOIN gold.dim_customers c ON o.customer_id = c.customer_id

LEFT JOIN gold.dim_products p ON i.product_id = p.product_id

LEFT JOIN gold.dim_stores s ON o.store_id = s.store_id

LEFT JOIN gold.dim_staffs sf ON o.staff_id = sf.staff_id

LEFT JOIN gold.dim_date d_order ON o.order_date = d_order.full_date

LEFT JOIN gold.dim_date d_required ON o.required_date = d_required.full_date

LEFT JOIN gold.dim_date d_shipped ON o.shipped_date = d_shipped.full_date

LEFT JOIN gold.fact_inventory inv ON o.store_id = inv.store_id 

GO

