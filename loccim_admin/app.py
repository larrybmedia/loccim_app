from flask import Flask, render_template, request, redirect, url_for, session, jsonify, send_from_directory
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from werkzeug.utils import secure_filename
from flask_socketio import SocketIO
import os
import eventlet
import jwt  # 🔥 Used for Flutter JWT creation
import datetime

eventlet.monkey_patch()

# =========================
# APP INIT
# =========================
app = Flask(__name__)
app.secret_key = "loccim_secret_key"
CORS(app)

# =========================
# SOCKETIO INIT (FIXED SAFE MODE)
# =========================
socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode="eventlet"
)

# =========================
# DATABASE
# =========================
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///loccim.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# =========================
# ADMIN LOGIN CREDENTIALS
# =========================
ADMIN_USER = "admin"
ADMIN_PASS = "1234"

# =========================
# UPLOADS
# =========================
UPLOAD_FOLDER = "uploads"
app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# =========================
# MODELS
# =========================
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(100), unique=True)
    password = db.Column(db.String(200))
    role = db.Column(db.String(50), default="admin")

class Sermon(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200))
    type = db.Column(db.String(50))
    url = db.Column(db.String(300))

class Event(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200))
    date = db.Column(db.String(100))
    location = db.Column(db.String(200))

class PrayerRequest(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    message = db.Column(db.Text)
    status = db.Column(db.String(50), default="Pending")

class Testimony(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    message = db.Column(db.Text)
    approved = db.Column(db.Boolean, default=False)

class Settings(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    live_url = db.Column(db.String(300))

# =========================
# DB CREATE & SEED
# =========================
with app.app_context():
    db.create_all()
    # Pre-seed settings model row so live updates don't throw an error
    if not Settings.query.first():
        db.session.add(Settings(live_url="https://www.youtube.com"))
        db.session.commit()

# =========================
# 🌐 WEB DASHBOARD LOGIN (Session-Based)
# =========================
from flask import render_template, request, redirect, url_for, session

@app.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")

        user = User.query.filter_by(
            username=username,
            password=password
        ).first()

        if user:
            session["logged_in"] = True
            session["user_id"] = user.id
            session["role"] = user.role

            return redirect(url_for("dashboard"))

        return render_template("login.html", error="Invalid username or password")

    return render_template("login.html")

# =========================
# 📱 FLUTTER MOBILE APP LOGIN (JWT-Based API)
# =========================
@app.route("/login", methods=["POST"])
def mobile_login():
    data = request.json or {}
    username = data.get("username")
    password = data.get("password")

    if username == ADMIN_USER and password == ADMIN_PASS:
        token = jwt.encode({
            'username': username,
            'role': 'admin',
            'exp': datetime.datetime.utcnow() + datetime.timedelta(days=7)
        }, app.secret_key, algorithm='HS256')
        
        return jsonify({"token": token, "role": "admin"}), 200

    return jsonify({"error": "Invalid credentials"}), 401

# =========================
# 📊 ANALYTICS DATA ENDPOINT (For Flutter Admin Dashboard)
# =========================
@app.route("/analytics", methods=["GET"])
def get_analytics():
    prayers_count = PrayerRequest.query.filter_by(status="Pending").count()
    sermons_count = Sermon.query.count()
    testimonies_count = Testimony.query.count()

    return jsonify({
        "prayers": prayers_count,
        "sermons": sermons_count,
        "testimonies": testimonies_count
    }), 200

# =========================
# MAIN DASHBOARD PANEL VIEW
# =========================
@app.route("/dashboard")
def dashboard():
    if not session.get("logged_in"):
        return redirect(url_for("login"))

    # FIXED: Removed localized duplicate import statement since models are globally available above
    return render_template(
        "dashboard.html",
        sermons=Sermon.query.all(),
        prayers=PrayerRequest.query.filter_by(status="Pending").all(),
        testimonies=Testimony.query.all()
    )

# =========================
# SERMONS WEB PAGE & API
# =========================
@app.route("/sermons_page")
def sermons_page():
    if not session.get("logged_in"):
        return redirect(url_for("login"))
    return render_template("sermons.html", sermons=Sermon.query.all())

@app.route("/sermons")
def sermons():
    data = Sermon.query.all()
    return jsonify([
        {
            "id": s.id,
            "title": s.title,
            "type": s.type,
            "url": s.url
        } for s in data
    ])

@app.route("/upload_sermon", methods=["POST"])
def upload_sermon():
    if not session.get("logged_in"):
        return {"error": "Unauthorized"}, 401

    title = request.form.get("title")
    file = request.files.get("file")

    if not file:
        return {"error": "No file uploaded"}, 400

    filename = secure_filename(file.filename)
    filepath = os.path.join(app.config["UPLOAD_FOLDER"], filename)
    file.save(filepath)

    sermon = Sermon(
        title=title,
        type="video" if filename.endswith(".mp4") else "audio",
        url=f"/uploads/{filename}"
    )

    db.session.add(sermon)
    db.session.commit()

    socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("sermons_page"))

# =========================
# PRAYERS WEB PAGE & API
# =========================
@app.route("/prayers-page")
def prayers_page():
    if not session.get("logged_in"):
        return redirect(url_for("login"))
    return render_template("prayers.html", prayers=PrayerRequest.query.all())

@app.route("/add_prayer", methods=["POST"])
def add_prayer():
    data = request.json or {}
    prayer = PrayerRequest(name=data["name"], message=data["message"])
    db.session.add(prayer)
    db.session.commit()
    socketio.emit("dashboard_update", {}, broadcast=True)
    return {"message": "Prayer submitted"}

@app.route("/prayers")
def prayers_api():
    data = PrayerRequest.query.all()
    return jsonify([
        {
            "id": p.id,
            "name": p.name,
            "message": p.message,
            "status": p.status
        } for p in data
    ])

@app.route("/prayer/<int:id>/approve", methods=["POST"])
def approve_prayer(id):
    if not session.get("logged_in"): return {"error": "Unauthorized"}, 401
    prayer = PrayerRequest.query.get_or_404(id)
    prayer.status = "Approved"
    db.session.commit()
    socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("prayers_page"))

@app.route("/prayer/<int:id>/reject", methods=["POST"])
def reject_prayer(id):
    if not session.get("logged_in"): return {"error": "Unauthorized"}, 401
    prayer = PrayerRequest.query.get_or_404(id)
    prayer.status = "Rejected"
    db.session.commit()
    socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("prayers_page"))

# =========================
# TESTIMONIES WEB PAGE & API
# =========================
@app.route("/testimonies-page")
def testimonies_page():
    if not session.get("logged_in"):
        return redirect(url_for("login"))
    return render_template("testimonies.html", testimonies=Testimony.query.all())

@app.route("/add_testimony", methods=["POST"])
def add_testimony():
    data = request.json or {}
    t = Testimony(name=data["name"], message=data["message"])
    db.session.add(t)
    db.session.commit()
    socketio.emit("dashboard_update", {}, broadcast=True)
    return {"message": "Testimony submitted"}

@app.route("/testimonies")
def testimonies():
    data = Testimony.query.all()
    return jsonify([
        {
            "id": t.id,
            "name": t.name,
            "message": t.message,
            "approved": t.approved
        } for t in data
    ])

@app.route("/testimony/<int:id>/approve", methods=["POST"])
def approve_testimony(id):
    if not session.get("logged_in"): return {"error": "Unauthorized"}, 401
    t = Testimony.query.get_or_404(id)
    t.approved = True
    db.session.commit()
    socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("testimonies_page"))

# =========================
# EVENTS WEB PAGE & API
# =========================
@app.route("/events-page")
def events_page():
    if not session.get("logged_in"):
        return redirect(url_for("login"))
    return render_template("events.html", events=Event.query.order_by(Event.date.asc()).all())

@app.route("/add_event", methods=["POST"])
def add_event():
    if not session.get("logged_in"): return {"error": "Unauthorized"}, 401
    title = request.form.get("title")
    date = request.form.get("date")
    location = request.form.get("location")
    
    if title and date and location:
        db.session.add(Event(title=title, date=date, location=location))
        db.session.commit()
        socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("events_page"))

@app.route("/events")
def events():
    data = Event.query.all()
    return jsonify([
        {
            "id": e.id,
            "title": e.title,
            "date": e.date,
            "location": e.location
        } for e in data
    ])

# =========================
# LIVE STREAM CONFIGURATIONS
# =========================
@app.route("/livestream-page")
def livestream_page():
    if not session.get("logged_in"):
        return redirect(url_for("login"))
    setting = Settings.query.first()
    return render_template("livestream.html", current_url=setting.live_url if setting else "")

@app.route("/set_live", methods=["POST"])
def set_live():
    if not session.get("logged_in"): return {"error": "Unauthorized"}, 401
    url = request.form.get("url", "").strip()
    setting = Settings.query.first()
    if setting:
        setting.live_url = url
        db.session.commit()
        socketio.emit("dashboard_update", {}, broadcast=True)
    return redirect(url_for("livestream_page"))

@app.route("/live")
def live():
    setting = Settings.query.first()
    return jsonify({"live_url": setting.live_url if setting else ""})

# =========================
# REQUISITE UTILITIES & PING
# =========================
@app.route("/ping")
def ping():
    return jsonify({"message": "LOCCIM backend connected"})

@app.route("/uploads/<filename>")
def uploaded_file(filename):
    return send_from_directory(app.config["UPLOAD_FOLDER"], filename)

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=5001, debug=True)