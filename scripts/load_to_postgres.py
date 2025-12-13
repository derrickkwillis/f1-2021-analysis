import os
import pandas as pd
from sqlalchemy import create_engine

DATA_DIR = "data"
DB_URI = "postgresql+psycopg2://postgres:postgres@localhost:5432/f1_data"
SCHEMA = "public"

engine = create_engine(DB_URI)

for file in os.listdir(DATA_DIR):
    if file.endswith(".csv"):
        table_name = file.replace(".csv", "").lower()
        file_path = os.path.join(DATA_DIR, file)

        print(f"Loading {file} → table '{table_name}'")

        df = pd.read_csv(file_path)

        df.columns = df.columns.str.lower()

        df.to_sql(
            table_name,
            engine,
            schema=SCHEMA,
            if_exists="replace",
            index=False
        )

print("All CSV files loaded successfully.")
