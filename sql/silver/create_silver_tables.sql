/*          
  this file contains the SQL statements to create the silver tables in the data warehouse.
  Note : if run script multiple times, it will drop the existing tables and create new ones.
*/


-- Drop tables if they already exist
IF OBJECT_ID('silver.order_items', 'U') IS NOT NULL
    DROP TABLE silver.order_items;

IF OBJECT_ID('silver.orders', 'U') IS NOT NULL
    DROP TABLE silver.orders;

IF OBJECT_ID('silver.stocks', 'U') IS NOT NULL
    DROP TABLE silver.stocks;

IF OBJECT_ID('silver.staffs', 'U') IS NOT NULL
    DROP TABLE silver.staffs;

IF OBJECT_ID('silver.products', 'U') IS NOT NULL
    DROP TABLE silver.products;

IF OBJECT_ID('silver.customers', 'U') IS NOT NULL
    DROP TABLE silver.customers;

IF OBJECT_ID('silver.stores', 'U') IS NOT NULL
    DROP TABLE silver.stores;

IF OBJECT_ID('silver.categories', 'U') IS NOT NULL
    DROP TABLE silver.categories;

IF OBJECT_ID('silver.brands', 'U') IS NOT NULL
    DROP TABLE silver.brands;
GO

-- create brands table 
CREATE TABLE silver.brands(

    brand_id INT PRIMARY KEY NOT NULL,
    brand_name NVARCHAR(50) NOT NULL,
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO


-- create stores table
CREATE TABLE silver.stores(

    store_id INT PRIMARY KEY NOT NULL,
    store_name NVARCHAR(100),
    phone NVARCHAR(20),
    email NVARCHAR(50),
    street NVARCHAR(100),
    city NVARCHAR(100),
    state NVARCHAR(10),
    zip_code NVARCHAR(10),
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO

-- create categories table
CREATE TABLE silver.categories(

    category_id INT PRIMARY KEY NOT NULL,
    category_name NVARCHAR(100) NOT NULL,
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO

-- create customers table 
CREATE TABLE silver.customers(

    customer_id INT PRIMARY KEY NOT NULL,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    phone NVARCHAR(20),
    email NVARCHAR(50),
    street NVARCHAR(100),
    city NVARCHAR(100),
    state NVARCHAR(10),
    zip_code NVARCHAR(10),
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO


-- create products table
CREATE TABLE silver.products(

    product_id INT PRIMARY KEY NOT NULL,
    product_name NVARCHAR(100),
    brand_id INT  CONSTRAINT fk_brand_id_products_table FOREIGN KEY REFERENCES silver.brands(brand_id),
    category_id INT CONSTRAINT fk_category_id_products_table FOREIGN KEY REFERENCES silver.categories(category_id),
    model_year INT,
    list_price DECIMAL(10,2),
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO

-- create staffs table
CREATE TABLE silver.staffs(

    staff_id INT PRIMARY KEY NOT NULL,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    email NVARCHAR(50),
    phone NVARCHAR(20),
    active BIT,
    store_id INT CONSTRAINT fk_store_id_staffs_table FOREIGN KEY REFERENCES silver.stores(store_id),
    manager_id INT,
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO

-- create stocks table
CREATE TABLE silver.stocks(
    
    stock_sk INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    store_id INT  CONSTRAINT fk_store_id_stocks_table FOREIGN KEY REFERENCES silver.stores(store_id),
    product_id INT  CONSTRAINT fk_product_id_stocks_table FOREIGN KEY REFERENCES silver.products(product_id),
    quantity INT,
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO



-- create orders table
CREATE TABLE silver.orders(

    order_id INT PRIMARY KEY NOT NULL,
    customer_id INT CONSTRAINT fk_customer_id FOREIGN KEY REFERENCES silver.customers(customer_id),
    order_status INT,
    order_date DATE,
    required_date DATE,
    shipped_date DATE,
    store_id INT  CONSTRAINT fk_store_id_orders_table FOREIGN KEY REFERENCES silver.stores(store_id),
    staff_id INT  CONSTRAINT fk_staff_id_orders_table FOREIGN KEY REFERENCES silver.staffs(staff_id),
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO


-- create order_items table 
CREATE TABLE silver.order_items(
    order_item_sk INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    order_id INT CONSTRAINT fk_order_id_order_items_table FOREIGN KEY REFERENCES silver.orders(order_id),
    item_id INT ,
    product_id INT CONSTRAINT fk_product_id_order_items_table FOREIGN KEY REFERENCES silver.products(product_id),
    quantity INT , 
    list_price DECIMAL(10,2),
    discount DECIMAL(4,2),
    dwh_created_date DATETIME DEFAULT GETDATE()
)
GO