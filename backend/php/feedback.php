<?php
// ─────────────────────────────────────────────
//  feedback.php  —  Habarlaşmak we Teklip API
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db       = getDB();
$method   = $_SERVER['REQUEST_METHOD'];
$jsonFile = 'data_feedback.json';
$toEmail  = 'abdyrahmandevoloper@gmail.com';

// Ensure table exists if DB is connected
if ($db) {
    try {
        @$db->query("CREATE TABLE IF NOT EXISTS feedbacks (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            sender_name VARCHAR(100) NOT NULL,
            sender_phone VARCHAR(50) NOT NULL DEFAULT '',
            sender_role VARCHAR(30) NOT NULL DEFAULT 'student',
            subject VARCHAR(150) NOT NULL DEFAULT 'Teklip',
            message TEXT NOT NULL,
            created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_created (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");
    } catch (\Throwable $e) {}
}

// ── GET: Ýazylan hatlary getir (developer gözden geçirmegi üçin) ────────
if ($method === 'GET') {
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $limit = max(1, min(100, $limit));

    if ($db) {
        try {
            $stmt = $db->prepare(
                'SELECT id, sender_name, sender_phone, sender_role, subject, message, created_at
                 FROM feedbacks
                 ORDER BY created_at DESC
                 LIMIT ?'
            );
            if ($stmt) {
                $stmt->bind_param('i', $limit);
                $stmt->execute();
                $res  = $stmt->get_result();
                $rows = [];
                while ($row = $res->fetch_assoc()) {
                    $rows[] = $row;
                }
                $stmt->close();
                jsonOk($rows);
            }
        } catch (\Throwable $e) {}
    }

    // JSON file fallback
    $rows = loadJsonFile($jsonFile, []);
    jsonOk(array_slice($rows, 0, $limit));
}

// ── POST: Täze hat/teklip iber ────────────────────────────────────────
if ($method === 'POST') {
    $body        = getBody();
    $senderName  = trim($body['name']    ?? 'Näbelli talyp');
    $senderPhone = trim($body['phone']   ?? '');
    $senderRole  = trim($body['role']    ?? 'student');
    $subject     = trim($body['subject'] ?? 'Teklip');
    $message     = trim($body['message'] ?? '');

    if ($message === '') {
        jsonError('Hatyň mazmuny boş bolup bilmeýär!');
    }

    $createdAt = date('Y-m-d H:i:s');
    $savedId   = null;

    // 1. MySQL-de sakla
    if ($db) {
        try {
            $stmt = $db->prepare(
                'INSERT INTO feedbacks (sender_name, sender_phone, sender_role, subject, message, created_at)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            if ($stmt) {
                $stmt->bind_param('ssssss', $senderName, $senderPhone, $senderRole, $subject, $message, $createdAt);
                if ($stmt->execute()) {
                    $savedId = $db->insert_id;
                    $stmt->close();
                }
            }
        } catch (\Throwable $e) {}
    }

    // 2. data_feedback.json faýlynda hem hemişelik sakla (Zero-Loss)
    $rows = loadJsonFile($jsonFile, []);
    $newId = $savedId ?? (count($rows) > 0 ? (max(array_column($rows, 'id')) + 1) : 1);
    $newItem = [
        'id'           => $newId,
        'sender_name'  => $senderName,
        'sender_phone' => $senderPhone,
        'sender_role'  => $senderRole,
        'subject'      => $subject,
        'message'      => $message,
        'created_at'   => $createdAt,
    ];
    array_unshift($rows, $newItem);
    saveJsonFile($jsonFile, $rows);

    // 3. E-poçta ugrat (abdyrahmandevoloper@gmail.com)
    try {
        $encodedSubject = '=?UTF-8?B?' . base64_encode("[Kursdaşlar] Habar: $subject ($senderName)") . '?=';
        $emailContent = "Topar-115 / Kursdaşlar programmasyndan täze hat:\n\n"
                      . "Ugradyjy: $senderName\n"
                      . "Telefon: $senderPhone\n"
                      . "Wezipesi: $senderRole\n"
                      . "Mowzuk: $subject\n"
                      . "Wagty: $createdAt\n"
                      . "--------------------------------------------------\n"
                      . "Hatyň mazmuny:\n$message\n"
                      . "--------------------------------------------------\n";

        $headers = "From: Kursdaşlar <noreply@kursdaslar.byethost4.com>\r\n"
                 . "Reply-To: noreply@kursdaslar.byethost4.com\r\n"
                 . "MIME-Version: 1.0\r\n"
                 . "Content-Type: text/plain; charset=UTF-8\r\n"
                 . "Content-Transfer-Encoding: 8bit\r\n"
                 . "X-Mailer: PHP/" . phpversion();

        @mail($toEmail, $encodedSubject, $emailContent, $headers);
    } catch (\Throwable $e) {
        // Mail hatasy bolsa hem ulanyja bildirmeýäris, sebäbi maglumat DB we JSON-da saklandy
    }

    jsonOk([
        'id'      => $newId,
        'message' => 'Hatyňyz üstünlikli ugradyldy! Sag boluň.',
    ]);
}

jsonError('Rugsat berilmedik usul', 405);
