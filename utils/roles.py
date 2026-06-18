from functools import wraps
from flask_jwt_extended import verify_jwt_in_request, get_jwt
from flask import jsonify

def role_required(required_role):
    def wrapper(fn):
        @wraps(fn)
        def decorator(*args, **kwargs):
            verify_jwt_in_request()

            claims = get_jwt()
            role = claims.get("role")

            if role != required_role:
                return jsonify({
                    "error": "Access denied",
                    "message": "Insufficient permissions"
                }), 403

            return fn(*args, **kwargs)
        return decorator
    return wrapper