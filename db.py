import mysql.connector
from config import Config
import os

def get_db():
    db_config = {
        "host": Config.DB_HOST,
        "port": Config.DB_PORT,
        "user": Config.DB_USER,
        "password": Config.DB_PASSWORD,
        "database": Config.DB_NAME,
        "connection_timeout": 15,
    }

    # Enable SSL when a CA certificate path is configured
    ca_cert = os.getenv("DB_SSL_CA")

    if ca_cert:
        db_config["ssl_ca"] = ca_cert
        db_config["ssl_verify_cert"] = True
        db_config["ssl_verify_identity"] = True

    return mysql.connector.connect(**db_config)
