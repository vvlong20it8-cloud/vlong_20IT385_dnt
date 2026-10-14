# Project 3 — Flutter Expense Manager with Receipt OCR

A starter mini-project for **Flutter + PHP API + MySQL**, with:
- Add, edit, delete and list income/expense transactions
- Income, expense and balance summary cards
- Filter by income/expense
- Receipt text extraction using Google ML Kit on Android/iOS
- Web/Chrome UI fallback: users can enter or paste receipt text manually (Google ML Kit's native plugin is not supported on Flutter Web)

## 1. Database (XAMPP)
1. Start **Apache** and **MySQL** in XAMPP.
2. Open `http://localhost/phpmyadmin`.
3. Choose **Import**, select `database/expense_manager_db.sql`, and import it.
4. Backend DB defaults are in `backend/db.php`: database `expense_manager_db`, user `root`, empty password. Update if your MySQL credentials differ.

## 2. Install the PHP API
Copy the `backend` folder to:

`C:\xampp\htdocs\expense_manager_api`

The file should then be available at:

`http://localhost/expense_manager_api/api.php?action=transactions`

Check API summary:

`http://localhost/expense_manager_api/api.php?action=summary`

Expected output is JSON. If it says database connection failed, check XAMPP and `backend/db.php`.

## 3. Configure Flutter API URL
Open `lib/services/api_service.dart` and set `apiBaseUrl`:
- Chrome on the same PC: `http://localhost/expense_manager_api/api.php`
- Android emulator: `http://10.0.2.2/expense_manager_api/api.php`
- Physical phone: use your PC's LAN IP, e.g. `http://192.168.1.10/expense_manager_api/api.php`; phone and PC must share a network and Windows Firewall must allow Apache.

## 4. Run on Chrome
Install Flutter SDK and make sure `flutter --version` works. In the project root:

```bash
flutter pub get
flutter run -d chrome
```

The UI and CRUD work on web when the PHP API is reachable. Google ML Kit OCR is a native mobile plugin; on Chrome, the Scan Receipt button explains the limitation and receipt text can be entered manually in Notes.

## 5. Run on Android for OCR
1. Connect an Android device or start an Android emulator.
2. Set the API URL to the Android emulator/phone URL described above.
3. Run:

```bash
flutter pub get
flutter run
```

The app uses image picker to select a receipt image and Google ML Kit Text Recognition to extract text. Review OCR output before saving because OCR can misread amounts and characters.

## Features / limitations
- This starter does not include authentication or user-specific records.
- Summary totals are calculated from all transactions; monthly charts can be added as an extension.
- Do not expose this demo API directly to the public internet without authentication, authorization, rate limiting and deployment hardening.
