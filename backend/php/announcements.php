<?php
// ─────────────────────────────────────────────
//  announcements.php  —  Duýduryşlar API
//  GET  → hepsini listele
//  POST → yeni duýduryş ekle (starşy/admin)
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db     = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// ── GET: tüm duyuruları getir ─────────────────
if ($method === 'GET') {
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $limit = max(1, min(100, $limit));

    $stmt = $db->prepare(
        'SELECT id, title, body, sender_name, sender_role, created_at
         FROM announcements
         ORDER BY created_at DESC
         LIMIT ?'
    );
    $stmt->bind_param('i', $limit);
    $stmt->execute();
    $res  = $stmt->get_result();
    $rows = [];
    while ($row = $res->fetch_assoc()) {
        $rows[] = $row;
    }
    $stmt->close();
    $db->close();
    jsonOk($rows);
}

// ── POST: yeni duyuru ekle ────────────────────
if ($method === 'POST') {
    $body        = getBody();
    $title       = trim($body['title']       ?? '');
    $text        = trim($body['body']        ?? '');
    $senderName  = trim($body['sender_name'] ?? 'Admin');
    $senderRole  = trim($body['sender_role'] ?? 'admin');

    if ($title === '' || $text === '') {
        jsonError('Başlyk we tekst hökman gerek!');
    }

    $stmt = $db->prepare(
        'INSERT INTO announcements (title, body, sender_name, sender_role)
         VALUES (?, ?, ?, ?)'
    );
    $stmt->bind_param('ssss', $title, $text, $senderName, $senderRole);

    if ($stmt->execute()) {
        $id = $db->insert_id;
        $stmt->close();
        $db->close();
        jsonOk(['id' => $id, 'message' => 'Duyuru üstünlikli goşuldy!']);
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

jsonError('Rugsat berilmedik usul', 405);
