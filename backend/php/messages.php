<?php
// ─────────────────────────────────────────────
//  messages.php  —  Grup Chat / Hatlar API (Resilient)
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db       = getDB();
$method   = $_SERVER['REQUEST_METHOD'];
$jsonFile = 'data_messages.json';

// ── GET: son mesajları getir ──────────────────
if ($method === 'GET') {
    $afterId  = isset($_GET['after'])  ? (int)$_GET['after']  : 0;
    $beforeId = isset($_GET['before']) ? (int)$_GET['before'] : 0;
    $limit    = isset($_GET['limit'])  ? (int)$_GET['limit']  : 30;
    $limit    = max(1, min(200, $limit));

    if ($db) {
        try {
            if ($afterId > 0) {
                // Sadece täze hatlar
                $stmt = $db->prepare(
                    'SELECT id, sender_name, sender_role, message, created_at,
                            reply_to_id, reply_to_name, reply_to_text
                     FROM chat_messages
                     WHERE id > ?
                     ORDER BY id ASC
                     LIMIT ?'
                );
                $stmt->bind_param('ii', $afterId, $limit);
            } else if ($beforeId > 0) {
                // Öňki hatlar (beforeId-den öňki)
                $stmt = $db->prepare(
                    'SELECT id, sender_name, sender_role, message, created_at,
                            reply_to_id, reply_to_name, reply_to_text
                     FROM chat_messages
                     WHERE id < ?
                     ORDER BY id DESC
                     LIMIT ?'
                );
                $stmt->bind_param('ii', $beforeId, $limit);
            } else {
                // Iň soňky N hat
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
            while ($row = $res->fetch_assoc()) $rows[] = $row;
            if ($afterId === 0) $rows = array_reverse($rows);
            $stmt->close();
            jsonOk($rows);
        } catch (\Throwable $e) {}
    }

    // JSON file fallback
    $all = loadJsonFile($jsonFile, []);
    if ($afterId > 0) {
        $filtered = array_values(array_filter($all, fn($m) => (int)($m['id'] ?? 0) > $afterId));
        jsonOk(array_slice($filtered, 0, $limit));
    } else if ($beforeId > 0) {
        $filtered = array_values(array_filter($all, fn($m) => (int)($m['id'] ?? 0) < $beforeId));
        $slice = array_slice($filtered, -$limit);
        jsonOk($slice);
    } else {
        $slice = array_slice($all, -$limit);
        jsonOk(array_values($slice));
    }
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

    if ($db) {
        try {
            $stmt = $db->prepare(
                'INSERT INTO chat_messages (sender_name, sender_role, message, reply_to_id, reply_to_name, reply_to_text)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('sssiss', $senderName, $senderRole, $message, $replyToId, $replyToName, $replyToText);
            if ($stmt->execute()) {
                $id = $db->insert_id;
                $stmt->close();
                jsonOk(['id' => $id, 'message' => 'Habar ugradyldy!']);
            }
        } catch (\Throwable $e) {}
    }

    // JSON file fallback
    $all = loadJsonFile($jsonFile, []);
    $newId = count($all) > 0 ? (max(array_map(fn($m) => (int)($m['id'] ?? 0), $all)) + 1) : 1;
    $newMsg = [
        'id' => $newId,
        'sender_name' => $senderName,
        'sender_role' => $senderRole,
        'message' => $message,
        'created_at' => date('Y-m-d H:i:s'),
        'reply_to_id' => $replyToId,
        'reply_to_name' => $replyToName,
        'reply_to_text' => $replyToText,
    ];
    $all[] = $newMsg;
    if (count($all) > 500) $all = array_slice($all, -500);
    saveJsonFile($jsonFile, $all);
    jsonOk(['id' => $newId, 'message' => 'Habar ugradyldy!']);
}

// ── DELETE: mesajy poz ─────────────────────────
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) jsonError('Geçerli ID gerekli!', 400);

    if ($db) {
        try {
            $stmt = $db->prepare('DELETE FROM chat_messages WHERE id = ?');
            $stmt->bind_param('i', $id);
            $stmt->execute();
            $stmt->close();
        } catch (\Throwable $e) {}
    }

    $all = loadJsonFile($jsonFile, []);
    $all = array_values(array_filter($all, fn($m) => (int)($m['id'] ?? 0) !== $id));
    saveJsonFile($jsonFile, $all);
    jsonOk(['message' => 'Habar pozuldy!']);
}

// ── PUT: mesajy üýtget ─────────────────────────
if ($method === 'PUT') {
    $body    = getBody();
    $id      = (int)($body['id'] ?? 0);
    $message = trim($body['message'] ?? '');

    if ($id <= 0 || $message === '') jsonError('ID we täze teksti doldurmaly!', 400);

    if ($db) {
        try {
            $stmt = $db->prepare('UPDATE chat_messages SET message = ? WHERE id = ?');
            $stmt->bind_param('si', $message, $id);
            $stmt->execute();
            $stmt->close();
        } catch (\Throwable $e) {}
    }

    $all = loadJsonFile($jsonFile, []);
    foreach ($all as &$m) {
        if ((int)($m['id'] ?? 0) === $id) {
            $m['message'] = $message;
            break;
        }
    }
    saveJsonFile($jsonFile, $all);
    jsonOk(['message' => 'Habar üýtgedildi!']);
}

jsonError('Rugsat berilmedik usul', 405);
