from scripts.config.database import get_sql_engine
import pandas as pd

# call the engine
engine = get_sql_engine()

file_list = [ 'brands.csv','categories.csv','customers.csv','order_items.parquet'
             ,'orders.csv','products.csv','staffs.csv','stocks.csv','stores.csv'
]

for file in file_list:
    print(f'=============== HANDLING FILE : {file.upper()} ===============')
    # store the path
    file_path = f'data/{file}'
    # read the file
    if file.endswith('.csv'):
        df = pd.read_csv(file_path)
    elif file.endswith('.parquet'):
        df = pd.read_parquet(file_path)
    else:
        continue

    table_name = file.split('.')[0]

    # load the data to the database
    try:
        df.to_sql(
                name=table_name,
                con=engine,
                schema='bronze',
                if_exists='replace',
                index=False
        )
    except Exception as e:
        print(f'ERROR OCCURED DURING LOAD TABLE {table_name} ', e)

print('=============== ALL TABLES LOADED SUCCESSFULLY IN BRONZE LAYER ===============')