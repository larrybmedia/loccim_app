import os
from extensions import db, migrate
from datetime import datetime
from functools import wraps
import cloudinary
import cloudinary.uploader

from flask import (
    Flask, request, jsonify, session,
    redirect, url_for, render_template,
    send_from_directory, flash
)
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from flask_cors import cross_origin
from models import User, Announcement, Book, Sermon, PrayerRequest, Testimony, Event, Gallery, Settings, AuditLog


# =========================
# EXTENSIONS
# =========================
app = Flask(__name__)

socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode="threading",
    logger=True,
    engineio_logger=True
)


# Configure Cloudinary
cloudinary.config(
    cloud_name=os.environ.get("dbj1ycdst"),
    api_key=os.environ.get("469652681695626"),
    api_secret=os.environ.get("4Dvk1ETZlqM0_bM7DqEpkaTkEZE"),
    secure=True,
)

# =========================
# CONFIG
# =========================
class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "loccim_secret")

    database_url = os.environ.get("DATABASE_URL")

    if database_url and database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    SQLALCHEMY_DATABASE_URI = database_url or "sqlite:///loccim.db"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    SESSION_COOKIE_SAMESITE = "None"
    SESSION_COOKIE_SECURE = True


def upload_to_cloudinary(file, folder):
    if not file or file.filename == "":
        return None

    result = cloudinary.uploader.upload(
        file,
        folder=f"LOCCIM/{folder}",
        resource_type="auto"
    )

    return result["secure_url"]

# =========================
# LOGIN DECORATOR
# =========================
def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if not session.get("logged_in"):
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return wrapper


# =========================
# APP FACTORY
# =========================
def create_app():
    app.config.from_object(Config)

    # ✅ FIXED CORS (THIS IS YOUR MAIN ISSUE)
    CORS(
        app,
        resources={r"/*": {"origins": [
            "http://localhost:*",
            "https://loccim-frontend.onrender.com"
        ]}},
        supports_credentials=True
    )

    db.init_app(app)
    migrate.init_app(app, db)
    socketio.init_app(
    app,
    cors_allowed_origins=["https://loccim-frontend.onrender.com"],
    async_mode="threading"
)

    @app.after_request
    def security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-XSS-Protection"] = "1; mode=block"

        # ✅ FIX CORS headers for preflight
        response.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
        response.headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"

        return response

    register_routes(app)

    with app.app_context():
        db.create_all()
        create_default_admin()

    return app


# =========================
# SOCKET FIX
# =========================

@socketio.on('disconnect')
def handle_disconnect():
    print("Client disconnected")


@socketio.on("connect")
def on_connect():
    # 1. Debug: Check if it's hitting this point
    print("Client attempting to connect...")
    
    # 2. Logic check
    setting = Settings.query.first()
    if setting:
        # Note: 'emit' inside a connect handler might be too early 
        # for some clients. Use emit with room=request.sid to be safe.
        from flask import request
        socketio.emit("livestream_updated", {"live_url": setting.live_url}, to=request.sid)
    else:
        print("No settings found in database.")

# =========================
# ROUTES
# =========================
def register_routes(app):
    @app.route("/", methods=["GET", "POST"])
    def login():
        error = None
        if request.method == "POST":
            username = request.form.get("username")
            password = request.form.get("password")
            user = User.query.filter_by(username=username).first()

            if user and check_password_hash(user.password, password):
                session.clear()
                session["logged_in"] = True
                session["user_id"] = user.id
                session["username"] = user.username
                session.permanent = True
                return redirect(url_for("dashboard"))
            error = "Invalid credentials"
        return render_template("login.html", error=error)
    
    @app.route("/api/login", methods=["POST"])
    def api_login():
        data = request.get_json()
        if not data:
            return jsonify({"success": False, "error": "Missing request body"}), 400
        username = data.get("username")
        password = data.get("password")
        user = User.query.filter_by(username=username).first()
        if user and check_password_hash(user.password, password):
            session.clear()
            session["logged_in"] = True
            session["user_id"] = user.id
            session["username"] = user.username
            session.permanent = True
            return jsonify({"success": True, "role": user.role, "username": user.username}), 200
        return jsonify({"success": False, "error": "Invalid username or password"}), 401

    @app.route("/logout")
    def logout():
        session.clear()
        return redirect(url_for("login"))

    @app.route("/favicon.ico")
    def favicon():
        return "", 204

    @app.route("/dashboard")
    @login_required
    def dashboard():

        books = Book.query.order_by(Book.id.desc()).all()

        announcements = Announcement.query.order_by(
            Announcement.created_at.desc()
        ).all()

        return render_template(
            "dashboard.html",
            sermons=Sermon.query.order_by(Sermon.id.desc()).all(),
            prayers=PrayerRequest.query.filter_by(
                status="Pending"
            ).all(),
            testimonies=Testimony.query.order_by(
                Testimony.id.desc()
            ).all(),
            books=books,
            announcements=announcements,
            live_youtube_views=0,
            total_stream_views=0,
            app_downloads=0
        )

    @app.route("/create_admin")
    def create_admin():
        if not User.query.filter_by(username="admin").first():
            admin = User(
                username="admin",
                password=generate_password_hash("admin1234"),
                role="admin"
            )

            db.session.add(admin)
            db.session.commit()

        return "Admin created"

    @app.route("/check_admin")
    def check_admin():
        user = User.query.filter_by(username="admin").first()

        if user:
            return "Admin exists"

        return "Admin missing"
    
    @app.route('/sermons')
    def manage_sermons():
        # Fetch all sermons from the database
        # We use .order_by(Sermon.id.desc()) to show the newest ones first
        sermons = Sermon.query.order_by(Sermon.id.desc()).all()
        
        # Pass the 'sermons' list to the template
        return render_template('sermons.html', sermons=sermons)

    @app.route("/api/admin/change-password", methods=["POST"])
    def change_password():
        data = request.json
        user = User.query.filter_by(username='admin').first()
        
        # 1. Verify current password
        if not check_password_hash(user.password_hash, data['current_password']):
            return jsonify({"message": "Incorrect current password"}), 401
    
        # 2. Update to new password
        user.password_hash = generate_password_hash(data['new_password'])
        db.session.commit()
        return jsonify({"message": "Password updated successfully"})
        
    @app.route('/api/sermons')
    def api_sermons():
        print("=== API SERMONS ROUTE HIT ===")

        sermons = Sermon.query.all()

        return jsonify([
            {
                "id": sermon.id,
                "title": sermon.title,
                "notes": sermon.notes,
                "audio_file_1": sermon.audio_file_1,
                "audio_file_2": sermon.audio_file_2,
            }
            for sermon in sermons
        ])

    @app.route("/upload_sermon", methods=["POST"])
    @login_required
    def upload_sermon():

        title = request.form.get("title")
        notes = request.form.get("notes")

        audio1 = request.files.get("audio_file_1")
        audio2 = request.files.get("audio_file_2")

        audio1_url = upload_to_cloudinary(audio1, "sermons") if audio1 else None
        audio2_url = upload_to_cloudinary(audio2, "sermons") if audio2 else None

        sermon = Sermon(
            title=title,
            notes=notes,
            audio_file_1=audio1_url,
            audio_file_2=audio2_url
        )

        db.session.add(sermon)
        db.session.commit()

        return redirect(url_for("manage_sermons"))

    @app.route("/api/events")
    def api_get_events():
        events = Event.query.all()
        # Ensure 'e.image_url' actually contains a string in the database
        return jsonify([
            {
                "id": e.id, 
                "title": e.title, 
                "date": e.date, 
                "location": e.location, 
                "image_url": e.image_url  # If this is null in DB, it will be null here
            } 
            for e in events
        ]), 200

    @app.route("/api/testimonies", methods=["GET", "POST", "OPTIONS"])
    def api_testimonies():

        print("REQUEST METHOD:", request.method)

        if request.method == "OPTIONS":
            return jsonify({"success": True}), 200

        if request.method == "POST":
            data = request.get_json()

            testimony = Testimony(
                name=data.get("name"),
                message=data.get("message"),
                approved=False
            )

            db.session.add(testimony)
            db.session.commit()

            return jsonify({
                "success": True,
                "message": "Testimony submitted successfully"
            }), 201

        testimonies = Testimony.query.filter_by(approved=True).all()

        return jsonify([
            {
                "id": t.id,
                "name": t.name,
                "message": t.message,
                "approved": t.approved
            }
            for t in testimonies
        ])
    
    @app.route("/api/gallery")
    def api_gallery():

        items = Gallery.query.all()

        return jsonify([
            {
                "id": i.id,
                "title": i.title,
                "image_url": i.image_url,
                "media_type": i.media_type
            }
            for i in items
        ])

    @app.route('/api/about', methods=['GET'])
    def get_about():
        return jsonify({
            "ministry": {
                "name": "LOCCIM Ministries",
                "vision": "Raising kingdom-minded believers with strong spiritual identity and global impact."
            },

            "leadership": [
                {
                    "name": "Prophet Adeniyi P. Olowoporoku",
                    "role": "General Overseer",
                    "image": "https://loccim-backend.onrender.com/static/images/go.jpg",
                    "bio": "Founder and General Overseer of LOCCIM Ministries, called to raise end-time believers."
                },
                {
                    "name": "Pastor (Mrs) Olowoporoku",
                    "role": "Co-Pastor",
                    "image": "https://loccim-backend.onrender.com/static/images/mrs_go.jpg",
                    "bio": "Co-pastor supporting the ministry with teaching, counseling, and women’s fellowship leadership."
                }
            ],

            "contact": {
                "address": "Mercy Camp, Abule-Oba Road, Makogi, Magboro, Ogun State",
                "email": "loccim@gmail.com",
                "phone": "08108647938",
                "website": "www.loccim.com"
            }
        })
    
    @app.route("/api/live")
    def api_get_live():
        setting = Settings.query.first()
        return jsonify({"live_url": setting.live_url if setting else ""}), 200


    @app.route("/api/prayers", methods=["POST"])
    def submit_prayer():
        data = request.get_json()

        print("Received prayer request:")
        print(data)

        prayer = PrayerRequest(
            name=data.get("name"),
            message=data.get("message")
        )

        db.session.add(prayer)
        db.session.commit()

        print("Prayer saved successfully!")

        return jsonify({
            "success": True,
            "message": "Prayer request submitted successfully"
        }), 201

    @app.route("/events")
    def events():
        if not session.get("logged_in"): return redirect(url_for("login"))
        return render_template("events.html", events=Event.query.order_by(Event.id.desc()).all())

    @app.route("/gallery")
    @login_required
    def gallery():
        gallery_items = Gallery.query.order_by(Gallery.id.desc()).all()

        print("Gallery template loaded")
        print("Gallery items:", len(gallery_items))

        return render_template(
            "gallery.html",
            gallery=gallery_items
        )
    
    @app.route("/upload_gallery", methods=["POST"])
    def upload_gallery():
        # 1. Get title and media_type from the request form
        title = request.form.get("title")
        media_type = request.form.get("media_type")
        
        # 2. Get the list of files from the request
        files = request.files.getlist("file")
        
        if not files or files[0].filename == '':
            return jsonify({"success": False, "error": "No files selected"}), 400

        uploaded_items = []
        
        # 3. Process the files
        for file in files:
            if file and file.filename:
                url = upload_to_cloudinary(file, "gallery")

                gallery_item = Gallery(
                    title=title,
                    media_type=media_type,
                    image_url=url
                )
                db.session.add(gallery_item)
                uploaded_items.append(gallery_item)
                
        # 5. Commit all at once
        db.session.commit()
        
        return jsonify({"success": True, "message": f"Uploaded {len(uploaded_items)} items."})

    @app.route("/prayers")
    @login_required
    def prayers():
        return render_template("prayers.html", prayers=PrayerRequest.query.all())

    @app.route("/testimonies")
    @login_required
    def testimonies():
        return render_template(
            "testimonies.html",
            testimonies=Testimony.query.all()
        )
    
    @app.route("/submit_testimony", methods=["POST", "OPTIONS"])
    def submit_testimony():

        print("REQUEST METHOD:", request.method)

        if request.method == "OPTIONS":
            return jsonify({"success": True}), 200

        data = request.get_json()

        print("DATA RECEIVED:", data)

        testimony = Testimony(
            name=data.get("name"),
            message=data.get("message"),
            approved=False
        )

        db.session.add(testimony)

        print("BEFORE COMMIT")

        db.session.commit()

        print("AFTER COMMIT")
        print("NEW TESTIMONY ID:", testimony.id)

        return jsonify({
            "success": True,
            "message": "Testimony submitted successfully"
        }), 201
        
    @app.route("/add_event", methods=["POST"])
    def add_event():
        # 1. Capture text fields
        title = request.form.get("title")
        date = request.form.get("date")
        location = request.form.get("location")
        
        print(f"DEBUG: Form data received: {title}, {date}, {location}")

        image_url = None

        # 2. Handle the file upload
        # 'image' MUST match the name="image" in your HTML
        if 'image' in request.files:
            file = request.files['image']
            
            if file and file.filename != '':
                image_url = upload_to_cloudinary(file, "events")
        else:
            print("DEBUG: No file found in request.files")

        # 3. Save to database
        new_event = Event(
            title=title,
            date=date,
            location=location,
            image_url=image_url
        )

        db.session.add(new_event)
        db.session.commit()
        print("DEBUG: Event committed to database.")

        return redirect(url_for("events"))

   # Ensure the methods list explicitly includes 'DELETE'
    @app.route("/delete_event/<int:event_id>", methods=["DELETE"])
    def delete_event(event_id):
        event = Event.query.get(event_id)

        if not event:
            return jsonify({
                "success": False,
                "error": "Event not found"
            }), 404

        try:
            # Delete the event from the database
            db.session.delete(event)
            db.session.commit()

            return jsonify({
                "success": True,
                "message": "Event deleted successfully."
            }), 200

        except Exception as e:
            db.session.rollback()

            return jsonify({
                "success": False,
                "error": str(e)
            }), 500

    # Update the route to specifically allow POST
    @app.route("/delete_sermon/<int:sermon_id>", methods=["POST"])
    @login_required
    def delete_sermon(sermon_id):
        sermon = db.session.get(Sermon, sermon_id) # Modern syntax
        if not sermon:
            flash("Sermon not found.", "danger")
            return redirect(url_for('sermons'))
            
        try:
            # Add file deletion logic here
            db.session.delete(sermon)
            db.session.commit()
            flash("Sermon deleted successfully!", "success")
        except Exception as e:
            flash(f"Error: {str(e)}", "danger")
            
        return redirect(url_for('sermons'))

    
    @app.route("/admin/delete-gallery/<int:id>", methods=["POST"])
    @login_required
    def delete_gallery(id):
        image = Gallery.query.get_or_404(id)

        db.session.delete(image)
        db.session.commit()

        flash("Gallery item deleted successfully", "success")
        return redirect("/gallery")

    @app.route("/delete_prayer/<int:id>", methods=["POST"])
    @login_required
    def delete_prayer(id):
        item = PrayerRequest.query.get_or_404(id)

        db.session.delete(item)
        db.session.commit()

        return redirect(url_for("prayers"))

    @app.route("/approve_testimony/<int:id>", methods=["POST"])
    @login_required
    def approve_testimony(id):
        testimony = Testimony.query.get_or_404(id)

        testimony.approved = True
        db.session.commit()

        return redirect(url_for("testimonies"))
    
    @app.route("/delete_testimony/<int:id>", methods=["DELETE"])
    def delete_testimony(id):
        t = Testimony.query.get(id)
        if t:
            db.session.delete(t)
            db.session.commit()
        return jsonify({"success": True})

    @app.route("/livestream")
    @login_required
    def livestream():
        setting = Settings.query.first()
        return render_template("livestream.html", current_url=setting.live_url if setting else "")
    

    @app.route("/api/set_live", methods=["POST"])
    def set_live():
        live_url = request.form.get("live_url")

        setting = Settings.query.first()

        if not setting:
            setting = Settings()
            db.session.add(setting)

        setting.live_url = live_url
        db.session.commit()

        flash("Live stream updated successfully!", "success")

        return redirect(url_for("livestream"))
    
    @app.route("/books")
    @login_required
    def books():

        books = Book.query.order_by(Book.id.desc()).all()

        return render_template(
            "books.html",
            books=books
        )

    @app.route("/api/books", methods=["GET"])
    def api_books():

        BASE_URL = os.environ.get(
            "BASE_URL",
            "https://loccim-backend.onrender.com"
        )

        books = Book.query.order_by(Book.created_at.desc()).all()

        return jsonify([
            {
                "id": book.id,
                "title": book.title,
                "price": book.price,
                "cover_image": book.cover_image,
                "author": book.author if hasattr(book, "author") else "Pastor Peter A. Olowoporoku"
            }
            for book in books
        ])
    

    @app.route("/upload_book", methods=["POST"])
    @login_required
    def upload_book():

        title = request.form.get("title")
        author = request.form.get("author")
        price = request.form.get("price")

        cover = request.files.get("cover")

        if not cover:
            return jsonify({
                "success": False,
                "error": "No cover image selected"
            }), 400

        cover_url = upload_to_cloudinary(cover, "books")

        book = Book(
            title=title,
            author=author,
            price=price,
            cover_image=cover_url
        )

        db.session.add(book)
        db.session.commit()

        return jsonify({
            "success": True
        })

    @app.route('/api/announcements')
    def get_announcements():

        announcements = Announcement.query.order_by(
            Announcement.created_at.desc()
        ).all()

        return jsonify([
            {
                "id": a.id,
                "title": a.title,
                "message": a.message,
                "type": a.type,
                "category": a.category,
                "flyer": a.flyer,
                "video": a.video,
                "created_at": a.created_at.strftime("%Y-%m-%d")
            }
            for a in announcements
        ])
    
    @app.route('/announcements')
    @login_required
    def announcements_page():

        announcements = Announcement.query\
            .order_by(Announcement.created_at.desc())\
            .all()

        return render_template(
            "announcements.html",
            announcements=announcements
        )

    @app.route('/admin/create-announcement', methods=['POST'])
    @login_required
    def create_announcement_dashboard():

        flyer = request.files.get("flyer")
        video = request.files.get("video")

        flyer_path = None
        video_path = None

        if flyer and flyer.filename:
            flyer_path = upload_to_cloudinary(flyer, "announcements")

        if video and video.filename:
            video_path = upload_to_cloudinary(video, "announcements")

        announcement = Announcement(
            title=request.form["title"],
            message=request.form["message"],
            type=request.form["type"],
            category=request.form["category"],
            flyer=flyer_path,
            video=video_path
        )

        db.session.add(announcement)
        db.session.commit()

        return redirect("/announcements")
    
    @app.route("/admin/delete-announcement/<int:id>", methods=["POST"])
    @login_required
    def delete_announcement(id):
        announcement = Announcement.query.get_or_404(id)

        db.session.delete(announcement)
        db.session.commit()

        flash("Announcement deleted successfully", "success")
        return redirect("/announcements")

    @app.route("/api/contact", methods=["POST"])
    def contact():
        data = request.get_json()

        name = data.get("name")
        email = data.get("email")
        message = data.get("message")

        if not name or not email or not message:
            return jsonify({
                "success": False,
                "error": "All fields are required"
            }), 400

        # You can save to DB or send email here
        print("NEW CONTACT MESSAGE:", data)

        return jsonify({
            "success": True
        })
        

    @app.route("/delete_book/<int:book_id>", methods=["DELETE"])
    @login_required
    def delete_book(book_id):

        book = Book.query.get(book_id)

        if not book:
            return jsonify({
                "success": False
            }), 404

        db.session.delete(book)
        db.session.commit()

        return jsonify({
            "success": True
        })

    @app.route("/api/version")
    def get_version():
        return jsonify({
            "version": "1.0.1",
            "download_url": "https://your-site.com/downloads/app-latest.apk",
            "force_update": False
        })


def create_default_admin():
    if not User.query.filter_by(username="admin").first():
        db.session.add(User(username="admin", password=generate_password_hash("admin1234"), role="admin"))
        db.session.commit()


# =========================
# RUN
# =========================
app = create_app()

if __name__ == "__main__":
    socketio.run(app, host="0.0.0.0", port=10000)