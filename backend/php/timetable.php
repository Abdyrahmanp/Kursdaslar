<?php
// ─────────────────────────────────────────────
//  timetable.php  —  Raspisaniýe / Tertip API (Resilient)
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
$jsonFile = 'data_timetable.json';

// Default schedule (115-topar)
$defaultSchedule = [
    '1' => [
        ['period' => 1, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
        ['period' => 2, 'subject' => 'Ýapon dili', 'teacher' => 'Nuryyewa Amanbike', 'room' => '3341'],
        ['period' => 3, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
    ],
    '2' => [
        ['period' => 1, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
        ['period' => 2, 'subject' => 'Matematika', 'teacher' => 'Bonjakowa Ogultuwak', 'room' => '3136'],
        ['period' => 3, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
    ],
    '3' => [
        ['period' => 1, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
        ['period' => 2, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
        ['period' => 3, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
    ],
    '4' => [
        ['period' => 1, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
        ['period' => 2, 'subject' => 'Fizika', 'teacher' => 'Amanmammedowa Maýsagül', 'room' => '3119'],
        ['period' => 3, 'subject' => 'Iňlis dili', 'teacher' => 'Berdinazarow Altymyrat', 'room' => '3341'],
    ],
    '5' => [
        ['period' => 1, 'subject' => 'Informatika', 'teacher' => 'Başymow Serdar', 'room' => '3136'],
        ['period' => 2, 'subject' => 'Ýapon dili', 'teacher' => 'Nuryyewa Amanbike', 'room' => '3341'],
        ['period' => 3, 'subject' => 'Ýapon dili', 'teacher' => 'Nuryyewa Amanbike', 'room' => '3341'],
    ],
    '6' => [
        ['period' => 1, 'subject' => 'Ýapon dili', 'teacher' => 'Nuryyewa Amanbike', 'room' => '3341'],
        ['period' => 2, 'subject' => 'Türkmen dili', 'teacher' => 'Ýoldaşowa Zylyha', 'room' => '3341'],
        ['period' => 3, 'subject' => 'Ýapon dili', 'teacher' => 'Nuryyewa Amanbike', 'room' => '3341'],
    ],
];

// ── GET: Raspisaniýäni getir ──────────────────
if ($method === 'GET') {
    if ($db) {
        try {
            $res = $db->query('SELECT day_of_week, period, subject, teacher, room, start_time, end_time FROM timetable ORDER BY day_of_week ASC, period ASC');
            if ($res && $res->num_rows > 0) {
                $sched = [
                    '1' => [], '2' => [], '3' => [],
                    '4' => [], '5' => [], '6' => []
                ];
                while ($row = $res->fetch_assoc()) {
                    $d = (string)$row['day_of_week'];
                    $sched[$d][] = [
                        'period'     => (int)$row['period'],
                        'subject'    => $row['subject'],
                        'teacher'    => $row['teacher'] ?? '',
                        'room'       => $row['room'] ?? '',
                        'start_time' => $row['start_time'] ?? '',
                        'end_time'   => $row['end_time'] ?? '',
                    ];
                }
                jsonOk($sched);
            }
        } catch (\Throwable $e) {}
    }

    $sched = loadJsonFile($jsonFile, $defaultSchedule);
    jsonOk($sched);
}

// ── POST / PUT: Raspisaniýäni ýatda sakla ─────
if ($method === 'POST' || $method === 'PUT') {
    $body = getBody();
    $schedule = $body['schedule'] ?? null;
    $day = isset($body['day']) ? (int)$body['day'] : null;
    $lessons = $body['lessons'] ?? null;

    $current = loadJsonFile($jsonFile, $defaultSchedule);

    if ($schedule && is_array($schedule)) {
        // Complete schedule update
        foreach ($schedule as $d => $items) {
            $key = (string)$d;
            if (is_array($items)) {
                $current[$key] = $items;
            }
        }
    } else if ($day !== null && $day >= 1 && $day <= 6 && is_array($lessons)) {
        // Single day update
        $current[(string)$day] = $lessons;
    } else {
        jsonError('Dogry tertip (schedule ýa-da day+lessons) ugradyň!', 400);
    }

    // Save to JSON
    saveJsonFile($jsonFile, $current);

    // Save to MySQL
    if ($db) {
        try {
            if ($day !== null && $day >= 1 && $day <= 6) {
                // Clear and re-insert single day
                $db->query("DELETE FROM timetable WHERE day_of_week = $day");
                $stmt = $db->prepare('INSERT INTO timetable (day_of_week, period, subject, teacher, room, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?, ?)');
                if ($stmt) {
                    foreach ($current[(string)$day] as $l) {
                        $period = (int)($l['period'] ?? 1);
                        $subj   = trim($l['subject'] ?? '');
                        $teach  = trim($l['teacher'] ?? '');
                        $room   = trim($l['room'] ?? '');
                        $st     = trim($l['start_time'] ?? '');
                        $et     = trim($l['end_time'] ?? '');
                        $stmt->bind_param('iisssss', $day, $period, $subj, $teach, $room, $st, $et);
                        $stmt->execute();
                    }
                    $stmt->close();
                }
            } else {
                // Full overwrite
                $db->query('TRUNCATE TABLE timetable');
                $stmt = $db->prepare('INSERT INTO timetable (day_of_week, period, subject, teacher, room, start_time, end_time) VALUES (?, ?, ?, ?, ?, ?, ?)');
                if ($stmt) {
                    foreach ($current as $d => $items) {
                        $dInt = (int)$d;
                        if (!is_array($items)) continue;
                        foreach ($items as $l) {
                            $period = (int)($l['period'] ?? 1);
                            $subj   = trim($l['subject'] ?? '');
                            $teach  = trim($l['teacher'] ?? '');
                            $room   = trim($l['room'] ?? '');
                            $st     = trim($l['start_time'] ?? '');
                            $et     = trim($l['end_time'] ?? '');
                            $stmt->bind_param('iisssss', $dInt, $period, $subj, $teach, $room, $st, $et);
                            $stmt->execute();
                        }
                    }
                    $stmt->close();
                }
            }
        } catch (\Throwable $e) {}
    }

    jsonOk(['message' => 'Raspisaniýe üstünlikli ýatda saklandy!', 'data' => $current]);
}

jsonError('Rugsat berilmedik usul', 405);
