# Project 2 — RoomBook (React Native + MySQL)

Includes a React Native/Expo app, PHP API and MySQL schema for a room/lab booking demo.

## Database and API setup (XAMPP)
1. Start Apache and MySQL.
2. Copy `backend/room_booking_api` to `C:\\xampp\\htdocs\\room_booking_api`.
3. Open `http://localhost/phpmyadmin`, choose Import, and import `database/room_booking_db.sql`.
4. Test `http://localhost/room_booking_api/api.php?action=rooms` in Chrome. It should return JSON.
5. Test `http://localhost/room_booking_api/api.php?action=bookings`.

If MySQL root has a password, update `DB_PASS` in `api.php`.

## Run on Chrome
Open the folder containing `package.json` in VS Code:
```powershell
npm.cmd install
npx.cmd expo start --web
```
Open the URL printed by Expo. The default API URL is `http://localhost/room_booking_api/api.php`, intended for Chrome on the same PC running XAMPP.

## Features
- Search/filter rooms, date/time selection, create and cancel bookings
- MySQL persists rooms and bookings
- PHP API checks overlapping bookings on the server

## Important
This is not connected to a real institutional Robin or LibCal API yet. That requires official API documentation and institution credentials. For a physical phone, change `API_BASE_URL` in `App.tsx` to your computer's LAN IP; for Android emulator, `10.0.2.2` is commonly used instead of localhost. This demo has no authentication and should not be exposed publicly as-is.
