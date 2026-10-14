<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }
require_once __DIR__ . '/db.php';
function respond(array $payload, int $status = 200): never {
    http_response_code($status); echo json_encode($payload, JSON_UNESCAPED_UNICODE); exit;
}
function body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw ?: '{}', true);
    return is_array($data) ? $data : [];
}
$action = $_GET['action'] ?? '';
try {
    if ($action === 'transactions' && $_SERVER['REQUEST_METHOD'] === 'GET') {
        $stmt = $pdo->query('SELECT id, title, amount, type, category, transaction_date, notes, created_at FROM transactions ORDER BY transaction_date DESC, id DESC');
        respond(['success' => true, 'data' => $stmt->fetchAll()]);
    }
    if ($action === 'summary' && $_SERVER['REQUEST_METHOD'] === 'GET') {
        $stmt = $pdo->query("SELECT COALESCE(SUM(CASE WHEN type='income' THEN amount ELSE 0 END),0) AS income, COALESCE(SUM(CASE WHEN type='expense' THEN amount ELSE 0 END),0) AS expense FROM transactions");
        $row = $stmt->fetch(); $row['balance'] = (float)$row['income'] - (float)$row['expense'];
        respond(['success' => true] + $row);
    }
    if ($action === 'save' && $_SERVER['REQUEST_METHOD'] === 'POST') {
        $d = body();
        $id = isset($d['id']) ? (int)$d['id'] : 0;
        $title = trim((string)($d['title'] ?? ''));
        $amount = filter_var($d['amount'] ?? null, FILTER_VALIDATE_FLOAT);
        $type = (string)($d['type'] ?? '');
        $category = trim((string)($d['category'] ?? 'Other'));
        $date = (string)($d['transaction_date'] ?? '');
        $notes = trim((string)($d['notes'] ?? ''));
        if ($title === '' || $amount === false || $amount <= 0 || !in_array($type, ['income','expense'], true) || !preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
            respond(['success' => false, 'message' => 'Invalid title, amount, type or date.'], 422);
        }
        if ($id > 0) {
            $stmt = $pdo->prepare('UPDATE transactions SET title=?, amount=?, type=?, category=?, transaction_date=?, notes=? WHERE id=?');
            $stmt->execute([$title, $amount, $type, $category, $date, $notes, $id]);
            respond(['success' => true, 'message' => 'Transaction updated.']);
        }
        $stmt = $pdo->prepare('INSERT INTO transactions (title, amount, type, category, transaction_date, notes) VALUES (?,?,?,?,?,?)');
        $stmt->execute([$title, $amount, $type, $category, $date, $notes]);
        respond(['success' => true, 'id' => (int)$pdo->lastInsertId(), 'message' => 'Transaction created.'], 201);
    }
    if ($action === 'delete' && $_SERVER['REQUEST_METHOD'] === 'DELETE') {
        $d = body(); $id = (int)($d['id'] ?? 0);
        if ($id < 1) respond(['success' => false, 'message' => 'A valid transaction id is required.'], 422);
        $stmt = $pdo->prepare('DELETE FROM transactions WHERE id=?'); $stmt->execute([$id]);
        respond(['success' => true, 'message' => 'Transaction deleted.']);
    }
    respond(['success' => false, 'message' => 'Unknown action or unsupported HTTP method.'], 404);
} catch (Throwable $e) {
    respond(['success' => false, 'message' => 'Server error. Check the PHP/Apache error log.'], 500);
}
