# Project 1.1 — Field Survey PWA (Flutter + PHP + MySQL)

## Architecture

Flutter Web/PWA → PHP REST API → MySQL (XAMPP).

Flutter never connects directly to MySQL. The PHP API is the only layer that uses database credentials.

## Setup on Windows

### 1. Import the database
- Start XAMPP Control Panel.
- Start **Apache** and **MySQL**.
- Open `http://localhost/phpmyadmin`.
- Choose **Import** and import `database/field_survey_db.sql`.

### 2. Install the PHP API
- Copy `backend/field_survey_api` to `C:\xampp\htdocs\field_survey_api`.
- Open `C:\xampp\htdocs\field_survey_api\db.php`.
- Default XAMPP settings: MySQL user `root`, blank password. Change these values if your setup differs.
- Open `http://localhost/field_survey_api/api.php`. It should return JSON with `success: true`.

### 3. Run Flutter
Open this project folder in VS Code. In Terminal:

```powershell
flutter create . --platforms=web,android,windows
flutter pub get
flutter run -d chrome
```

If Flutter reports that Chrome is unavailable, run `flutter devices` and check the web setup.

### 4. Verify database connection
- Keep Apache and MySQL running.
- Create a survey in the Flutter UI.
- Open `http://localhost/phpmyadmin`, select `field_survey_db` → `surveys` → **Browse**.
- The new row should be present in MySQL.

## API endpoints

Base URL: `http://localhost/field_survey_api/api.php`

- `GET /api.php` — list surveys
- `GET /api.php?id=1` — get one survey
- `POST /api.php` — create survey
- `PUT /api.php?id=1` — update survey
- `DELETE /api.php?id=1` — delete survey

POST/PUT JSON example:

```json
{
  "location": "District 1, Ho Chi Minh City",
  "surveyor": "Student Name",
  "date": "2026-10-14",
  "status": "Planned",
  "notes": "Example field observation"
}
```

## Troubleshooting
- **Connection refused / API error:** start Apache and MySQL in XAMPP.
- **404 on API URL:** confirm folder path is `C:\xampp\htdocs\field_survey_api\api.php`.
- **Database connection failed:** check database name, MySQL username/password in `db.php`.
- **CORS error:** use the API from the same localhost origin, check browser console, and keep the OPTIONS handler in `api.php`.
- **HTTP blocked as mixed content after deployment:** deploy the API over HTTPS and update `apiBaseUrl` to the HTTPS endpoint.
- The included CORS policy is permissive for local development. Restrict it to your actual frontend origin before public deployment.
