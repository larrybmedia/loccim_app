from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required
from utils.roles import role_required

admin_bp = Blueprint("admin", __name__)

@admin_bp.route("/admin/dashboard", methods=["GET"])
@jwt_required()
@role_required("admin")
def admin_dashboard():
    return jsonify({
        "message": "Welcome Admin",
        "status": "secure data"
    })