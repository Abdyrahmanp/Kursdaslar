<?php
// ─────────────────────────────────────────────
//  subjects.php  —  Sapaklar + Temalar API
//  GET  ?type=subjects          → tüm dersler
//  GET  ?type=topics            → tüm temalar
//  GET  ?type=topics&subject=ID → belirli ders teması
//  POST ?type=subject           → yeni ders ekle
//  POST ?type=topic             → yeni tema ekle
// ─────────────────────────────────────────────
require_once __DIR__ . '/config.php';

$db     = getDB();
$method = $_SERVER['REQUEST_METHOD'];

// Byethost bazen POST'ta GET query string'i kesebiliyor. Hem GET hem Body kontrol edelim:
$bodyRaw = ($method === 'POST') ? (json_decode(file_get_contents('php://input'), true) ?? []) : [];
$type    = $_GET['type'] ?? $bodyRaw['type'] ?? 'topics';

// ══════════════════════════════════════════════
//  GET
// ══════════════════════════════════════════════
if ($method === 'GET') {

    if ($type === 'subjects') {
        // Otomatik bozuk harf onarımı (I?lis -> Iňlis)
        $db->query("UPDATE subjects SET name = 'Iňlis dili' WHERE code = 'ENG' AND (name LIKE '%?%' OR name = 'I?lis dili')");

        // Tüm dersleri getir
        $res = $db->query('SELECT id, code, name, teacher FROM subjects ORDER BY id ASC');
        $rows = [];
        if ($res) {
            while ($row = $res->fetch_assoc()) {
                $rows[] = $row;
            }
        }
        $db->close();
        jsonOk($rows);
    }

    // Temalar (LEFT JOIN ile ders adı/kodu)
    $subjectId = isset($_GET['subject']) ? (int)$_GET['subject'] : 0;

    if ($subjectId > 0) {
        $stmt = $db->prepare(
            "SELECT t.id, t.subject_id,
                    COALESCE(s.code, 'DERS') AS subject_code,
                    COALESCE(s.name, 'Umumy Ders') AS subject_name,
                    t.title, t.content, t.homework, t.created_by,
                    DATE_FORMAT(t.created_at, '%d.%m.%Y') AS date
             FROM topics t
             LEFT JOIN subjects s ON s.id = t.subject_id
             WHERE t.subject_id = ?
             ORDER BY t.created_at DESC"
        );
        $stmt->bind_param('i', $subjectId);
    } else {
        $stmt = $db->prepare(
            "SELECT t.id, t.subject_id,
                    COALESCE(s.code, 'DERS') AS subject_code,
                    COALESCE(s.name, 'Umumy Ders') AS subject_name,
                    t.title, t.content, t.homework, t.created_by,
                    DATE_FORMAT(t.created_at, '%d.%m.%Y') AS date
             FROM topics t
             LEFT JOIN subjects s ON s.id = t.subject_id
             ORDER BY t.created_at DESC
             LIMIT 100"
        );
    }

    $stmt->execute();
    $res  = $stmt->get_result();
    $rows = [];
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $rows[] = $row;
        }
    }
    $stmt->close();
    $db->close();
    jsonOk($rows);
}

// ══════════════════════════════════════════════
//  POST
// ══════════════════════════════════════════════
if ($method === 'POST') {
    $body = $bodyRaw;

    // ── Yeni ders ekle ────────────────────────
    if ($type === 'subject') {
        $code    = trim($body['code']    ?? '');
        $name    = trim($body['name']    ?? '');
        $teacher = trim($body['teacher'] ?? '');

        if ($code === '' || $name === '') jsonError('Kod we ady hökman!');

        $stmt = $db->prepare('INSERT INTO subjects (code, name, teacher) VALUES (?, ?, ?)');
        $stmt->bind_param('sss', $code, $name, $teacher);
        if ($stmt->execute()) {
            $id = $db->insert_id;
            $stmt->close();
            $db->close();
            jsonOk(['id' => $id, 'message' => 'Ders goşuldy']);
        }
        jsonError('DB hatasy: ' . $db->error, 500);
    }

    // ── Yeni tema ekle ────────────────────────
    if ($type === 'topic') {
        $subjectId  = (int)($body['subject_id'] ?? 0);
        $title      = trim($body['title']       ?? '');
        $content    = trim($body['content']     ?? '');
        $homework   = trim($body['homework']    ?? '');
        $createdBy  = trim($body['created_by']  ?? 'Starşy');

        if ($title === '') {
            jsonError('Tema ady hökman!');
        }

        // 1. Eger subject_id 0 bolsa ýa-da subjects tablisasynda tapylmasa,
        // foreign key constraint fail bolmazlygy üçin barlanýar:
        $validSubject = false;
        if ($subjectId > 0) {
            $check = $db->prepare('SELECT id FROM subjects WHERE id = ? LIMIT 1');
            $check->bind_param('i', $subjectId);
            $check->execute();
            $checkRes = $check->get_result();
            if ($checkRes && $checkRes->num_rows > 0) {
                $validSubject = true;
            }
            $check->close();
        }

        // Eger berlen subject_id ýok bolsa, bar bolan ilkinji dersi al
        if (!$validSubject) {
            $firstSub = $db->query('SELECT id FROM subjects ORDER BY id ASC LIMIT 1');
            if ($firstSub && $row = $firstSub->fetch_assoc()) {
                $subjectId = (int)$row['id'];
                $validSubject = true;
            } else {
                // Hiç ders ýok bolsa, default bir ders döret
                $db->query("INSERT INTO subjects (code, name, teacher) VALUES ('TKM', 'Türkmen dili', '')");
                $subjectId = $db->insert_id;
                $validSubject = true;
            }
        }

        $stmt = $db->prepare(
            'INSERT INTO topics (subject_id, title, content, homework, created_by)
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->bind_param('issss', $subjectId, $title, $content, $homework, $createdBy);
        if ($stmt->execute()) {
            $id = $db->insert_id;
            $stmt->close();
            $db->close();
            jsonOk(['id' => $id, 'subject_id' => $subjectId, 'message' => 'Täze tema goşuldy!']);
        } else {
            jsonError('DB ýazma hatasy: ' . $db->error, 500);
        }
    }

    jsonError('Näbelli type: ' . htmlspecialchars($type));
}

// ══════════════════════════════════════════════
//  DELETE — Temany poz
// ══════════════════════════════════════════════
if ($method === 'DELETE') {
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    if ($id <= 0) {
        jsonError('Geçerli ID gerekli!', 400);
    }

    $stmt = $db->prepare('DELETE FROM topics WHERE id = ?');
    $stmt->bind_param('i', $id);

    if ($stmt->execute()) {
        $affected = $stmt->affected_rows;
        $stmt->close();
        $db->close();
        if ($affected > 0) {
            jsonOk(['message' => 'Tema pozuldy!']);
        } else {
            jsonError('Tema tapylmady!', 404);
        }
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

// ══════════════════════════════════════════════
//  PUT — Temany üýtget
// ══════════════════════════════════════════════
if ($method === 'PUT') {
    $body     = json_decode(file_get_contents('php://input'), true) ?? [];
    $id       = (int)($body['id'] ?? 0);
    $title    = trim($body['title']    ?? '');
    $content  = trim($body['content']  ?? '');
    $homework = trim($body['homework'] ?? '');

    if ($id <= 0 || $title === '') {
        jsonError('ID we temany doldurmaly!', 400);
    }

    $stmt = $db->prepare('UPDATE topics SET title = ?, content = ?, homework = ? WHERE id = ?');
    $stmt->bind_param('sssi', $title, $content, $homework, $id);

    if ($stmt->execute()) {
        $stmt->close();
        $db->close();
        jsonOk(['message' => 'Tema üýtgedildi!']);
    } else {
        jsonError('DB ýazma hatasy: ' . $db->error, 500);
    }
}

jsonError('Rugsat berilmedik usul', 405);

