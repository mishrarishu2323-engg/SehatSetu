# SehatSetu — Flask + MySQL integration

This project keeps your existing HTML/CSS/JS frontend and adds a Flask backend connected to the `sehatsetu_db` schema.

## 1. Requirements
- Python 3.10+
- MySQL Server 8.x and MySQL Workbench (or mysql command line)
- VS Code (recommended)

## 2. Import database schema
1. Open MySQL Workbench and connect to your local server.
2. Open `schema.sql`.
3. Execute the whole script. It creates the `sehatsetu_db` database and its 16 tables.
4. This dump contains table definitions, not sample records. The facilities/camps lists will be empty until records are added.

## 3. Configure Python
Open this project folder in VS Code terminal and run:

```bash
python -m venv .venv
```
Windows PowerShell:
```powershell
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```
If using Command Prompt instead of PowerShell, activate with `.venv\Scripts\activate.bat`.

Open `.env` and set `DB_PASSWORD` to your actual MySQL password. Replace `FLASK_SECRET_KEY` with a long random secret. Never share `.env`.

## 4. Create an admin login
After schema import and `.env` configuration, run:
```bash
python create_admin.py
```
Enter the admin name, email, and password when prompted. The password is stored as a hash.

## 5. Start the website
```bash
python app.py
```
Open `http://127.0.0.1:5000` in Chrome. Keep the terminal open while testing.

## Included backend endpoints
- `GET /api/health` — test database connection
- `POST /api/register` — patient registration API (JSON: name, email, optional phone, password)
- `POST /api/login` — patient login API
- `POST /api/login?role=admin` — admin login API
- `POST /api/contact` — saves contact enquiries
- `GET /api/facilities`, `GET /api/camps`, `GET /api/events` — data APIs
- `POST /api/camps/<camp_id>/register` — authenticated camp registration

## Notes
- Do not expose database passwords or `.env` when sharing the ZIP.
- This is a development setup, not yet a production deployment. Before public deployment, disable debug mode, configure HTTPS, rotate the secret key, and add CSRF protection/rate limits.
- The current frontend has static page content; this first integration wires login/contact forms and provides data APIs. Populating every visual card from live database data and building a full admin dashboard are follow-up tasks.
