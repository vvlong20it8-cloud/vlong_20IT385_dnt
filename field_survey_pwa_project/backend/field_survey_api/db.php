<?php
declare(strict_types=1);

/*
 * Local XAMPP defaults:
 * host=127.0.0.1, database=field_survey_db, user=root, password empty.
 * If your MySQL root account has a password, set it below.
 */
$host = '127.0.0.1';
$dbname = 'field_survey_db';
$username = 'root';
$password = '';

$dsn = "mysql:host={$host};dbname={$dbname};charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed. Check db.php and make sure MySQL is running.',
    ]);
    exit;
}
