from flask_socketio import SocketIO

socketio = SocketIO(cors_allowed_origins="*", async_mode="threading")

def init_socket(app):
    socketio.init_app(app)

    @socketio.on("connect")
    def connect():
        print("Client connected")

    return socketio