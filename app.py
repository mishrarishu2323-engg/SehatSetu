import os
import json
from functools import wraps

from flask import (
    Flask,
    jsonify,
    request,
    session,
    redirect,
    send_from_directory,
    render_template
)

from werkzeug.security import (
    generate_password_hash,
    check_password_hash
)

from mysql.connector import Error
from config import Config
from db import get_db


app = Flask(__name__)
app.config.from_object(Config)
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

FRONTEND = BASE_DIR / "frontend" / "SehatSetu"
PAGES = FRONTEND / "pages"
CSS = FRONTEND / "css"
JS = FRONTEND / "js"
ASSETS = FRONTEND / "assets"
# =====================================
# FRONTEND ROUTES
# =====================================

@app.get("/")
@app.get("/index.html")
def home():
    return send_from_directory(FRONTEND, "index.html")


@app.get("/pages/<path:filename>")
def pages(filename):
    return send_from_directory(PAGES, filename)


@app.get("/css/<path:filename>")
def css(filename):
    return send_from_directory(CSS, filename)


@app.get("/js/<path:filename>")
def js(filename):
    return send_from_directory(JS, filename)


@app.get("/assets/<path:filename>")
def assets(filename):
    return send_from_directory(ASSETS, filename)


# =====================================
# DATABASE QUERY FUNCTION
# =====================================

def query(sql, params=(), one=False, commit=False):

    conn = get_db()

    if conn is None:
        raise RuntimeError("Database connection unavailable.")

    cur = None

    try:
        cur = conn.cursor(dictionary=True)

        cur.execute(sql, params)

        if commit:
            conn.commit()
            return cur.lastrowid

        if one:
            return cur.fetchone()

        return cur.fetchall()

    except Exception:
        if commit:
            conn.rollback()
        raise

    finally:
        if cur is not None:
            cur.close()

        conn.close()


# =====================================
# LOGIN REQUIRED DECORATOR
# =====================================

def logged_in(fn):

    @wraps(fn)
    def wrapped(*args, **kwargs):

        if not session.get("user_id"):
            return jsonify({
                "ok": False,
                "message": "Please log in first."
            }), 401

        return fn(*args, **kwargs)

    return wrapped


# =====================================
# DATABASE HEALTH CHECK
# =====================================

@app.get("/api/health")
def health():

    try:
        query("SELECT 1", one=True)

        return jsonify({
            "ok": True,
            "message": "Flask and MySQL are connected."
        })

    except Exception:
        app.logger.exception("Database health check failed")

        return jsonify({
            "ok": False,
            "message": "Database connection failed. Check config and database."
        }), 503


# =====================================
# PATIENT REGISTRATION
# =====================================

@app.post("/api/register")
def register():

    data = request.get_json(silent=True) or request.form

    name = (
        data.get("name")
        or data.get("fullName")
        or ""
    ).strip()

    email = (data.get("email") or "").strip().lower()

    phone = (data.get("phone") or "").strip() or None

    password = data.get("password") or ""

    if not name or not email or len(password) < 8:

        return jsonify({
            "ok": False,
            "message": "Name and email are required. Password must contain at least 8 characters."
        }), 400

    try:

        query(
            """
            INSERT INTO users
            (full_name, email, phone, password_hash, role)
            VALUES (%s, %s, %s, %s, 'patient')
            """,
            (
                name,
                email,
                phone,
                generate_password_hash(password)
            ),
            commit=True
        )

        return jsonify({
            "ok": True,
            "message": "Account created. You can now log in."
        }), 201

    except Error as exc:

        if getattr(exc, "errno", None) == 1062:

            return jsonify({
                "ok": False,
                "message": "This email or phone number is already registered."
            }), 409

        app.logger.exception("Registration failed")

        return jsonify({
            "ok": False,
            "message": "Registration failed. Check the database setup."
        }), 500



        not check_password_hash(
            user["password_hash"],
            password
        )# =====================================
# LOGIN: ADMIN AND PATIENT
# =====================================

@app.post("/api/login")
def login():

    data = request.get_json(silent=True) or request.form

    email_or_phone = (
        data.get("email")
        or data.get("adminEmail")
        or ""
    ).strip().lower()

    password = (
        data.get("password")
        or data.get("adminPassword")
        or ""
    )

    role_required = (
        "admin"
        if "adminEmail" in data
        or request.args.get("role") == "admin"
        else "patient"
    )

    if not email_or_phone or not password:

        return jsonify({
            "ok": False,
            "message": "Email/phone and password are required."
        }), 400

    try:

        user = query(
            """
            SELECT
                user_id,
                full_name,
                email,
                password_hash,
                role,
                is_active
            FROM users
            WHERE email = %s OR phone = %s
            LIMIT 1
            """,
            (email_or_phone, email_or_phone),
            one=True
        )

    except Exception:

        app.logger.exception("Login query failed")

        return jsonify({
            "ok": False,
            "message": "Login failed because of a database error."
        }), 503

    if (
        not user
        or not user["is_active"]
        or user["role"] != role_required
        or not check_password_hash(
            user["password_hash"],
            password
        )
    ):

        return jsonify({
            "ok": False,
            "message": "Invalid login details or account type."
        }), 401

    session.clear()

    session["user_id"] = user["user_id"]
    session["name"] = user["full_name"]
    session["role"] = user["role"]

    return jsonify({
        "ok": True,
        "message": "Login successful.",
        "redirect": "/dashboard"
    })


# =====================================
# DASHBOARD
# =====================================

@app.get("/dashboard")
def dashboard():

    if not session.get("user_id"):
        return redirect("/pages/patient-login.html")

    role = session.get("role")

    if role == "admin":
        return send_from_directory(
            FRONTEND,
            "admin-dashboard.html"
        )

    if role == "patient":
        return send_from_directory(
            FRONTEND,
            "index.html"
        )

    session.clear()
    return redirect("/")
# =====================================
# HEALTHCARE FACILITIES
# =====================================

@app.get("/api/facilities")
def facilities():

    q = request.args.get("q", "").strip()
    like = f"%{q}%"

    try:

        rows = query(
            """
            SELECT
                facility_id,
                facility_name,
                facility_type,
                description,
                address,
                city,
                state,
                pincode,
                phone,
                email,
                website,
                opening_hours,
                emergency_services,
                image_url
            FROM healthcare_facilities
            WHERE verification_status = 'verified'
            AND (
                %s = ''
                OR facility_name LIKE %s
                OR city LIKE %s
                OR address LIKE %s
            )
            ORDER BY facility_name
            """,
            (q, like, like, like)
        )

        return jsonify({
            "ok": True,
            "facilities": rows
        })

    except Exception:

        app.logger.exception("Facility search failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load facilities."
        }), 503


# =====================================
# MEDICAL CAMPS
# =====================================

@app.get("/api/camps")
def camps():

    try:

        rows = query(
            """
            SELECT
                camp_id,
                camp_name,
                description,
                camp_type,
                camp_date,
                start_time,
                end_time,
                address,
                city,
                state,
                pincode,
                is_free,
                registration_fee,
                contact_phone,
                image_url,
                status
            FROM medical_camps
            WHERE status IN ('upcoming', 'ongoing')
            ORDER BY camp_date
            """
        )

        return app.response_class(
            json.dumps({
                "ok": True,
                "camps": rows
            }, default=str),
            mimetype="application/json"
        )

    except Exception:

        app.logger.exception("Camp listing failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load medical camps."
        }), 503

# =====================================
# DASHBOARD SUMMARY
# =====================================


@app.get("/api/dashboard-summary")
def dashboard_summary():

    try:
        facilities = query(
            """
            SELECT COUNT(*) AS total
            FROM healthcare_facilities
            WHERE verification_status = 'verified'
            """,
            one=True
        )

        camps = query(
            """
            SELECT COUNT(*) AS total
            FROM medical_camps
            WHERE status IN ('upcoming', 'ongoing')
            """,
            one=True
        )

        articles = query(
            """
            SELECT COUNT(*) AS total
            FROM health_articles
            WHERE status = 'published'
            """,
            one=True
        )

        enquiries_count = 0

        if session.get("user_id"):
            enquiries = query(
                """
                SELECT COUNT(*) AS total
                FROM contact_messages
                WHERE user_id = %s
                """,
                (session["user_id"],),
                one=True
            )

            enquiries_count = enquiries["total"]

        return jsonify({
            "ok": True,
            "facilities": facilities["total"],
            "camps": camps["total"],
            "articles": articles["total"] + 22,
            "enquiries": enquiries_count
        })

    except Exception:
        app.logger.exception("Dashboard summary failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load dashboard summary."
        }), 503


# =====================================
# HEALTH AWARENESS EVENTS
# =====================================

@app.get("/api/events")
def events():

    try:

        rows = query(
            """
            SELECT
                event_id,
                event_name,
                description,
                topic,
                event_date,
                start_time,
                end_time,
                venue,
                city,
                state,
                registration_required,
                max_participants,
                contact_phone,
                status
            FROM health_awareness_events
            WHERE status IN ('upcoming', 'ongoing')
            ORDER BY event_date
            """
        )

        return app.response_class(
            json.dumps({
                "ok": True,
                "events": rows
            }, default=str),
            mimetype="application/json"
        )

    except Exception:

        app.logger.exception("Event listing failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load health awareness events."
        }), 503



@app.get("/api/articles")
def articles():
    try:
        language = request.args.get("language", "en").strip().lower()

        if language not in ("en", "hi"):
            language = "en"

        rows = query(
            """
            SELECT
                article_id,
                title,
                slug,
                summary,
                content,
                category_id,
                featured_image,
                language,
                published_at
            FROM health_articles
            WHERE status = 'published'
              AND language = %s
            ORDER BY published_at DESC, article_id DESC
            """,
            (language,)
        )

        return app.response_class(
            json.dumps({
                "ok": True,
                "articles": rows
            }, default=str),
            mimetype="application/json"
        )

    except Exception:
        app.logger.exception("Health articles listing failed")
        return jsonify({
            "ok": False,
            "message": "Unable to load health articles."
        }), 503




# =====================================
# CONTACT FORM
# =====================================


@app.post("/api/contact")
def contact():
    data = request.get_json(silent=True) or request.form

    name = (
        data.get("full_name")
        or data.get("fullName")
        or data.get("name")
        or ""
    ).strip()

    email = (data.get("email") or "").strip().lower()

    phone = (data.get("phone") or "").strip() or None

    subject = (
        data.get("enquiry_type")
        or data.get("enquiryType")
        or data.get("subject")
        or "general"
    ).strip()

    message = (data.get("message") or "").strip()

    if not all([name, email, subject, message]):
        return jsonify({
            "ok": False,
            "message": "Please complete all required fields."
        }), 400

    try:
        query(
            """
            INSERT INTO contact_messages
            (user_id, name, email, phone, subject, message)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                session.get("user_id"),
                name,
                email,
                phone,
                subject,
                message
            ),
            commit=True
        )

        return jsonify({
            "ok": True,
            "message": "Your enquiry has been saved successfully."
        }), 201

    except Exception:
        app.logger.exception("Contact form save failed")

        return jsonify({
            "ok": False,
            "message": "Could not save your enquiry."
        }), 503



# =====================================
# REGISTER FOR MEDICAL CAMP
# =====================================

@app.post("/api/camps/<int:camp_id>/register")
@logged_in
def register_camp(camp_id):

    if session.get("role") != "patient":

        return jsonify({
            "ok": False,
            "message": "Only patients can register for camps."
        }), 403

    try:

        query(
            """
            INSERT INTO camp_registrations
            (camp_id, user_id)
            VALUES (%s, %s)
            """,
            (camp_id, session["user_id"]),
            commit=True
        )

        return jsonify({
            "ok": True,
            "message": "You are registered for this camp."
        }), 201

    except Error as exc:

        if getattr(exc, "errno", None) == 1062:

            return jsonify({
                "ok": False,
                "message": "You are already registered for this camp."
            }), 409

        app.logger.exception("Camp registration failed")

        return jsonify({
            "ok": False,
            "message": "Registration failed. Check camp ID and database."
        }), 400
# =====================================
# ADMIN AUTHENTICATION
# =====================================

from functools import wraps


def admin_required(func):
    @wraps(func)
    def wrapper(*args, **kwargs):

        if not session.get("user_id"):
            return redirect("/pages/admin-login.html")

        if session.get("role") != "admin":
            return jsonify({
                "ok": False,
                "message": "Admin access required."
            }), 403

        return func(*args, **kwargs)

    return wrapper


# =====================================
# ADMIN USERS
# =====================================

@app.get("/admin/users")
@admin_required
def admin_users():

    try:
        users = query(
            """
            SELECT
                user_id,
                full_name,
                email,
                phone,
                role,
                is_active
            FROM users
            ORDER BY user_id DESC
            """
        )

        return jsonify({
            "ok": True,
            "users": users
        })

    except Exception:
        app.logger.exception("Admin users loading failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load users."
        }), 503

@app.get("/admin/users-page")
@admin_required
def admin_users_page():
    return render_template("admin-users.html")


# =====================================
# ADMIN HEALTHCARE FACILITIES
# =====================================

@app.get("/admin/facilities")
@admin_required
def admin_facilities():

    try:
        facilities_data = query(
            """
            SELECT *
            FROM healthcare_facilities
            ORDER BY facility_id DESC
            """
        )

        return jsonify({
            "ok": True,
            "facilities": facilities_data
        })

    except Exception:
        app.logger.exception("Admin facilities loading failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load healthcare facilities."
        }), 503

@app.get("/admin/facilities-page")
@admin_required
def admin_facilities_page():
    return render_template("admin-facilities.html")


# =====================================
# ADMIN MEDICAL CAMPS
# =====================================

@app.get("/admin/camps")
@admin_required
def admin_camps():

    try:
        camps_data = query(
            """
            SELECT *
            FROM medical_camps
            ORDER BY camp_id DESC
            """
        )

        return app.response_class(
            json.dumps({
                "ok": True,
                "camps": camps_data
            }, default=str),
            mimetype="application/json"
        )

    except Exception:
        app.logger.exception("Admin camps loading failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load medical camps."
        }), 503

@app.get("/admin/camps-page")
@admin_required
def admin_camps_page():
    return render_template("admin-camps.html")


# =====================================
# ADMIN HEALTH ARTICLES
# =====================================

@app.get("/admin/articles")
@admin_required
def admin_articles():

    try:
        articles = query(
            """
            SELECT *
            FROM health_articles
            ORDER BY article_id DESC
            """
        )

        return app.response_class(
            json.dumps({
                "ok": True,
                "articles": articles
            }, default=str),
            mimetype="application/json"
        )

    except Exception:
        app.logger.exception("Admin articles loading failed")

        return jsonify({
            "ok": False,
            "message": "Unable to load health articles."
        }), 503

@app.get("/admin/articles-page")
@admin_required
def admin_articles_page():
    return render_template("admin-articles.html")

# =====================================
# LOGOUT
# =====================================

@app.get("/logout")
def logout():

    session.clear()

    return redirect("/")


# =====================================
# 404 HANDLER
# =====================================

@app.errorhandler(404)
def not_found(error):

    if request.path.startswith("/api/"):

        return jsonify({
            "ok": False,
            "message": "API endpoint not found."
        }), 404

    return "Page not found. Please check the URL and frontend files.", 404


# =====================================
# ==========================================
# RUN SERVER + FRONTEND PATH CHECK
# ==========================================

if __name__ == "__main__":

    print("\n========== SEHAT SETU FRONTEND CHECK ==========")
    print("Project directory:", BASE_DIR)
    print("Frontend path:", FRONTEND)
    print("Frontend exists:", os.path.isdir(FRONTEND))
    print(
        "Index exists:",
        os.path.isfile(os.path.join(FRONTEND, "index.html"))
    )
    print("Pages folder exists:", os.path.isdir(PAGES))

    if os.path.isdir(FRONTEND):
        print("Frontend files:", os.listdir(FRONTEND))

    if os.path.isdir(PAGES):
        print("Page files:", os.listdir(PAGES))

    print("================================================\n")

    app.run(
        debug=app.config.get("DEBUG", False),
        host="127.0.0.1",
        port=5000
    )