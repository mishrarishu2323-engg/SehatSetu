from getpass import getpass
from werkzeug.security import generate_password_hash
from db import get_db

def main():
    name = input("Admin full name: ").strip()
    email = input("Admin email: ").strip().lower()
    password = getpass("Admin password (minimum 8 characters): ")
    if not name or not email or len(password) < 8:
        raise SystemExit("Name/email required; password must be at least 8 characters.")
    conn = get_db()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO users(full_name,email,password_hash,role) VALUES(%s,%s,%s,'admin')",
                    (name,email,generate_password_hash(password)))
        conn.commit()
        print("Admin account created successfully. Keep your password private.")
    finally:
        cur.close()
        conn.close()
if __name__ == "__main__":
    main()
