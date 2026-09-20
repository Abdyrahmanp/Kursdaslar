<?php
// ─────────────────────────────────────────────
//  Byethost MySQL bağlantı ayarları
//  Byethost cPanel → MySQL Databases'den alarsın
// ─────────────────────────────────────────────

define('DB_HOST', 'sql206.byethost4.com');  // Byethost MySQL host (cPanel'den bak)
define('DB_USER', 'b4_42930090_kursdaslar');        // MySQL kullanıcı adın
define('DB_PASS', 'pythonist2008');        // MySQL şifren
define('DB_NAME', 'b4_42930090');   // Veritabanı adın

// CORS — Flutter uygulaması her yerden bağlanabilsin
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

// OPTIONS (preflight) isteğini hemen bitir
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ─── Veritabanı bağlantısı ───────────────────
function getDB(): mysqli {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(['error' => 'DB bağlantı hatası: ' . $conn->connect_error]);
        exit();
    }
    $conn->set_charset('utf8mb4');
    return $conn;
}

// ─── JSON yardımcıları ───────────────────────
function jsonOk(mixed $data): void {
    echo json_encode(['success' => true, 'data' => $data]);
    exit();
}

function jsonError(string $msg, int $code = 400): void {
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg]);
    exit();
}

function getBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}
