from app import app, db, User   # IMPORTANT: adjust if your file name is different

with app.app_context():
    User.query.delete()
    db.session.commit()
    print("✅ All users deleted successfully")