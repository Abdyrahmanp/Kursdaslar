<?php
// ─────────────────────────────────────────────
//  chat.php  —  Grup Chat API  (Short Polling)
//  GET  ?after=ID  → ID'den sonraki mesajları getir
//  POST            → yeni mesaj gönder
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db     = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── GET: son mesajları getir ──────────────────
if ($method === 'GET') {
    // Flutter her 2-3 saniyede bir ?after=<son_id> ile sorar
    // Sadece yeni mesajları döner → bant genişliği tasarrufu
    $afterId = isset($_GET['after']) ? (int)$_GET['after'] : 0;
    $limit   = isset($_GET['limit']) ? (int)$_GET['limit'] : 60;
    $limit   = max(1, min(200, $limit));

    if ($afterId > 0) {
        // Sadece yeni mesajlar
        $stmt = $db->prepare(
            'SELECT id, sender_name, sender_role, message, created_at
             FROM chat_messages
             WHERE id > ?
             ORDER BY id ASC
             LIMIT ?'
        );
        $stmt->bind_param('ii', $afterId, $limit);
    } else {
        // İlk yükleme: son N mesaj
        $stmt = $db->prepare(
            'SELECT id, sender_name, sender_role, message, created_at
             FROM chat_messages
             ORDER BY id DESC
             LIMIT ?'
        );
        $stmt->bind_param('i', $limit);
    }

    $stmt->execute();
    $res  = $stmt->get_result();
    $rows = [];
    while ($row = $res->fetch_assoc()) {
        $rows[] = $row;
    }
    // İlk yüklemede ters çevir (en eski üstte)
    if ($afterId === 0) {
        $rows = array_reverse($rows);
    }
    $stmt->close();
    $db->close();
    jsonOk($rows);
}

// ── POST: mesaj gönder ────────────────────────
if ($method === 'POST') {
    $body       = getBody();
    $senderName = trim($body['sender_name'] ?? '');
    $senderRole = trim($body['sender_role'] ?? 'student');
    $message    = trim($body['message']     ?? '');

    if ($senderName === '' || $message === '') {
        jsonError('Ady we habary doldurmaly!');
    }
    if (mb_strlen($message) > 2000) {
        jsonError('Habar gaty uzyn (max 2000 harp)');
    }

    $stmt = $db->prepare(
        'INSERT INTO chat_messages (sender_name, sender_role, message)
         VALUES (?, ?, ?)'
    );
    $stmt->bind_param('sss', $senderName, $senderRole, $message);

    if ($stmt->execute()) {
        $id = $db->insert_id;

        // Eski mesajları temizle (500'den fazla birikmesini önle)
        $db->query('DELETE FROM chat_messages WHERE id NOT IN
                    (SELECT id FROM (SELECT id FROM chat_messages ORDER BY id DESC LIMIT 500) t)');

        $stmt->close();
        $db->close();
        jsonOk(['id' => $id, 'message' => 'Habar ugradyldy!']);
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

jsonError('Rugsat berilmedik usul', 405);
