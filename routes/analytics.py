from flask import jsonify, current_app as app
from models import PrayerRequest, Sermon, Testimony
from flask_jwt_extended import jwt_required
from utils.roles import role_required

# =========================
# 📊 PUBLIC/ADMIN DASHBOARD ANALYTICS (SECURED)
# =========================
@app.route("/analytics/dashboard")
@jwt_required()
@role_required("admin")
def analytics_dashboard():

    prayers = PrayerRequest.query.count()
    sermons = Sermon.query.count()
    testimonies = Testimony.query.count()

    pending_prayers = PrayerRequest.query.filter_by(status="pending").count()

    return jsonify({
        "prayers": prayers,
        "sermons": sermons,
        "testimonies": testimonies,
        "pending_prayers": pending_prayers
    })


# =========================
# 🔐 SIMPLE ANALYTICS (ADMIN ONLY)
# =========================
@app.route("/analytics")
@jwt_required()
@role_required("admin")
def analytics():

    return jsonify({
        "prayers": 10,
        "sermons": 5,
        "testimonies": 7
    })