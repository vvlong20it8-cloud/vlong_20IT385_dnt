# PHP REST API for Field Survey

1. Copy the `field_survey_api` folder into `C:\xampp\htdocs\`.
2. Import `database/field_survey_db.sql` into phpMyAdmin.
3. Start Apache and MySQL in XAMPP.
4. Check `db.php`; default XAMPP credentials are `root` with an empty password.
5. Open `http://localhost/field_survey_api/api.php` in a browser. Expected JSON:
   `{"success":true,"data":[]}` when the table is empty.

## Endpoints

- `GET api.php` — list surveys
- `GET api.php?id=1` — get one survey
- `POST api.php` — create a survey (JSON body)
- `PUT api.php?id=1` — update a survey (JSON body)
- `DELETE api.php?id=1` — delete a survey

For production, replace permissive CORS with the exact deployed frontend origin, use a dedicated database user, enable HTTPS, and do not expose PHP/database credentials in Flutter.
