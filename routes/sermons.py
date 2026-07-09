from flask import Blueprint, request, jsonify, session
from werkzeug.utils import secure_filename
import os
from flask import current_app
from extensions import db
from models import Sermon
from extensions import socketio

sermons_bp = Blueprint("sermons", __name__)

@sermons_bp.route("/sermons")
def get_sermons():
    data = Sermon.query.all()
    return jsonify([
        {"title": s.title, "type": s.type, "url": s.url} for s in data
    ])


@sermons_bp.route("/upload_sermon", methods=["POST"])
def upload_sermon():
    if not session.get("logged_in"):
        return {"error": "Unauthorized"}, 401

    title = request.form["title"]
    file = request.files["file"]

    filename = secure_filename(file.filename)
    filepath = os.path.join(
    current_app.config["UPLOAD_FOLDER"],
    filename
)

    sermon = Sermon(
        title=title,
        type="video" if filename.endswith(".mp4") else "audio",
        url=f"/uploads/{filename}"
    )

    db.session.add(sermon)
    db.session.commit()

    socketio.emit("stats_update", {
    "type": "sermon",
    "action": "created"
})

    return {"message": "Uploaded"}