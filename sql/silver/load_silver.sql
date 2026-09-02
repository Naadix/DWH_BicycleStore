/*
  CREATE STORED PROCEDURE FOR CLEANING DATA FROM BRONZE LAYER AND LOADING INTO SILVER LAYER
*/

CREATE OR ALTER PROCEDURE silver.load_silver
AS 
BEGIN
    -- variable for compute loading time
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    
    BEGIN TRY 

        SET @batch_start_time = GETDATE();
        PRINT'================================ LOADING SILVER LAYER ... =====================================';

        -- clean and load brands table 
        SET @start_time = GETDATE();
        DELETE FROM silver.brands;
        INSERT INTO silver.brands (
            brand_id,
            brand_name
        )
        SELECT 
            brand_id,
            TRIM(brand_name) AS brand_name -- if exist spaces in leading or trailing, remove it
        FROM bronze.brands;
        PRINT 'BRANDS TABLE LOADED THE DATA WTHOUT ANY TRANSFORMATION'
        SET @end_time = GETDATE();
        PRINT 'THE TIME LOADED OF BRANDS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';

        -- clean and load categories table 
        SET @start_time = GETDATE();
        DELETE FROM silver.categories;
        INSERT INTO silver.categories (
            category_id, 
            category_name
        )
        SELECT 
            category_id, 
            TRIM(category_name) AS category_name -- if exist spaces in leading or trailing, remove it
        FROM bronze.categories;
        PRINT 'CATEGORIES TABLE LOADED THE DATA WITHOUT ANY TRANSFORMATION'
        SET @end_time = GETDATE();
        PRINT 'THE TIME LOADED OF CATEGORIES TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';

        --  clean and load customers table 
        SET @start_time = GETDATE();
        DELETE FROM silver.customers;
        INSERT INTO silver.customers (
            customer_id,
            first_name,
            last_name,
            phone,
            email,
            street,
            city,
            state,
            zip_code
        )
        SELECT
            customer_id , 
            TRIM(first_name) AS first_name, -- if exist spaces in leading or trailing, remove it
            TRIM(last_name) AS last_name, -- if exist spaces in leading or trailing,
            CASE 
                WHEN TRIM(phone) IS NULL THEN 'n/a' -- handle null phone values
                ELSE TRIM(phone)
            END AS phone,
            CASE
                WHEN TRIM(email) IS NULL THEN 'n/a' -- handle null email values
                ELSE TRIM(email)
            END AS email,
            TRIM(street) AS street, -- if exist spaces in leading or trailing, remove it
            TRIM(city) AS city, -- if exist spaces in leading or trailing, remove it
            CASE
                WHEN UPPER(TRIM(state)) = 'CA' THEN 'California'
                WHEN UPPER(TRIM(state)) = 'NY' THEN 'New York'
                WHEN UPPER(TRIM(state)) = 'TX' THEN 'Texas'
                ELSE TRIM(state) -- if exist spaces in leading or trailing, remove it
            END AS state, -- normalize the states values to full name
            CASE
                WHEN zip_code IS NULL THEN 0 -- handle null zip_code values
                ELSE zip_code
            END AS zip_code
        FROM bronze.customers;
        PRINT 'CUSTOMERS TABLE LOADED THE DATA WITH TRANSFORMATION'
        SET @end_time = GETDATE();
        PRINT 'THE TIME LOADED OF CUSTOMERS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
        
        
    -- clean and load stores table
    SET @start_time = GETDATE();
    DELETE FROM silver.stores;
    INSERT INTO silver.stores(
        store_id,
        store_name, 
        phone, 
        email, 
        street, 
        city, 
        state,
        zip_code    
    )
    SELECT 
        store_id,
        TRIM(store_name) AS store_name, -- if exist spaces in leading or trailing, remove it
        CASE 
            WHEN TRIM(phone) IS NULL THEN 'n/a' -- handle null phone values
            ELSE TRIM(phone)
        END AS phone,
        CASE
            WHEN TRIM(email) IS NULL THEN 'n/a' -- handle null email values
            ELSE TRIM(email)
        END AS email,
        TRIM(street) AS street, -- if exist spaces in leading or trailing, remove it
        TRIM(city) AS city, -- if exist spaces in leading or trailing, remove it
        CASE
            WHEN UPPER(TRIM(state)) = 'CA' THEN 'California'
            WHEN UPPER(TRIM(state)) = 'NY' THEN 'New York'
            WHEN UPPER(TRIM(state)) = 'TX' THEN 'Texas'
            ELSE TRIM(state) 
        END AS state, -- normalize the states values to full name
        CASE 
            WHEN zip_code IS NULL THEN 0 -- handle null zip_code values
            ELSE zip_code
        END AS zip_code
    FROM bronze.stores
    SET @end_time = GETDATE();
    PRINT 'STORES TABLE LOADED THE DATA WITH TRANSFORMATION'
    PRINT 'THE TIME LOADED OF STORES TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
    

    -- clean and load staffs table
    SET @start_time = GETDATE();
    DELETE FROM silver.staffs;
    INSERT INTO silver.staffs(
        staff_id, 
        first_name, 
        last_name, 
        email, 
        phone, 
        active, 
        store_id, 
        manager_id
    )
    SELECT 
        staff_id,
        TRIM(first_name) AS first_name, -- if exist spaces in leading or trailing, remove it
        CASE 
            WHEN TRIM(last_name) IS NULL THEN 'Unknown' -- handle null last_name values
            ELSE TRIM(last_name) -- if exist spaces in leading or trailing, remove it
        END AS last_name,
        CASE 
            WHEN TRIM(email) IS NULL THEN 'n/a' -- handle null email values
            ELSE TRIM(email)
        END AS email,
        CASE 
            WHEN TRIM(phone) IS NULL THEN 'n/a' -- handle null phone values
            ELSE TRIM(phone)
        END AS phone,
        active,
        store_id,
        manager_id
    FROM bronze.staffs;    
    PRINT 'STAFFS TABLE LOADED THE DATA WTHOUT ANY TRANSFORMATION';
    SET @end_time = GETDATE();
    PRINT 'THE TIME LOADED OF STAFFS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
        
        -- clean and load orders table
        SET @start_time = GETDATE();
        DELETE FROM silver.orders;
        INSERT INTO silver.orders(  
            order_id, 
            customer_id, 
            order_status, 
            order_date, 
            required_date, 
            shipped_date, 
            store_id, 
            staff_id
        )
        SELECT
            order_id , 
            CASE
                WHEN customer_id IS NULL THEN 0 -- handle null customer_id values
                ELSE customer_id
            END AS customer_id,
            order_status,
            CASE
                WHEN order_date LIKE '10%' THEN STUFF(order_date, 1, 2, '20') -- replace the year to 20xx
                WHEN order_date IS NULL THEN '1900-01-01' -- handle null order
                ELSE order_date
            END AS order_date,
            CASE
                WHEN required_date LIKE '10%' THEN STUFF(required_date, 1, 2, '20') -- replace the year to 20xx
                WHEN required_date IS NULL THEN '1900-01-01' -- handle null required_date
                ELSE required_date
            END AS required_date,
            CASE
                WHEN shipped_date LIKE '10%' THEN STUFF(shipped_date, 1, 2, '20') -- replace the year to 20xx
                WHEN shipped_date IS NULL THEN '1900-01-01' -- handle null shipped_date
                ELSE shipped_date
            END AS shipped_date,
            store_id,
            staff_id
        FROM bronze.orders   
        PRINT 'ORDERS TABLE LOADED THE DATA WITH TRANSFORMATION';
        SET @end_time = GETDATE();
        PRINT 'THE TIME LOADED OF ORDERS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
    
    -- clean and load products table
    SET @start_time = GETDATE();
    DELETE FROM silver.products;
    INSERT INTO silver.products (
        product_id, 
        product_name, 
        brand_id, 
        category_id, 
        model_year, 
        list_price
    )
    SELECT 
        product_id,
        TRIM(
            SUBSTRING(
                product_name,
                1,
                LEN(product_name) -CHARINDEX(' - ',REVERSE(product_name)) -2
            )
        ),
        brand_id,
        category_id,
        CASE
            WHEN model_year IS NULL THEN 1900 -- handle null model_year values
            ELSE model_year
        END AS model_year,
        CASE
            WHEN list_price IS NULL THEN 0 -- handle null list_price values
            ELSE list_price
        END AS list_price
        
    FROM (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY product_id) AS unique_pd_id, -- ensure the product_id is unique
            product_id,
            product_name,
            brand_id,
            category_id,
            model_year,
            list_price
        FROM bronze.products
    )t
    WHERE unique_pd_id = 1;
    PRINT 'PRODUCTS TABLE LOADED THE DATA WITH TRANSFORMATION';
    SET @end_time = GETDATE();
    PRINT 'THE TIME LOADED OF PRODUCTS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
    
    -- clean and load order_items table
        SET @start_time = GETDATE();
        DELETE FROM silver.order_items;
        INSERT INTO silver.order_items(
            order_id, 
            item_id, 
            product_id, 
            quantity, 
            list_price, 
            discount
        )
        SELECT 
            order_id,
            CASE
                WHEN TRY_CONVERT(INT, item_id) IS NULL THEN 0 -- handle null item_id values
                ELSE TRY_CONVERT(INT, item_id)
            END AS item_id,
            product_id,
            CASE 
                WHEN TRY_CONVERT(INT, quantity) IS NULL THEN 0 -- handle null quantity values
                ELSE TRY_CONVERT(INT, quantity)
            END AS quantity,
            CASE
                WHEN TRY_CONVERT(DECIMAL(10,2), list_price) IS NULL THEN 0 -- handle null list_price values
                ELSE TRY_CONVERT(DECIMAL(10,2), list_price)
            END AS list_price,
            CASE
                WHEN TRY_CONVERT(DECIMAL(4,2), discount) IS NULL THEN 0 -- handle null discount values
                ELSE TRY_CONVERT(DECIMAL(4,2), discount)
            END AS discount
        FROM bronze.order_items;
        PRINT 'ORDER_ITEMS TABLE LOADED THE DATA WITH TRANSFORMATION';
        SET @end_time = GETDATE();
        PRINT 'THE TIME LOADED OF ORDER_ITEMS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';     

    -- clean and load stocks table
    SET @start_time = GETDATE();
    DELETE FROM silver.stocks;
    INSERT INTO silver.stocks(
        store_id, 
        product_id, 
        quantity
    )
    SELECT 
        store_id,
        product_id,
        CASE
            WHEN TRY_CONVERT(INT, quantity) IS NULL THEN 0 -- handle null quantity values
            ELSE TRY_CONVERT(INT, quantity)
        END AS quantity
    FROM bronze.stocks;
    PRINT 'STOCKS TABLE LOADED THE DATA WTHOUT ANY TRANSFORMATION'
    SET @end_time = GETDATE();
    PRINT 'THE TIME LOADED OF STOCKS TABLE IS : ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' second';
    
    SET @batch_end_time = GETDATE();


    -- time loaded of silver layer
    PRINT '==============================================================================================';
    PRINT 'THE TIME LOADED OF SILVER LAYER IS : ' + CAST(DATEDIFF(SECOND, @batch_start_time, GETDATE()) AS NVARCHAR) + ' second';
    PRINT '================================================================================================';
    
    END TRY 

    BEGIN CATCH
        PRINT 'ERROR IN SILVER LAYER LOADING :'+ERROR_MESSAGE();
        PRINT 'THE ERROR LINE NUMBER IS : '+ CAST(ERROR_LINE() AS NVARCHAR);
    END CATCH
    
END