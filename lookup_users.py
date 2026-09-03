from app import app, db, User

with app.app_context():
    print("\n====================================")
    print("    LOCCIM NATIVE USER LOOKUP")
    print("====================================\n")

    try:
        users = User.query.all()

        if not users:
            print("CRITICAL: The User table is completely EMPTY.")
        else:
            print(f"Found {len(users)} user account(s):\n")

            for index, user in enumerate(users, start=1):
                print(f"[{index}] Username: {user.username}")
                print(f"    Role: {user.role}")
                print("    Password Hash: [HIDDEN]")
                print("-" * 40)

    except Exception as e:
        print(f"Database Query Error: {e}")

    print("\n====================================")