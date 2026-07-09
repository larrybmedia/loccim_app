import os
# 🛠️ FIXED: Import the application factory creator along with extensions
from app import create_app, db, User

# Instantiate the app instance from the factory layout
app = create_app()

with app.app_context():
    print("\n====================================")
    print("    LOCCIM NATIVE USER LOOKUP")
    print("====================================\n")
    
    try:
        # Fetch all user entries safely
        users = User.query.all()
        
        if not users:
            print("❌ CRITICAL: The User table is completely EMPTY.")
            print("Your database will auto-seed 'admin' with 'admin1234' on the next server start.")
        else:
            print(f"Found {len(users)} user account(s):\n")
            for index, user in enumerate(users, start=1):
                print(f"[{index}] 👤 Username: {user.username}")
                print(f"    ⚙️  Role:     {user.role}")
                # Clean up display by truncating extremely long security string outputs
                display_hash = user.password if len(user.password) <= 35 else f"{user.password[:35]}..."
                print(f"    🔒 Password Hash: {display_hash}")
                print("-" * 40)
                
    except Exception as e:
        print(f"❌ Database Query Error: {e}")
        print("💡 Tip: Ensure your 'instance/loccim.db' or local SQL service is active.")
        
    print("\n====================================")