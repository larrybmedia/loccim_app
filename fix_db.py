import sqlite3
import os
import glob

# Search across common locations for the actual file
possible_paths = glob.glob("**/loccim.db", recursive=True) + ["loccim.db"]
valid_db = None

for path in possible_paths:
    if os.path.exists(path):
        # Let's check if this database actually has tables
        try:
            conn = sqlite3.connect(path)
            cursor = conn.cursor()
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [t[0] for t in cursor.fetchall()]
            conn.close()
            
            if "gallery" in tables:
                valid_db = path
                break
        except Exception:
            continue

if not valid_db:
    print("❌ Could not locate the active loccim.db file containing the 'gallery' table.")
    print("Checked files:", [os.path.abspath(p) for p in possible_paths if os.path.exists(p)])
    print("\n💡 Alternative: If you don't mind resetting your local test data, just look for 'loccim.db' files in your project and delete them manually. Flask will rebuild it automatically!")
    exit()

print(f"🎯 FOUND ACTIVE DATABASE AT: {os.path.abspath(valid_db)}")

try:
    conn = sqlite3.connect(valid_db)
    cursor = conn.cursor()

    # Add title column
    try:
        cursor.execute("ALTER TABLE gallery ADD COLUMN title TEXT DEFAULT 'Untitled Media';")
        print("✅ Column 'title' successfully added!")
    except sqlite3.OperationalError as e:
        print(f"⚠️ Column 'title' status: {e}")

    # Add media_type column
    try:
        cursor.execute("ALTER TABLE gallery ADD COLUMN media_type TEXT DEFAULT 'image';")
        print("✅ Column 'media_type' successfully added!")
    except sqlite3.OperationalError as e:
        print(f"⚠️ Column 'media_type' status: {e}")

    conn.commit()
    conn.close()
    print("🎉 Structural update successful!")

except Exception as e:
    print(f"❌ Error during modification: {e}")