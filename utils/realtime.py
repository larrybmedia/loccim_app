from extensions import socketio

def emit_event(event_name, data):
    socketio.emit(event_name, data, broadcast=True)