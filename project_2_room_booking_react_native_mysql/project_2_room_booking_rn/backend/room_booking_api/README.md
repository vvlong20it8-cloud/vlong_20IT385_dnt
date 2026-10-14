# PHP API setup

1. Copy `room_booking_api` into `C:\\xampp\\htdocs\\room_booking_api`.
2. Start Apache and MySQL in XAMPP.
3. Import `database/room_booking_db.sql` through phpMyAdmin.
4. Test `http://localhost/room_booking_api/api.php?action=rooms`.
5. If root has a password, set `DB_PASS` in `api.php`.

Endpoints: GET `?action=rooms`, GET `?action=bookings`, POST `?action=bookings`, DELETE `?id=B1`.
