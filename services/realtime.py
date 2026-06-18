from flask_socketio import SocketIO

socketio = SocketIO()

def emit_dashboard_update():
    socketio.emit("dashboard_update", {
        "status": "refresh"
    })