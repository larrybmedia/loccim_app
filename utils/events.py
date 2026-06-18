from extensions import socketio

def emit_event(event_type, payload):
    socketio.emit("admin_event", {
        "type": event_type,
        "data": payload
    }, broadcast=True)