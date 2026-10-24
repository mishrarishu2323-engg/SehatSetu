import os
from pathlib import Path

from dotenv import load_dotenv


# Load environment variables from the project folder's .env file
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env")


class Config:
    # Flask session security
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY")

    if not SECRET_KEY:
        raise RuntimeError(
            "FLASK_SECRET_KEY is missing. "
            "Add it to your project's .env file."
        )

    # MySQL connection settings
    DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
    DB_PORT = int(os.getenv("DB_PORT", "3306"))
    DB_NAME = os.getenv("DB_NAME", "sehatsetu_db")
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")

    # Flask settings
    DEBUG = os.getenv("FLASK_DEBUG", "0") == "1"

    # Session cookie security
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = "Lax"
    SESSION_COOKIE_SECURE = (
        os.getenv("SESSION_COOKIE_SECURE", "0") == "1"
    )
