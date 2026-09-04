import os
import json
from extensions import db, migrate
from sqlalchemy import func
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
from flask_jwt_extended import JWTManager, create_access_token
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
from flask_cors import cross_origin
from models import (
    User,
    Announcement,
    Book,
    Sermon,
    PrayerRequest,
    Testimony,
    Event,
    Gallery,
    Settings,
    AuditLog,
    Volunteer,
)


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
    cloud_name=os.environ.get("CLOUDINARY_CLOUD_NAME"),
    api_key=os.environ.get("CLOUDINARY_API_KEY"),
    api_secret=os.environ.get("CLOUDINARY_API_SECRET"),
    secure=True,
)

# =========================
# CONFIG
# =========================
class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "loccim_secret")
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY")

    database_url = os.environ.get("DATABASE_URL")

    if database_url and database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    SQLALCHEMY_DATABASE_URI = database_url or "sqlite:///loccim.db"
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # PostgreSQL connection-pool protection for production
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_pre_ping": True,
        "pool_recycle": 300,
    }

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
    print("Database configured:", bool(app.config["SQLALCHEMY_DATABASE_URI"]))


    # =========================
    # CORS CONFIGURATION
    # =========================
    CORS(
        app,
        resources={
            r"/api/*": {
                "origins": [
                    "https://loccim-1a612.web.app",
                    "https://loccim-1a612.firebaseapp.com",
                    "https://loccim-frontend.onrender.com",
                    "http://localhost:10000",
                    "http://127.0.0.1:10000",
                    "http://localhost:5000",
                    "http://127.0.0.1:5000",
                ],
                "allow_headers": [
                    "Content-Type",
                    "Authorization",
                ],
                "methods": [
                    "GET",
                    "POST",
                    "PUT",
                    "DELETE",
                    "OPTIONS",
                ],
            }
        },
        supports_credentials=True,
    )

    db.init_app(app)
    migrate.init_app(app, db)

    jwt = JWTManager(app)
    socketio.init_app(
    app,
    cors_allowed_origins="*",
    async_mode="threading"
)

    @app.after_request
    def security_headers(response):
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-XSS-Protection"] = "1; mode=block"

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
            return jsonify({
                "success": False,
                "error": "Missing request body"
            }), 400

        username = data.get("username")
        password = data.get("password")

        user = User.query.filter_by(username=username).first()

        if user and check_password_hash(user.password, password):

            # Flask web session
            session.clear()
            session["logged_in"] = True
            session["user_id"] = user.id
            session["username"] = user.username
            session.permanent = True

            # JWT for Flutter/mobile API
            access_token = create_access_token(
                identity=str(user.id),
                additional_claims={
                    "role": user.role,
                    "username": user.username,
                }
            )

            return jsonify({
                "success": True,
                "access_token": access_token,
                "role": user.role,
                "username": user.username,
            }), 200

        return jsonify({
            "success": False,
            "error": "Invalid username or password"
        }), 401

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
            prayers=PrayerRequest.query.filter_by(status="Pending").all(),
            testimonies=Testimony.query.order_by(Testimony.id.desc()).all(),
            books=books,
            announcements=announcements,
            live_youtube_views=0,
            total_stream_views=0,
            app_downloads=0
        )


    @app.route("/api/dashboard/stats", methods=["GET"])
    @login_required
    def dashboard_stats():

        members = 102455

        volunteers = Volunteer.query.count()

        prayer_requests = PrayerRequest.query.count()

        testimonies = Testimony.query.filter_by(
            approved=True
        ).count()

        sermon_streams = Sermon.query.count()

        active_users = 8945

        downloads = 48200

        live_viewers = 3245

        return jsonify({
            "members": members,
            "downloads": downloads,
            "active_users": active_users,
            "sermon_streams": sermon_streams,
            "live_viewers": live_viewers,
            "prayer_requests": prayer_requests,
            "testimonies": testimonies,
            "volunteers": volunteers
        })

    @app.route("/api/admin/stats", methods=["GET"])
    def admin_stats():

        from models import (
            Event,
            Sermon,
            Book,
            Testimony,
            Volunteer,
            Prayer
        )

        return jsonify({
            "events": Event.query.count(),
            "sermons": Sermon.query.count(),
            "books": Book.query.count(),
            "testimonies": Testimony.query.count(),
            "volunteers": Volunteer.query.count(),
            "prayers": Prayer.query.count()
        })

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
        
    def download_url(url):
      if url:
          return url.replace("/upload/", "/upload/fl_attachment/")
      return None

    @app.route('/api/sermons')
    def api_sermons():
        print("=== API SERMONS ROUTE HIT ===")

        sermons = Sermon.query.all()

        return jsonify([
            {
                "id": sermon.id,
                "title": sermon.title,
                "notes": sermon.notes,
                "audio_url_1": download_url(sermon.audio_url_1),
                "audio_url_2": download_url(sermon.audio_url_2),
                "sermon_date": sermon.sermon_date.strftime("%Y-%m-%d")
                if sermon.sermon_date else None,
            }
            for sermon in sermons
        ])

    @app.route("/upload_sermon", methods=["POST"])
    @login_required
    def upload_sermon():
        title = request.form.get("title")
        notes = request.form.get("notes")
        sermon_date = request.form.get("sermon_date")

        audio1 = request.files.get("audio_file_1")
        audio2 = request.files.get("audio_file_2")

        # Validate required fields
        if not title:
            flash("Sermon title is required.", "danger")
            return redirect(url_for("manage_sermons"))

        if not sermon_date:
            flash("Sermon date is required. Please select the sermon date.", "danger")
            return redirect(url_for("manage_sermons"))

        # Validate sermon date format
        try:
            parsed_sermon_date = datetime.strptime(
                sermon_date,
                "%Y-%m-%d"
            ).date()
        except (ValueError, TypeError):
            flash("Invalid sermon date. Please select a valid date.", "danger")
            return redirect(url_for("manage_sermons"))

        # Upload audio files
        audio1_url = upload_to_cloudinary(audio1, "sermons") if audio1 else None
        audio2_url = upload_to_cloudinary(audio2, "sermons") if audio2 else None

        # Create sermon
        sermon = Sermon(
            title=title,
            notes=notes,
            audio_url_1=audio1_url,
            audio_url_2=audio2_url,
            sermon_date=parsed_sermon_date,
        )

        try:
            db.session.add(sermon)
            db.session.commit()
            flash("Sermon uploaded successfully!", "success")
        except Exception as e:
            db.session.rollback()
            print("UPLOAD SERMON ERROR:", e)
            flash(f"Error uploading sermon: {e}", "danger")

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
        items = Gallery.query.order_by(Gallery.id.desc()).all()

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

        title = request.form.get("title")
        media_type = request.form.get("media_type", "image")

        files = request.files.getlist("file")

        if not files or files[0].filename == "":
            return jsonify({
                "success": False,
                "error": "No files selected"
            }), 400

        uploaded_items = []

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

        db.session.commit()

        return jsonify({
            "success": True,
            "message": f"Uploaded {len(uploaded_items)} items."
        })
    
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
        

        image_url = None

        # 2. Handle the file upload
        # 'image' MUST match the name="image" in your HTML
        if 'image' in request.files:
            file = request.files['image']
            
            if file and file.filename != '':
                image_url = upload_to_cloudinary(file, "events")

        # 3. Save to database
        new_event = Event(
            title=title,
            date=date,
            location=location,
            image_url=image_url
        )

        db.session.add(new_event)
        db.session.commit()

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
        sermon = db.session.get(Sermon, sermon_id)

        if sermon is None:
            flash("Sermon not found.", "danger")
            return redirect(url_for("manage_sermons"))

        try:
            db.session.delete(sermon)
            db.session.commit()

            flash("Sermon deleted successfully!", "success")

        except Exception as e:
            db.session.rollback()          # <-- IMPORTANT
            print("DELETE ERROR:", e)      # <-- Print to Render logs
            flash(f"Error deleting sermon: {e}", "danger")

        return redirect(url_for("manage_sermons"))

    
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

    @app.route("/volunteers")
    def volunteer_management():
        volunteers = Volunteer.query.order_by(
            Volunteer.created_at.desc()
        ).all()

        return render_template(
            "volunteers.html",
            volunteers=volunteers
        )


    @app.route("/api/volunteers", methods=["POST"])
    def submit_volunteer():
        data = request.get_json()

        try:
            volunteer = Volunteer(
                full_name=data.get("full_name"),
                phone=data.get("phone"),
                email=data.get("email"),
                gender=data.get("gender"),
                branch=data.get("branch"),
                membership_status=data.get("membership_status"),

                joined_date=datetime.fromisoformat(
                    data["joined_date"]
                ).date() if data.get("joined_date") else None,

                address=data.get("address"),
                occupation=data.get("occupation"),
                skills=data.get("skills"),
                experience=data.get("experience"),

                departments=",".join(
                    data.get("departments", [])
                ),

                availability=",".join(
                    data.get("availability", [])
                ),

                baptized=data.get("baptized", False),

                previous_worker=data.get(
                    "previous_worker",
                    False,
                ),

                emergency_name=data.get("emergency_name"),

                emergency_relationship=data.get(
                    "emergency_relationship"
                ),

                emergency_phone=data.get("emergency_phone"),

                reason=data.get("reason"),

                medical_conditions=data.get(
                    "medical_conditions"
                ),

                comments=data.get("comments"),
            )

            db.session.add(volunteer)
            db.session.commit()

            return jsonify({
                "success": True,
                "message": "Volunteer application submitted successfully."
            }), 201

        except Exception as e:
            db.session.rollback()

            return jsonify({
                "success": False,
                "error": str(e)
            }), 500

    @app.route("/api/admin/volunteers", methods=["GET"])
    def get_volunteers():
        volunteers = Volunteer.query.order_by(
            Volunteer.created_at.desc()
        ).all()

        return jsonify([
            {
                "id": v.id,
                "full_name": v.full_name,
                "phone": v.phone,
                "email": v.email,
                "branch": v.branch,
                "gender": v.gender,
                "membership_status": v.membership_status,
                "departments": v.departments.split(",") if v.departments else [],
                "availability": v.availability.split(",") if v.availability else [],
                "status": v.status,
                "created_at": v.created_at.strftime("%d %b %Y"),
            }
            for v in volunteers
        ])

    @app.route("/api/admin/volunteers/<int:id>/approve", methods=["PUT"])
    def approve_volunteer(id):
        volunteer = Volunteer.query.get_or_404(id)

        volunteer.status = "Approved"

        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Volunteer approved."
        })
    
    @app.route("/api/admin/volunteers/<int:id>/reject", methods=["PUT"])
    def reject_volunteer(id):
        volunteer = Volunteer.query.get_or_404(id)

        volunteer.status = "Rejected"

        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Volunteer rejected."
        })
    
    @app.route("/api/admin/volunteers/<int:id>", methods=["DELETE"])
    def delete_volunteer(id):
        volunteer = Volunteer.query.get_or_404(id)

        db.session.delete(volunteer)
        db.session.commit()

        return jsonify({
            "success": True,
            "message": "Volunteer deleted."
        })

    @app.route("/volunteer/<int:id>")
    def volunteer_details(id):
        volunteer = Volunteer.query.get_or_404(id)
        return render_template(
            "volunteer_details.html",
            volunteer=volunteer
        )
        

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

    @app.route("/api/routes")
    def show_routes():
        return jsonify([
            {
                "endpoint": r.endpoint,
                "path": r.rule,
                "methods": list(r.methods)
            }
            for r in app.url_map.iter_rules()
        ])

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