from app import app
from extensions import db
from models import User
import bcrypt

with app.app_context():

    # ❌ prevent duplicate admin
    existing = User.query.filter_by(username="admin").first()
    if existing:
        print("Admin already exists")
        exit()

    hashed = bcrypt.hashpw(
        "1234".encode("utf-8"),
        bcrypt.gensalt()
    )

    admin = User(
        username="admin",
        password=hashed.decode("utf-8"),
        role="admin"
    )

    db.session.add(admin)
    db.session.commit()

    print("Admin created successfully")