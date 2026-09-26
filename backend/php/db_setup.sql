-- ═══════════════════════════════════════════════════
--  Topar-115  —  MySQL Veritabanı Kurulum Scripti
--  Byethost cPanel → phpMyAdmin → SQL sekmesine yapıştır
-- ═══════════════════════════════════════════════════

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

-- ─── 1. Duyurular ────────────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title       VARCHAR(255)  NOT NULL,
    body        TEXT          NOT NULL,
    sender_name VARCHAR(100)  NOT NULL DEFAULT 'Admin',
    sender_role VARCHAR(30)   NOT NULL DEFAULT 'admin',
    target_ids  TEXT          NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── 2. Chat Mesajları ───────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_name VARCHAR(100)  NOT NULL,
    sender_role VARCHAR(30)   NOT NULL DEFAULT 'student',
    message     TEXT          NOT NULL,
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_id_desc (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── 3. Dersler (Subjects) ───────────────────────────
CREATE TABLE IF NOT EXISTS subjects (
    id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code    VARCHAR(20)   NOT NULL,
    name    VARCHAR(150)  NOT NULL,
    teacher VARCHAR(100)  NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─── 4. Temalar (Topics) ────────────────────────────
CREATE TABLE IF NOT EXISTS topics (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    subject_id  INT UNSIGNED  NOT NULL,
    title       VARCHAR(255)  NOT NULL,
    content     TEXT          NOT NULL DEFAULT '',
    homework    TEXT          NOT NULL DEFAULT '',
    created_by  VARCHAR(100)  NOT NULL DEFAULT 'Starşy',
    created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
    INDEX idx_subject (subject_id),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ═══════════════════════════════════════════════════
--  Başlangıç verileri (Topar-115 dersler)
-- ═══════════════════════════════════════════════════

INSERT INTO subjects (code, name, teacher) VALUES
  ('ENG',  'Iňlis dili',                  ''),
  ('JPN',  'Ýapon dili',                  ''),
  ('TKM',  'Türkmen dili',                ''),
  ('INF',  'Informatika',                 ''),
  ('MAT',  'Matematika',                  ''),
  ('FIZ',  'Fizika',                      '');
