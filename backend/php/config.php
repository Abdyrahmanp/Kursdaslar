<?php
// ─────────────────────────────────────────────
//  Topar-115  —  Backend Config (Zero-Failure Architecture)
// ─────────────────────────────────────────────

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

@ini_set('display_errors', '0');
@error_reporting(E_ALL);

// PHP fatal exception handler: never let unhandled exception become HTTP 500
set_exception_handler(function(\Throwable $e) {
    http_response_code(200);
    echo json_encode(['success' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
    exit();
});

if (function_exists('mysqli_report')) {
    @mysqli_report(MYSQLI_REPORT_OFF);
}

// ── MySQL Connection with Candidate Combinations & Fallback ──
function getDB(): ?mysqli {
    static $cachedConn = null;
    static $attempted = false;

    if ($attempted) return $cachedConn;
    $attempted = true;

    $candidates = [
        // Byethost: DB_NAME has suffix, DB_USER is often prefix
        ['host' => 'sql206.byethost4.com', 'user' => 'b4_42930090', 'pass' => 'pythonist2008', 'db' => 'b4_42930090_kursdaslar'],
        ['host' => 'sql206.byethost4.com', 'user' => 'b4_42930090_kursdaslar', 'pass' => 'pythonist2008', 'db' => 'b4_42930090_kursdaslar'],
        ['host' => 'sql206.byethost4.com', 'user' => 'b4_42930090', 'pass' => 'pythonist2008', 'db' => 'b4_42930090'],
        ['host' => 'sql206.byethost4.com', 'user' => 'b4_42930090_kursdaslar', 'pass' => 'pythonist2008', 'db' => 'b4_42930090'],
        ['host' => 'localhost', 'user' => 'b4_42930090', 'pass' => 'pythonist2008', 'db' => 'b4_42930090_kursdaslar'],
        ['host' => 'localhost', 'user' => 'b4_42930090_kursdaslar', 'pass' => 'pythonist2008', 'db' => 'b4_42930090_kursdaslar'],
        ['host' => '127.0.0.1', 'user' => 'b4_42930090', 'pass' => 'pythonist2008', 'db' => 'b4_42930090_kursdaslar'],
    ];

    foreach ($candidates as $c) {
        try {
            $conn = @new mysqli($c['host'], $c['user'], $c['pass'], $c['db']);
            if ($conn && !$conn->connect_error) {
                @$conn->set_charset('utf8mb4');
                ensureTables($conn);
                $cachedConn = $conn;
                return $conn;
            }
        } catch (\Throwable $e) {
            // try next candidate
        }
    }

    return null;
}

function ensureTables(mysqli $conn): void {
    // Announcements
    @$conn->query("CREATE TABLE IF NOT EXISTS announcements (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        sender_name VARCHAR(100) NOT NULL DEFAULT 'Admin',
        sender_role VARCHAR(30) NOT NULL DEFAULT 'admin',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // Chat messages (with reply fields)
    @$conn->query("CREATE TABLE IF NOT EXISTS chat_messages (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        sender_name VARCHAR(100) NOT NULL,
        sender_role VARCHAR(30) NOT NULL DEFAULT 'student',
        message TEXT NOT NULL,
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        reply_to_id INT NULL DEFAULT NULL,
        reply_to_name VARCHAR(100) NULL DEFAULT NULL,
        reply_to_text VARCHAR(255) NULL DEFAULT NULL,
        INDEX idx_id_desc (id)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    @$conn->query("ALTER TABLE chat_messages ADD COLUMN reply_to_id INT NULL DEFAULT NULL");
    @$conn->query("ALTER TABLE chat_messages ADD COLUMN reply_to_name VARCHAR(100) NULL DEFAULT NULL");
    @$conn->query("ALTER TABLE chat_messages ADD COLUMN reply_to_text VARCHAR(255) NULL DEFAULT NULL");

    // Subjects
    @$conn->query("CREATE TABLE IF NOT EXISTS subjects (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        code VARCHAR(20) NOT NULL,
        name VARCHAR(150) NOT NULL,
        teacher VARCHAR(100) NOT NULL DEFAULT ''
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // Topics
    @$conn->query("CREATE TABLE IF NOT EXISTS topics (
        id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        subject_id INT UNSIGNED NOT NULL,
        title VARCHAR(255) NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        homework TEXT NOT NULL DEFAULT '',
        created_by VARCHAR(100) NOT NULL DEFAULT 'Starşy',
        created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        INDEX idx_subject (subject_id),
        INDEX idx_created (created_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // Default subjects if table is empty
    $res = @$conn->query("SELECT COUNT(*) AS cnt FROM subjects");
    if ($res && ($row = $res->fetch_assoc()) && (int)$row['cnt'] === 0) {
        @$conn->query("INSERT INTO subjects (code, name, teacher) VALUES
            ('ENG', 'Iňlis dili', ''),
            ('JPN', 'Ýapon dili', ''),
            ('TKM', 'Türkmen dili', ''),
            ('INF', 'Informatika', ''),
            ('MAT', 'Matematika', ''),
            ('FIZ', 'Fizika', '')");
    }
}

// ── JSON Response Helpers ────────────────────
function jsonOk(mixed $data): void {
    http_response_code(200);
    echo json_encode(['success' => true, 'data' => $data], JSON_UNESCAPED_UNICODE);
    exit();
}

function jsonError(string $msg, int $code = 400): void {
    http_response_code($code);
    echo json_encode(['success' => false, 'error' => $msg], JSON_UNESCAPED_UNICODE);
    exit();
}

function getBody(): array {
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}

// ── File-based Fallback Storage ──────────────
function loadJsonFile(string $filename, array $default = []): array {
    $path = __DIR__ . '/' . $filename;
    if (!file_exists($path)) {
        return $default;
    }
    $raw = @file_get_contents($path);
    if (!$raw) return $default;
    $data = @json_decode($raw, true);
    return is_array($data) ? $data : $default;
}

function saveJsonFile(string $filename, array $data): bool {
    $path = __DIR__ . '/' . $filename;
    return (bool)@file_put_contents($path, json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT), LOCK_EX);
}
