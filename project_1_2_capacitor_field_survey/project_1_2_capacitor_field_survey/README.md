# Project 1.2 — Capacitor Field Survey

This project uses HTML, CSS, JavaScript, Vite and Capacitor. It is intentionally different from Project 1.1's Flutter implementation and follows the technology named in the assignment form: **Capacitor - Field Survey**.

## Features
- Responsive Field Survey dashboard
- Total, In progress and Completed statistics
- Create, edit and delete survey records
- Search by location, surveyor and notes
- Filter by survey status
- PHP REST API backed by MySQL
- Capacitor configuration for Android packaging

## A. Run on Chrome first

Requirements: Node.js/npm and XAMPP.

1. Start **Apache** and **MySQL** in XAMPP.
2. Import `database/field_survey_db.sql` using `http://localhost/phpmyadmin` → **Import**.
3. Copy `backend/field_survey_api` into `C:\xampp\htdocs\field_survey_api`.
4. Check `db.php`; default XAMPP credentials are often `root` with an empty password, but adjust if yours differ.
5. Open `http://localhost/field_survey_api/api.php`. It should return JSON such as `{"success":true,"data":[]}`.
6. Open this project folder in VS Code, the folder containing `package.json`.
7. In Terminal run:

```powershell
npm install
npm run dev
```

8. Open the local URL Vite prints, typically `http://localhost:5173`.

## B. Build the Capacitor Android app (optional)

After the Chrome/web version works:

```powershell
npm run build
npx cap add android
npx cap sync android
npx cap open android
```

Open the Android project in Android Studio and run it on an emulator/device. The API code selects `http://10.0.2.2/field_survey_api/api.php` on Android Emulator, which routes to the host PC. For a physical phone, replace `10.0.2.2` in `src/main.js` with your PC's LAN IP and ensure both devices share the same network. Depending on Android's cleartext network policy and your Capacitor/Android configuration, HTTP API access may need HTTPS or an explicit development-only cleartext allowance.

## C. Verify database persistence

Create a survey in the app, then open phpMyAdmin → `field_survey_db` → `surveys` → Browse and refresh. The new record should be stored in MySQL.

## Important
The source was generated as a starter project based on the assignment title and earlier discussion. Run it in the user's environment to confirm the installed Node/Java/Android SDK versions and adjust if necessary. It has not been checked against a detailed instructor rubric.
