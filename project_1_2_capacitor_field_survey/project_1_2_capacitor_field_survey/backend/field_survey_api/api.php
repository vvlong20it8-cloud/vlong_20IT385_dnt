<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}
require_once __DIR__ . '/db.php';

function respond(int $status, array $payload): never {
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}
function requestData(): array {
    $data = json_decode(file_get_contents('php://input') ?: '{}', true);
    if (!is_array($data)) respond(400, ['success' => false, 'message' => 'Invalid JSON body.']);
    return $data;
}
function validateSurvey(array $data): array {
    $location = trim((string)($data['location'] ?? ''));
    $surveyor = trim((string)($data['surveyor'] ?? ''));
    $date = trim((string)($data['date'] ?? $data['survey_date'] ?? ''));
    $status = trim((string)($data['status'] ?? 'Planned'));
    $notes = trim((string)($data['notes'] ?? ''));
    if ($location === '' || $surveyor === '' || $date === '') {
        respond(422, ['success' => false, 'message' => 'Location, surveyor, and date are required.']);
    }
    $parsed = DateTime::createFromFormat('!Y-m-d', $date);
    if (!$parsed || $parsed->format('Y-m-d') !== $date) {
        respond(422, ['success' => false, 'message' => 'Date must use YYYY-MM-DD format.']);
    }
    if (!in_array($status, ['Planned', 'In progress', 'Completed'], true)) {
        respond(422, ['success' => false, 'message' => 'Invalid status.']);
    }
    return [
        'location' => $location,
        'surveyor' => $surveyor,
        'survey_date' => $date,
        'status' => $status,
        'notes' => $notes,
    ];
}
function formatSurvey(array $row): array {
    return [
        'id' => (int)$row['id'],
        'location' => $row['location'],
        'surveyor' => $row['surveyor'],
        'date' => $row['survey_date'],
        'status' => $row['status'],
        'notes' => $row['notes'] ?? '',
        'createdAt' => $row['created_at'],
    ];
}
$method = $_SERVER['REQUEST_METHOD'];
try {
    if ($method === 'GET') {
        if (isset($_GET['id'])) {
            $stmt = $pdo->prepare('SELECT * FROM surveys WHERE id = ?');
            $stmt->execute([(int)$_GET['id']]);
            $row = $stmt->fetch();
            if (!$row) respond(404, ['success' => false, 'message' => 'Survey not found.']);
            respond(200, ['success' => true, 'data' => formatSurvey($row)]);
        }
        $rows = $pdo->query('SELECT * FROM surveys ORDER BY created_at DESC, id DESC')->fetchAll();
        respond(200, ['success' => true, 'data' => array_map('formatSurvey', $rows)]);
    }
    if ($method === 'POST') {
        $data = validateSurvey(requestData());
        $stmt = $pdo->prepare(
            'INSERT INTO surveys (location, surveyor, survey_date, status, notes)
             VALUES (:location, :surveyor, :survey_date, :status, :notes)'
        );
        $stmt->execute($data);
        $stmt = $pdo->prepare('SELECT * FROM surveys WHERE id = ?');
        $stmt->execute([(int)$pdo->lastInsertId()]);
        respond(201, ['success' => true, 'data' => formatSurvey($stmt->fetch())]);
    }
    if ($method === 'PUT') {
        $id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
        if (!$id || $id < 1) respond(400, ['success' => false, 'message' => 'A valid id query parameter is required.']);
        $data = validateSurvey(requestData());
        $data['id'] = $id;
        $stmt = $pdo->prepare(
            'UPDATE surveys SET location=:location, surveyor=:surveyor,
             survey_date=:survey_date, status=:status, notes=:notes WHERE id=:id'
        );
        $stmt->execute($data);
        $stmt = $pdo->prepare('SELECT * FROM surveys WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();
        if (!$row) respond(404, ['success' => false, 'message' => 'Survey not found.']);
        respond(200, ['success' => true, 'data' => formatSurvey($row)]);
    }
    if ($method === 'DELETE') {
        $id = filter_var($_GET['id'] ?? null, FILTER_VALIDATE_INT);
        if (!$id || $id < 1) respond(400, ['success' => false, 'message' => 'A valid id query parameter is required.']);
        $stmt = $pdo->prepare('DELETE FROM surveys WHERE id = ?');
        $stmt->execute([$id]);
        if (!$stmt->rowCount()) respond(404, ['success' => false, 'message' => 'Survey not found.']);
        respond(200, ['success' => true, 'message' => 'Survey deleted.']);
    }
    header('Allow: GET, POST, PUT, DELETE, OPTIONS');
    respond(405, ['success' => false, 'message' => 'Method not allowed.']);
} catch (Throwable $e) {
    respond(500, ['success' => false, 'message' => 'Server error. Check PHP/MySQL configuration and logs.']);
}
