<?php
/**
 * Topar-115 / Kursdaşlar — Announcements API (PHP Zero-Config Version)
 * Drop this file into Alwaysdata's `www/` folder or `www/api/index.php`.
 * Runs natively on Alwaysdata with zero external dependencies.
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$dataFile = __DIR__ . '/announcements.json';

// Initialize default data if file doesn't exist
if (!file_exists($dataFile)) {
    $initialData = [
        [
            'id' => 'ann_01',
            'title' => '📢 Ertirki Ders Wagty Özgerdi',
            'content' => 'Salam topar! Ertir ir bilen sagat 09:00-da bolmaly dersimiz sagat 10:30-a geçirildi. Ähliňiz wagtynda geliň.',
            'senderName' => 'Tuşiýewa Abadan (Starşy)',
            'senderPhone' => '+993 61 76 28 19',
            'timestamp' => date('c', strtotime('-2 hours')),
            'recipientCount' => 25,
            'isUrgent' => true,
        ],
        [
            'id' => 'ann_02',
            'title' => '📚 Öý Işi we Amaly Ýapgylar',
            'content' => 'Matematika we Kompýuter Ylymlary dersi boýunça berlen 3-nji amaly işi şu anna gününe çenli tabşyrmaly.',
            'senderName' => 'Tuşiýewa Abadan (Starşy)',
            'senderPhone' => '+993 61 76 28 19',
            'timestamp' => date('c', strtotime('-1 day')),
            'recipientCount' => 25,
            'isUrgent' => false,
        ],
        [
            'id' => 'ann_03',
            'title' => '🎓 Topar Ýygnagy',
            'content' => 'Şenbe güni sagat 14:00-da fakultet zalynda umumy topar ýygnagy bolar. Gatnaşmak ähli talyplar üçin hökmanydyr.',
            'senderName' => 'Tuşiýewa Abadan (Starşy)',
            'senderPhone' => '+993 61 76 28 19',
            'timestamp' => date('c', strtotime('-2 days')),
            'recipientCount' => 25,
            'isUrgent' => false,
        ]
    ];
    file_put_contents($dataFile, json_encode($initialData, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
}

function loadAnnouncements($dataFile) {
    if (!file_exists($dataFile)) return [];
    $raw = file_get_contents($dataFile);
    $data = json_decode($raw, true);
    return is_array($data) ? $data : [];
}

function saveAnnouncements($dataFile, $data) {
    file_put_contents($dataFile, json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
}

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$path = isset($_SERVER['PATH_INFO']) ? trim($_SERVER['PATH_INFO'], '/') : '';

// Health check
if ($method === 'GET' && ($path === 'health' || isset($_GET['health']))) {
    echo json_encode(['status' => 'ok', 'timestamp' => date('c')]);
    exit();
}

// GET /api/announcements
if ($method === 'GET') {
    $list = loadAnnouncements($dataFile);
    // Sort descending by timestamp
    usort($list, function($a, $b) {
        return strtotime($b['timestamp']) - strtotime($a['timestamp']);
    });
    echo json_encode($list, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    exit();
}

// POST /api/announcements
if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);

    if (!$data || empty(trim($data['content'] ?? ''))) {
        http_response_code(400);
        echo json_encode(['error' => 'content meýdany hökman gerek']);
        exit();
    }

    $content = trim($data['content']);
    $title = !empty(trim($data['title'] ?? '')) ? trim($data['title']) : (mb_strlen($content) > 30 ? mb_substr($content, 0, 30) . '…' : $content);
    $senderName = $data['senderName'] ?? 'Tuşiýewa Abadan (Starşy)';
    $senderPhone = $data['senderPhone'] ?? '+993 61 76 28 19';
    $isUrgent = !empty($data['isUrgent']);
    $recipientCount = (int)($data['recipientCount'] ?? 25);
    $timestamp = $data['timestamp'] ?? date('c');
    $id = $data['id'] ?? ('ann_' . round(microtime(true) * 1000));

    $newAnnouncement = [
        'id' => $id,
        'title' => $title,
        'content' => $content,
        'senderName' => $senderName,
        'senderPhone' => $senderPhone,
        'timestamp' => $timestamp,
        'recipientCount' => $recipientCount,
        'isUrgent' => $isUrgent,
    ];

    $list = loadAnnouncements($dataFile);
    array_unshift($list, $newAnnouncement);
    saveAnnouncements($dataFile, $list);

    http_response_code(201);
    $newAnnouncement['message'] = 'Duýduryş üstünlikli ýerleşdirildi';
    echo json_encode($newAnnouncement, JSON_UNESCAPED_UNICODE);
    exit();
}

// DELETE /api/announcements
if ($method === 'DELETE') {
    $id = $_GET['id'] ?? $path;
    if ($id) {
        $list = loadAnnouncements($dataFile);
        $filtered = array_values(array_filter($list, function($item) use ($id) {
            return $item['id'] !== $id;
        }));
        saveAnnouncements($dataFile, $filtered);
        echo json_encode(['message' => "$id pozuldy"]);
        exit();
    }
}
