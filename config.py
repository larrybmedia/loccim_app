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
    cloud_name=os.environ.get("CLOUDINARY_CLOUD_NAME"),
    api_key=os.environ.get("CLOUDINARY_API_KEY"),
    api_secret=os.environ.get("CLOUDINARY_API_SECRET"),
    secure=True,
)