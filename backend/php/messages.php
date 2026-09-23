<?php
// ─────────────────────────────────────────────
//  messages.php  —  Grup Chat / Hatlar API (Short Polling)
//  GET  ?after=ID  → ID'den sonraki mesajları getir
//  POST            → yeni mesaj gönder (reply_to_* desteği ile)
//  DELETE ?id=ID   → mesajı sil
//  PUT             → mesajı düzenle
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db     = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// Sütunların varlığından emin ol (Reply özelliği için otomatik göç)
@$db->query("ALTER TABLE chat_messages ADD COLUMN reply_to_id INT NULL DEFAULT NULL");
@$db->query("ALTER TABLE chat_messages ADD COLUMN reply_to_name VARCHAR(100) NULL DEFAULT NULL");
@$db->query("ALTER TABLE chat_messages ADD COLUMN reply_to_text VARCHAR(255) NULL DEFAULT NULL");

// ── GET: son mesajları getir ──────────────────
if ($method === 'GET') {
    $afterId = isset($_GET['after']) ? (int)$_GET['after'] : 0;
    $limit   = isset($_GET['limit']) ? (int)$_GET['limit'] : 60;
    $limit   = max(1, min(200, $limit));

    if ($afterId > 0) {
        $stmt = $db->prepare(
            'SELECT id, sender_name, sender_role, message, created_at,
                    reply_to_id, reply_to_name, reply_to_text
             FROM chat_messages
             WHERE id > ?
             ORDER BY id ASC
             LIMIT ?'
        );
        $stmt->bind_param('ii', $afterId, $limit);
    } else {
        $stmt = $db->prepare(
            'SELECT id, sender_name, sender_role, message, created_at,
                    reply_to_id, reply_to_name, reply_to_text
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

    $replyToId   = !empty($body['reply_to_id']) ? (int)$body['reply_to_id'] : null;
    $replyToName = !empty($body['reply_to_name']) ? mb_substr(trim($body['reply_to_name']), 0, 100) : null;
    $replyToText = !empty($body['reply_to_text']) ? mb_substr(trim($body['reply_to_text']), 0, 250) : null;

    if ($senderName === '' || $message === '') {
        jsonError('Ady we habary doldurmaly!');
    }
    if (mb_strlen($message) > 2000) {
        jsonError('Habar gaty uzyn (max 2000 harp)');
    }

    $stmt = $db->prepare(
        'INSERT INTO chat_messages (sender_name, sender_role, message, reply_to_id, reply_to_name, reply_to_text)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $stmt->bind_param('sssiss', $senderName, $senderRole, $message, $replyToId, $replyToName, $replyToText);

    if ($stmt->execute()) {
        $id = $db->insert_id;

        // 500'den fazla mesaj birikmesini önle
        $db->query('DELETE FROM chat_messages WHERE id NOT IN
                    (SELECT id FROM (SELECT id FROM chat_messages ORDER BY id DESC LIMIT 500) t)');

        $stmt->close();
        $db->close();
        jsonOk(['id' => $id, 'message' => 'Habar ugradyldy!']);
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

// ── DELETE: mesajy poz ─────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        jsonError('Geçerli ID gerekli!', 400);
    }

    $stmt = $db->prepare('DELETE FROM chat_messages WHERE id = ?');
    $stmt->bind_param('i', $id);

    if ($stmt->execute()) {
        $affected = $stmt->affected_rows;
        $stmt->close();
        $db->close();
        if ($affected > 0) {
            jsonOk(['message' => 'Habar pozuldy!']);
        } else {
            jsonError('Habar tapylmady!', 404);
        }
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

// ── PUT: mesajy üýtget ─────────────────────────
if ($method === 'PUT') {
    $body    = getBody();
    $id      = (int)($body['id'] ?? 0);
    $message = trim($body['message'] ?? '');

    if ($id <= 0 || $message === '') {
        jsonError('ID we täze teksti doldurmaly!', 400);
    }
    if (mb_strlen($message) > 2000) {
        jsonError('Habar gaty uzyn (max 2000 harp)', 400);
    }

    $stmt = $db->prepare('UPDATE chat_messages SET message = ? WHERE id = ?');
    $stmt->bind_param('si', $message, $id);

    if ($stmt->execute()) {
        $stmt->close();
        $db->close();
        jsonOk(['message' => 'Habar üýtgedildi!']);
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

jsonError('Rugsat berilmedik usul', 405);
