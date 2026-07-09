from flask import Blueprint, jsonify, request
from models import Event, db

events_bp = Blueprint("events", __name__)

@events_bp.route("/events")
def get_events():
    events = Event.query.all()
    return jsonify([
        {"title": e.title, "date": e.date, "location": e.location}
        for e in events
    ])