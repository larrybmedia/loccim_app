from flask import Blueprint, request
from models import Testimony, db

testimonies_bp = Blueprint("testimonies", __name__)

@testimonies_bp.route("/add_testimony", methods=["POST"])
def add_testimony():
    data = request.json

    t = Testimony(
        name=data["name"],
        message=data["message"]
    )

    db.session.add(t)
    db.session.commit()

    return {"message": "Testimony submitted"}