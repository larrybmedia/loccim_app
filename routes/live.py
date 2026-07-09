from flask import Blueprint, jsonify
from models import Settings

live_bp = Blueprint("live", __name__)

@live_bp.route("/live")
def live():

    setting = Settings.query.first()

    return jsonify({
        "live_url": setting.live_url if setting else ""
    })