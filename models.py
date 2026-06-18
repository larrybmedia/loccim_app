from extensions import db
import datetime

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)  # hashed
    role = db.Column(db.String(50), default="admin")

class Sermon(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    title = db.Column(db.String(200), nullable=False)

    notes = db.Column(db.Text)

    audio_file_1 = db.Column(db.String(300))

    audio_file_2 = db.Column(db.String(300))

    created_at = db.Column(
    db.DateTime,
    default=datetime.utcnow
)

class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200))
    date = db.Column(db.String(100))
    location = db.Column(db.String(200))
    image_url = db.Column(db.String(500)) # ADD THIS LINE


class PrayerRequest(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    message = db.Column(db.Text)
    status = db.Column(db.String(50), default="pending")


class Testimony(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    message = db.Column(db.Text)
    approved = db.Column(db.Boolean, default=False)


class Settings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    live_url = db.Column(db.String(300))

class AuditLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    action = db.Column(db.String(200))
    module = db.Column(db.String(50))
    created_at = db.Column(db.DateTime, default=db.func.now())

class Gallery(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    # 🛠️ UPDATED: Match the new columns you added via script
    title = db.Column(db.String(200), default='Untitled Media')
    image_url = db.Column(db.String(500))
    media_type = db.Column(db.String(50), default='image')

class Book(db.Model):
    id = db.Column(db.Integer, primary_key=True)

    title = db.Column(db.String(255), nullable=False)

    price = db.Column(db.String(50))

    author = db.Column(
        db.String(255),
        default="Pastor Peter A. Olowoporoku"
    )

    cover_image = db.Column(
        db.String(500),
        nullable=False
    )

    created_at = db.Column(
    db.DateTime,
    default=datetime.utcnow
)
    