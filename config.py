import os
import cloudinary

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY", "loccim_secret_key")

    # Database
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "sqlite:///loccim.db"
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Upload folder (optional for temporary files)
    UPLOAD_FOLDER = "uploads"


# Configure Cloudinary
cloudinary.config(
    cloud_name=os.environ.get("dbj1ycdst"),
    api_key=os.environ.get("469652681695626"),
    api_secret=os.environ.get("4Dvk1ETZlqM0_bM7DqEpkaTkEZE"),
    secure=True,
)