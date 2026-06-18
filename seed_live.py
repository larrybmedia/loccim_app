from app import app
from extensions import db
from models import Settings

with app.app_context():

    existing = Settings.query.first()

    if not existing:

        s = Settings(
            live_url="https://www.youtube.com/watch?v=K18cpp_-gP8"
        )

        db.session.add(s)
        db.session.commit()

        print("Live URL added")

    else:
        print("Live URL already exists")