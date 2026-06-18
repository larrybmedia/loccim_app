import sqlite3

try:
    # Directly connect to the SQLite instance file
    conn = sqlite3.connect(r"C:\loccim_app\loccim_backend\loccim.db")
    cursor = conn.cursor()
    
    print("Connecting to database... Injecting missing columns.")
    
    # Force add the missing columns safely
    cursor.execute("ALTER TABLE gallery ADD COLUMN title TEXT DEFAULT 'Untitled Media';")
    cursor.execute("ALTER TABLE gallery ADD COLUMN media_type TEXT DEFAULT 'image';")
    
    conn.commit()
    print("SUCCESS: Database schema patched! You can delete this script now.")

except sqlite3.OperationalError as e:
    if "duplicate column name" in str(e).lower():
        print("Columns already exist structurally. The schema is good!")
    else:
         print(f"Operational Issue: {e}")
except Exception as e:
    print(f"Error executing script: {e}")
finally:
    if 'conn' in locals():
        conn.close()