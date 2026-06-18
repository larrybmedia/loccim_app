from flask import Blueprint, request, session, redirect, url_for, render_template
from models import User
from flask_jwt_extended import create_access_token
import bcrypt

auth_bp = Blueprint("auth", __name__)

# =========================
# 🔐 FLUTTER LOGIN (JWT API)
# =========================
@auth_bp.route("/api/login", methods=["POST"])
def api_login():
    data = request.json
    user = User.query.filter_by(username=data["username"]).first()

    if not user:
        return {"error": "Invalid username"}, 401

    if not bcrypt.checkpw(
        data["password"].encode("utf-8"),
        user.password.encode("utf-8")
    ):
        return {"error": "Invalid password"}, 401

    token = create_access_token(identity={
        "id": user.id,
        "role": user.role
    })

    return {"token": token}


# =========================
# 🟣 WEB ADMIN LOGIN (HTML DASHBOARD)
# =========================
ADMIN_USER = "admin"
ADMIN_PASS = "1234"

@auth_bp.route("/", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        if (
            request.form["username"] == ADMIN_USER and
            request.form["password"] == ADMIN_PASS
        ):
            session["logged_in"] = True
            return redirect(url_for("dashboard.dashboard"))

    return render_template("login.html")