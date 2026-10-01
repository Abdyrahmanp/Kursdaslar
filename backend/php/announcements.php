<?php
// ─────────────────────────────────────────────
//  announcements.php  —  Duýduryşlar API (Resilient)
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db     = getDB();
$method = $_SERVER['REQUEST_METHOD'];
if ($method === 'POST') {
    $rawBodyCheck = getBody();
    if (isset($rawBodyCheck['_method'])) {
        $method = strtoupper($rawBodyCheck['_method']);
    }
}
$jsonFile = 'data_announcements.json';

// ── GET: ähli duýduryşlary getir ───────────────
if ($method === 'GET') {
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $limit = max(1, min(100, $limit));

    if ($db) {
        try {
            // Check & auto-add column if not exists
            @$db->query("ALTER TABLE announcements ADD COLUMN target_ids TEXT NULL");
            $stmt = $db->prepare(
                'SELECT id, title, body, sender_name, sender_role, target_ids, created_at
                 FROM announcements
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
        } catch (\Throwable $e) {
            // DB fail bolsa json faýlyna geç
        }
    }

    // JSON file fallback
    $rows = loadJsonFile($jsonFile, [
        [
            'id' => 1,
            'title' => '📢 Ertirki Ders Wagty Özgerdi',
            'body' => 'Salam topar! Ertir ir bilen sagat 09:00-da bolmaly dersimiz sagat 10:30-a geçirildi. Ähliňiz wagtynda geliň.',
            'sender_name' => 'Tuşiýewa Abadan (Starşy)',
            'sender_role' => 'starshy',
            'target_ids' => '',
            'created_at' => date('Y-m-d H:i:s', strtotime('-2 hours')),
        ],
        [
            'id' => 2,
            'title' => '📚 Öý Işi we Amaly Ýapgylar',
            'body' => 'Iňlis dili we Ýapon dili dersi boýunça berlen amaly işleri şu hepdäniň ahyryna çenli tabşyrmaly.',
            'sender_name' => 'Tuşiýewa Abadan (Starşy)',
            'sender_role' => 'starshy',
            'target_ids' => '',
            'created_at' => date('Y-m-d H:i:s', strtotime('-1 day')),
        ],
    ]);

    jsonOk(array_slice($rows, 0, $limit));
}

// ── POST: täze duýduryş goş ────────────────────
if ($method === 'POST') {
    $body        = getBody();
    $title       = trim($body['title']       ?? '');
    $text        = trim($body['body']        ?? '');
    $senderName  = trim($body['sender_name'] ?? 'Tuşiýewa Abadan (Starşy)');
    $senderRole  = trim($body['sender_role'] ?? 'starshy');
    $targetIds   = trim($body['target_ids']  ?? '');

    if ($title === '' || $text === '') {
        jsonError('Başlyk we tekst hökman gerek!');
    }

    if ($db) {
        try {
            @$db->query("ALTER TABLE announcements ADD COLUMN target_ids TEXT NULL");
            $stmt = $db->prepare(
                'INSERT INTO announcements (title, body, sender_name, sender_role, target_ids)
                 VALUES (?, ?, ?, ?, ?)'
            );
            if ($stmt) {
                $stmt->bind_param('sssss', $title, $text, $senderName, $senderRole, $targetIds);
                if ($stmt->execute()) {
                    $id = $db->insert_id;
                    $stmt->close();
                    jsonOk(['id' => $id, 'message' => 'Duýduryş üstünlikli goşuldy!']);
                }
            }
        } catch (\Throwable $e) {
            // DB fail bolsa json faýlyna geç
        }
    }

    // JSON file fallback
    $rows = loadJsonFile($jsonFile, []);
    $newId = count($rows) > 0 ? (max(array_column($rows, 'id')) + 1) : 1;
    $newItem = [
        'id' => $newId,
        'title' => $title,
        'body' => $text,
        'sender_name' => $senderName,
        'sender_role' => $senderRole,
        'target_ids' => $targetIds,
        'created_at' => date('Y-m-d H:i:s'),
    ];
    array_unshift($rows, $newItem);
    saveJsonFile($jsonFile, $rows);
    jsonOk(['id' => $newId, 'message' => 'Duýduryş üstünlikli goşuldy!']);
}

// ── DELETE: duýduryşy poz ───────────────────────
if ($method === 'DELETE') {
    $body = getBody();
    $id = isset($_GET['id']) ? (int)$_GET['id'] : (int)($body['id'] ?? 0);
    if ($id <= 0) {
        jsonError('Geçerli ID gerek!', 400);
    }

    if ($db) {
        try {
            $stmt = $db->prepare('DELETE FROM announcements WHERE id = ?');
            if ($stmt) {
                $stmt->bind_param('i', $id);
                $stmt->execute();
                $stmt->close();
            }
        } catch (\Throwable $e) {}
    }

    $rows = loadJsonFile($jsonFile, []);
    $rows = array_values(array_filter($rows, fn($r) => (int)($r['id'] ?? 0) !== $id));
    saveJsonFile($jsonFile, $rows);
    jsonOk(['message' => 'Duýduryş üstünlikli pozuldy!']);
}

// ── PUT: duýduryşy düzet ───────────────────────
if ($method === 'PUT') {
    $body  = getBody();
    $id    = (int)($body['id'] ?? $_GET['id'] ?? 0);
    $title = trim($body['title'] ?? '');
    $text  = trim($body['body'] ?? $body['content'] ?? '');
    $targetIds = isset($body['target_ids']) ? trim($body['target_ids']) : null;

    if ($id <= 0 || ($title === '' && $text === '')) {
        jsonError('ID we üýtgediljek maglumat hökman gerek!', 400);
    }

    if ($db) {
        try {
            $stmt = $db->prepare('UPDATE announcements SET title = ?, body = ? WHERE id = ?');
            if ($stmt) {
                $stmt->bind_param('ssi', $title, $text, $id);
                $stmt->execute();
                $stmt->close();
            }
        } catch (\Throwable $e) {}
    }

    $rows = loadJsonFile($jsonFile, []);
    foreach ($rows as &$r) {
        if ((int)($r['id'] ?? 0) === $id) {
            if ($title !== '') $r['title'] = $title;
            if ($text !== '') $r['body'] = $text;
            if ($targetIds !== null) $r['target_ids'] = $targetIds;
            break;
        }
    }
    saveJsonFile($jsonFile, $rows);
    jsonOk(['message' => 'Duýduryş üstünlikli üýtgedildi!']);
}

jsonError('Rugsat berilmedik usul', 405);
