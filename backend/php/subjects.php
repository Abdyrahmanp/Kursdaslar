<?php
// ─────────────────────────────────────────────
//  subjects.php  —  Sapaklar + Temalar API (Resilient)
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db      = getDB();
$method  = $_SERVER['REQUEST_METHOD'];
$bodyRaw = ($method === 'POST' || $method === 'PUT') ? (json_decode(file_get_contents('php://input'), true) ?? []) : [];
$type    = $_GET['type'] ?? $bodyRaw['type'] ?? 'topics';

$jsonSubjects = 'data_subjects.json';
$jsonTopics   = 'data_topics.json';

$defaultSubjects = [
    ['id' => 1, 'code' => 'ENG', 'name' => 'Iňlis dili',   'teacher' => 'Berdinazarow Altymyrat'],
    ['id' => 2, 'code' => 'JPN', 'name' => 'Ýapon dili',   'teacher' => 'Nuryyewa Amanbike'],
    ['id' => 3, 'code' => 'TKM', 'name' => 'Türkmen dili', 'teacher' => 'Ýoldaşowa Zylyha'],
    ['id' => 4, 'code' => 'INF', 'name' => 'Informatika',  'teacher' => 'Başymow Serdar'],
    ['id' => 5, 'code' => 'MAT', 'name' => 'Matematika',   'teacher' => 'Bonjakowa Ogultuwak'],
    ['id' => 6, 'code' => 'FIZ', 'name' => 'Fizika',       'teacher' => 'Amanmammedowa Maýsagül'],
];

// ══════════════════════════════════════════════
//  GET
// ══════════════════════════════════════════════
if ($method === 'GET') {
    if ($type === 'subjects') {
        if ($db) {
            try {
                $res = $db->query('SELECT MIN(id) AS id, code, name, MAX(teacher) AS teacher FROM subjects GROUP BY name, code ORDER BY MIN(id) ASC');
                $rows = [];
                if ($res) {
                    while ($row = $res->fetch_assoc()) $rows[] = $row;
                }
                if (!empty($rows)) jsonOk($rows);
            } catch (\Throwable $e) {}
        }
        $subs = loadJsonFile($jsonSubjects, $defaultSubjects);
        // JSON süzgüji: gaýtalanýan dersleri aýyr
        $unique = [];
        $seen = [];
        foreach ($subs as $s) {
            $key = mb_strtolower(trim($s['name'] ?? ''));
            if ($key !== '' && !isset($seen[$key])) {
                $seen[$key] = true;
                $unique[] = $s;
            }
        }
        jsonOk($unique);
    }

    // Temalar
    $subjectId = isset($_GET['subject']) ? (int)$_GET['subject'] : 0;
    if ($db) {
        try {
            if ($subjectId > 0) {
                $stmt = $db->prepare(
                    "SELECT t.id, t.subject_id,
                            COALESCE(s.code, 'DERS') AS subject_code,
                            COALESCE(s.name, 'Umumy Ders') AS subject_name,
                            t.title, t.content, t.homework, t.created_by,
                            t.attachments,
                            DATE_FORMAT(t.created_at, '%d.%m.%Y') AS date
                     FROM topics t
                     LEFT JOIN subjects s ON s.id = t.subject_id
                     WHERE t.subject_id = ?
                     ORDER BY t.id DESC"
                );
                $stmt->bind_param('i', $subjectId);
            } else {
                $stmt = $db->prepare(
                    "SELECT t.id, t.subject_id,
                            COALESCE(s.code, 'DERS') AS subject_code,
                            COALESCE(s.name, 'Umumy Ders') AS subject_name,
                            t.title, t.content, t.homework, t.created_by,
                            t.attachments,
                            DATE_FORMAT(t.created_at, '%d.%m.%Y') AS date
                     FROM topics t
                     LEFT JOIN subjects s ON s.id = t.subject_id
                     ORDER BY t.id DESC"
                );
            }
            $stmt->execute();
            $res = $stmt->get_result();
            $rows = [];
            while ($row = $res->fetch_assoc()) {
                if (isset($row['attachments']) && is_string($row['attachments']) && $row['attachments'] !== '') {
                    $decodedAtts = json_decode($row['attachments'], true);
                    $row['attachments'] = is_array($decodedAtts) ? $decodedAtts : [];
                } else if (!isset($row['attachments'])) {
                    $row['attachments'] = [];
                }
                $rows[] = $row;
            }
            $stmt->close();
            jsonOk($rows);
        } catch (\Throwable $e) {}
    }

    // JSON file fallback
    $topics = loadJsonFile($jsonTopics, []);
    if ($subjectId > 0) {
        $topics = array_values(array_filter($topics, fn($t) => (int)($t['subject_id'] ?? 0) === $subjectId));
    }
    jsonOk($topics);
}

// ══════════════════════════════════════════════
//  POST — Täze tema goş
// ══════════════════════════════════════════════
if ($method === 'POST') {
    $body       = getBody();
    $subjectId  = (int)($body['subject_id'] ?? 0);
    $title      = trim($body['title']       ?? '');
    $content    = trim($body['content']     ?? '');
    $homework   = trim($body['homework']    ?? '');
    $createdBy  = trim($body['created_by']  ?? 'Starşy');

    if ($title === '') {
        jsonError('Tema ady hökman!');
    }

    $attachments = $body['attachments'] ?? [];
    if (!is_array($attachments)) {
        $attachments = json_decode($attachments, true) ?? [];
    }

    if ($db) {
        try {
            $validSubject = false;
            if ($subjectId > 0) {
                $check = $db->prepare('SELECT id FROM subjects WHERE id = ? LIMIT 1');
                $check->bind_param('i', $subjectId);
                $check->execute();
                $checkRes = $check->get_result();
                if ($checkRes && $checkRes->num_rows > 0) $validSubject = true;
                $check->close();
            }
            if (!$validSubject) {
                $firstSub = $db->query('SELECT id FROM subjects ORDER BY id ASC LIMIT 1');
                if ($firstSub && $row = $firstSub->fetch_assoc()) {
                    $subjectId = (int)$row['id'];
                }
            }

            $attachmentsJson = !empty($attachments) ? json_encode($attachments, JSON_UNESCAPED_UNICODE) : null;
            $stmt = $db->prepare(
                'INSERT INTO topics (subject_id, title, content, homework, created_by, attachments)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->bind_param('isssss', $subjectId, $title, $content, $homework, $createdBy, $attachmentsJson);
            if ($stmt->execute()) {
                $id = $db->insert_id;
                $stmt->close();
                // Also persist attachments in JSON file fallback store
                $topics = loadJsonFile($jsonTopics, []);
                $subs = loadJsonFile($jsonSubjects, $defaultSubjects);
                $subName = 'Ders';
                $subCode = 'DERS';
                foreach ($subs as $s) {
                    if ((int)$s['id'] === $subjectId) {
                        $subName = $s['name'];
                        $subCode = $s['code'];
                        break;
                    }
                }
                $newTopic = [
                    'id' => $id,
                    'subject_id' => $subjectId,
                    'subject_code' => $subCode,
                    'subject_name' => $subName,
                    'title' => $title,
                    'content' => $content,
                    'homework' => $homework,
                    'created_by' => $createdBy,
                    'date' => date('d.m.Y'),
                    'attachments' => $attachments,
                ];
                array_unshift($topics, $newTopic);
                saveJsonFile($jsonTopics, $topics);
                jsonOk(['id' => $id, 'subject_id' => $subjectId, 'message' => 'Täze tema goşuldy!']);
            }
        } catch (\Throwable $e) {}
    }

    // JSON file fallback
    $topics = loadJsonFile($jsonTopics, []);
    $newId = count($topics) > 0 ? (max(array_map(fn($t) => (int)($t['id'] ?? 0), $topics)) + 1) : 1;
    $subs = loadJsonFile($jsonSubjects, $defaultSubjects);
    $subName = 'Ders';
    $subCode = 'DERS';
    foreach ($subs as $s) {
        if ((int)$s['id'] === $subjectId) {
            $subName = $s['name'];
            $subCode = $s['code'];
            break;
        }
    }

    $newTopic = [
        'id' => $newId,
        'subject_id' => $subjectId,
        'subject_code' => $subCode,
        'subject_name' => $subName,
        'title' => $title,
        'content' => $content,
        'homework' => $homework,
        'created_by' => $createdBy,
        'date' => date('d.m.Y'),
        'attachments' => $attachments,
    ];
    array_unshift($topics, $newTopic);
    saveJsonFile($jsonTopics, $topics);
    jsonOk(['id' => $newId, 'subject_id' => $subjectId, 'message' => 'Täze tema goşuldy!']);
}

// ══════════════════════════════════════════════
//  DELETE — Temany poz
// ══════════════════════════════════════════════
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        jsonError('Geçerli ID gerekli!', 400);
    }

    if ($db) {
        try {
            $stmt = $db->prepare('DELETE FROM topics WHERE id = ?');
            $stmt->bind_param('i', $id);
            $stmt->execute();
            $stmt->close();
        } catch (\Throwable $e) {}
    }

    // JSON file sync
    $topics = loadJsonFile($jsonTopics, []);
    $topics = array_values(array_filter($topics, fn($t) => (int)($t['id'] ?? 0) !== $id));
    saveJsonFile($jsonTopics, $topics);
    jsonOk(['message' => 'Tema pozuldy!']);
}

// ══════════════════════════════════════════════
//  PUT — Temany üýtget
// ══════════════════════════════════════════════
if ($method === 'PUT') {
    $body     = getBody();
    $id       = (int)($body['id'] ?? 0);
    $title    = trim($body['title']    ?? '');
    $content  = trim($body['content']  ?? '');
    $attachments = isset($body['attachments']) ? $body['attachments'] : null;
    if ($attachments !== null && !is_array($attachments)) {
        $attachments = json_decode($attachments, true) ?? [];
    }

    $homework = trim($body['homework'] ?? '');

    if ($id <= 0 || $title === '') {
        jsonError('ID we temany doldurmaly!', 400);
    }

    if ($db) {
        try {
            if ($attachments !== null) {
                $attachmentsJson = !empty($attachments) ? json_encode($attachments, JSON_UNESCAPED_UNICODE) : null;
                $stmt = $db->prepare('UPDATE topics SET title = ?, content = ?, homework = ?, attachments = ? WHERE id = ?');
                $stmt->bind_param('ssssi', $title, $content, $homework, $attachmentsJson, $id);
            } else {
                $stmt = $db->prepare('UPDATE topics SET title = ?, content = ?, homework = ? WHERE id = ?');
                $stmt->bind_param('sssi', $title, $content, $homework, $id);
            }
            $stmt->execute();
            $stmt->close();
        } catch (\Throwable $e) {}
    }

    // JSON file sync
    $topics = loadJsonFile($jsonTopics, []);
    foreach ($topics as &$t) {
        if ((int)($t['id'] ?? 0) === $id) {
            $t['title']    = $title;
            $t['content']  = $content;
            $t['homework'] = $homework;
            if ($attachments !== null) {
                $t['attachments'] = $attachments;
            }
            break;
        }
    }
    saveJsonFile($jsonTopics, $topics);
    jsonOk(['message' => 'Tema üýtgedildi!']);
}

jsonError('Rugsat berilmedik usul', 405);
