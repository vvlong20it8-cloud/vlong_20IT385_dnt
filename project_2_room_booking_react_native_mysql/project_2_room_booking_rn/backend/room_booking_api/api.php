<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

const DB_HOST = '127.0.0.1';
const DB_NAME = 'room_booking_db';
const DB_USER = 'root';
const DB_PASS = ''; // Set your XAMPP MySQL password here if needed.

function respond(int $status, array $payload): never {
 http_response_code($status);
 echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
 exit;
}
function db(): PDO {
 static $pdo = null;
 if ($pdo instanceof PDO) return $pdo;
 $pdo = new PDO('mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=utf8mb4', DB_USER, DB_PASS, [
  PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC,
  PDO::ATTR_EMULATE_PREPARES=>false
 ]);
 return $pdo;
}
function body(): array {
 $v = json_decode(file_get_contents('php://input') ?: '{}', true);
 if (!is_array($v)) respond(400, ['success'=>false,'message'=>'Invalid JSON body']);
 return $v;
}
try {
 $pdo = db(); $method = $_SERVER['REQUEST_METHOD']; $action = $_GET['action'] ?? '';
 if ($method === 'GET' && $action === 'rooms') {
  $rows = $pdo->query('SELECT id,name,building,floor,capacity,room_type,equipment_json,color FROM rooms WHERE is_active=1 ORDER BY name')->fetchAll();
  foreach ($rows as &$r) {
   $r['capacity']=(int)$r['capacity']; $r['type']=$r['room_type']; unset($r['room_type']);
   $r['equipment']=json_decode($r['equipment_json'],true) ?: []; unset($r['equipment_json']);
  }
  respond(200,['success'=>true,'data'=>$rows]);
 }
 if ($method === 'GET' && $action === 'bookings') {
  $rows = $pdo->query("SELECT id,room_id,room_name,DATE_FORMAT(booking_date,'%Y-%m-%d') booking_date,TIME_FORMAT(start_time,'%H:%i') start_time,TIME_FORMAT(end_time,'%H:%i') end_time,purpose,booked_by,status FROM bookings WHERE status <> 'Cancelled' ORDER BY booking_date,start_time")->fetchAll();
  foreach ($rows as &$r) {
   $r['id']='B'.$r['id']; $r['roomId']=$r['room_id']; $r['roomName']=$r['room_name'];
   $r['date']=$r['booking_date']; $r['start']=$r['start_time']; $r['end']=$r['end_time']; $r['bookedBy']=$r['booked_by'];
   unset($r['room_id'],$r['room_name'],$r['booking_date'],$r['start_time'],$r['end_time'],$r['booked_by']);
  }
  respond(200,['success'=>true,'data'=>$rows]);
 }
 if ($method === 'POST' && ($action === 'bookings' || $action === '')) {
  $d=body();
  foreach (['roomId','date','start','end','purpose','bookedBy'] as $k) {
   if (!isset($d[$k]) || trim((string)$d[$k])==='') respond(422,['success'=>false,'message'=>"Missing field: $k"]);
  }
  if ($d['end'] <= $d['start']) respond(422,['success'=>false,'message'=>'End time must be later than start time']);
  $pdo->beginTransaction();
  $s=$pdo->prepare('SELECT id,name FROM rooms WHERE id=? AND is_active=1 FOR UPDATE'); $s->execute([$d['roomId']]); $room=$s->fetch();
  if (!$room) { $pdo->rollBack(); respond(404,['success'=>false,'message'=>'Room not found']); }
  $s=$pdo->prepare("SELECT id FROM bookings WHERE room_id=? AND booking_date=? AND status <> 'Cancelled' AND start_time < ? AND end_time > ? LIMIT 1");
  $s->execute([$d['roomId'],$d['date'],$d['end'].':00',$d['start'].':00']);
  if ($s->fetch()) { $pdo->rollBack(); respond(409,['success'=>false,'message'=>'This room is already booked during that time']); }
  $s=$pdo->prepare("INSERT INTO bookings(room_id,room_name,booking_date,start_time,end_time,purpose,booked_by,status) VALUES(?,?,?,?,?,?,?,'Confirmed')");
  $s->execute([$room['id'],$room['name'],$d['date'],$d['start'].':00',$d['end'].':00',trim($d['purpose']),trim($d['bookedBy'])]);
  $id='B'.$pdo->lastInsertId(); $pdo->commit();
  respond(201,['success'=>true,'data'=>['id'=>$id,'roomId'=>$room['id'],'roomName'=>$room['name'],'date'=>$d['date'],'start'=>$d['start'],'end'=>$d['end'],'purpose'=>trim($d['purpose']),'bookedBy'=>trim($d['bookedBy']),'status'=>'Confirmed']]);
 }
 if ($method === 'DELETE' && isset($_GET['id'])) {
  $id=preg_replace('/^B/','',(string)$_GET['id']);
  if (!ctype_digit($id)) respond(400,['success'=>false,'message'=>'Invalid booking id']);
  $s=$pdo->prepare("UPDATE bookings SET status='Cancelled' WHERE id=?"); $s->execute([(int)$id]);
  if (!$s->rowCount()) respond(404,['success'=>false,'message'=>'Booking not found']);
  respond(200,['success'=>true,'message'=>'Booking cancelled']);
 }
 respond(404,['success'=>false,'message'=>'Unknown endpoint']);
} catch (Throwable $e) {
 if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) $pdo->rollBack();
 error_log((string)$e);
 respond(500,['success'=>false,'message'=>'Server/database error. Check XAMPP and PHP error log.']);
}
