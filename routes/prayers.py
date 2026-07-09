from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from models import PrayerRequest, AuditLog # Grouped models together safely
from extensions import db, socketio        # Grouped extensions together cleanly
from utils.roles import role_required
from utils.events import emit_event

prayers_bp = Blueprint("prayers", __name__)


# =========================
# ➕ ADD PRAYER REQUEST
# =========================
@prayers_bp.route("/add_prayer", methods=["POST"])
def add_prayer():
    data = request.json

    prayer = PrayerRequest(
        name=data["name"],
        message=data["message"]
    )

    db.session.add(prayer)
    db.session.commit()

    # 🔥 REAL-TIME EVENT
    emit_event("dashboard_update", {
        "type": "prayer",
        "action": "created"
    })

    return {"message": "Prayer submitted successfully"}


# =========================
# 📥 GET ALL PRAYERS
# =========================
@prayers_bp.route("/prayers", methods=["GET"])
def get_prayers():
    prayers = PrayerRequest.query.all()

    return jsonify([
        {
            "id": p.id,
            "name": p.name,
            "message": p.message,
            "status": p.status
        }
        for p in prayers
    ])


# =========================
# 🟢 APPROVE PRAYER (ADMIN ONLY)
# =========================
@prayers_bp.route("/prayer/<int:id>/approve", methods=["PUT"])
@jwt_required()
def approve_prayer(id):
    prayer = PrayerRequest.query.get(id)

    if not prayer:
        return {"error": "Not found"}, 404

    prayer.status = "approved"
    db.session.commit()

    emit_event("dashboard_update", {
        "type": "prayer",
        "action": "approved",
        "id": id
    })

    # FIXED: This block was sitting completely outside the function!
    # Moving it inside keeps it within the application context and makes 'id' accessible.
    log = AuditLog(
        action=f"Approved prayer {id}",
        module="prayer"
    )
    db.session.add(log)
    db.session.commit()

    emit_event("audit_log", {
        "action": log.action,
        "module": log.module
    })

    return {"message": "Prayer approved"}


# =========================
# 🔴 REJECT PRAYER (ADMIN ONLY)
# =========================
@prayers_bp.route("/prayer/<int:id>/reject", methods=["PUT"])
@jwt_required()
def reject_prayer(id):
    prayer = PrayerRequest.query.get(id)

    if not prayer:
        return {"error": "Not found"}, 404

    prayer.status = "rejected"
    db.session.commit()

    # 🔥 REAL-TIME UPDATE
    emit_event("dashboard_update", {
        "type": "prayer",
        "action": "rejected"
    })

    return {"message": "Prayer rejected"}


# =========================
# 📝 SUBMIT PRAYER PLACEHOLDER
# =========================
@prayers_bp.route('/submit-prayer', methods=['POST'])
def submit_prayer():
    # Kept intact from your previous placeholder structure
    # Note: Make sure PrayerLog is imported from your models if you intend to use it later!
    from models import PrayerLog 
    
    log = PrayerLog(message="Someone requested a prayer")
    db.session.add(log)
    db.session.commit()
    
    return {"status": "success"}, 201