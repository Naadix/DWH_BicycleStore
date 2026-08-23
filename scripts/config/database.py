import urllib.parse
from sqlalchemy import create_engine

def get_sql_engine():
    server = 'localhost'
    database = 'DWH_BicycleStore'
    driver = 'ODBC Driver 18 for SQL Server'
    trusted_connection = 'yes'

    # merge the connection string
    connection_string = f"DRIVER={{{driver}}};SERVER={server};DATABASE={database};Trusted_Connection={trusted_connection};TrustServerCertificate=yes;"
    
    # crypt the connection string
    quoted_connection_string = urllib.parse.quote_plus(connection_string)
    engine_url = f"mssql+pyodbc:///?odbc_connect={quoted_connection_string}"
    
    #create the engine
    engine = create_engine(engine_url)
    return engine

# connect to the database
if __name__ == "__main__":
    try:
        engine = get_sql_engine()
        with engine.connect() as connection:
            print(' THE CONNECTION IS SUCCESSFUL ')
    except Exception as e:
            print(' THE CONNECTION FAILED ', e)