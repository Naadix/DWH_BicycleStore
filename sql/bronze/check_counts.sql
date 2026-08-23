-- check counts of all tables in the bronze schema
SELECT 'brands' AS table_name, COUNT(*) AS row_count FROM bronze.brands
UNION ALL
SELECT 'categories' AS table_name, COUNT(*) AS row_count FROM bronze.categories
UNION ALL
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM bronze.customers
UNION ALL
SELECT 'order_items' AS table_name, COUNT(*) AS row_count FROM bronze.order_items
UNION ALL
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM bronze.orders
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM bronze.products
UNION ALL
SELECT 'staffs' AS table_name, COUNT(*) AS row_count FROM bronze.staffs
UNION ALL
SELECT 'stocks' AS table_name, COUNT(*) AS row_count FROM bronze.stocks
UNION ALL
SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM bronze.stores