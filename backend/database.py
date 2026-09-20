"""
Database configuration and initialization for Topar-115 Backend.
Supports both local SQLite and Fly.io Persistent Volume (/data/topar115.db).
"""

import sqlite3
import os
import datetime

# If running on Fly.io with a mounted volume at /data, use that for persistence.
# Otherwise, use local directory.
if os.path.isdir('/data'):
    DB_PATH = '/data/topar115.db'
else:
    DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'topar115.db')


def get_db():
    conn = sqlite3.connect(DB_PATH, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Creates tables and initial seed data if not present."""
    with get_db() as conn:
        cursor = conn.cursor()

        # 1. Announcements Table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS announcements (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                sender_name TEXT NOT NULL,
                sender_phone TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                recipient_count INTEGER NOT NULL DEFAULT 25,
                is_urgent INTEGER NOT NULL DEFAULT 0
            )
        ''')

        # 2. Chat Messages Table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS chat_messages (
                id TEXT PRIMARY KEY,
                sender_name TEXT NOT NULL,
                sender_phone TEXT NOT NULL,
                message TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                role TEXT NOT NULL DEFAULT 'student'
            )
        ''')

        # 3. Subjects (Sapaklar) Table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS subjects (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                code TEXT NOT NULL,
                teacher_name TEXT NOT NULL,
                icon_name TEXT NOT NULL DEFAULT 'school'
            )
        ''')

        # 4. Topics & Homework (Sapak Temalary we Öý Işleri) Table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS topics (
                id TEXT PRIMARY KEY,
                subject_id TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                homework TEXT DEFAULT '',
                date TEXT NOT NULL,
                created_by TEXT NOT NULL,
                FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE
            )
        ''')

        # Seed initial subjects if empty
        cursor.execute('SELECT COUNT(*) as count FROM subjects')
        if cursor.fetchone()['count'] == 0:
            initial_subjects = [
                ('sub_01', 'Kompýuter Torlary', 'KT-115', 'Amanow B.', 'network_check'),
                ('sub_02', 'Maglumat Howpsuzlygy', 'MH-115', 'Gurbandurdyýew M.', 'security'),
                ('sub_03', 'Web Programmirleme (Flutter & Python)', 'WP-115', 'Tuşiýewa A.', 'code'),
                ('sub_04', 'Maglumatlar Binýady (SQL & NoSQL)', 'MB-115', 'Hydyrow S.', 'storage'),
                ('sub_05', 'Algoritmler we Maglumat Gurluşlary', 'AMG-115', 'Kakalyýew K.', 'terminal'),
            ]
            cursor.executemany('''
                INSERT INTO subjects (id, name, code, teacher_name, icon_name)
                VALUES (?, ?, ?, ?, ?)
            ''', initial_subjects)

            # Seed initial topics
            initial_topics = [
                (
                    'top_01',
                    'sub_01',
                    '1-nji Tema: OSI Modeli we TCP/IP protokollary',
                    'OSI modeliniň 7 gatlagy we TCP/IP protokollarynyň arasyndaky tapawutlar barada umumy düşünje.',
                    'Ders kitabyndan 1-nji baplary okamak we soraglara jogap taýýarlamak.',
                    datetime.date.today().isoformat(),
                    'Tuşiýewa Abadan (Starşy)'
                ),
                (
                    'top_02',
                    'sub_03',
                    '1-nji Tema: Flutter-da State Management (Riverpod)',
                    'Riverpod bilen döwrebap mobil programma ýasamak, ProviderScope we StateNotifier ulanmak.',
                    '3-nji amaly işi taýýarlap, github-a ugratmak.',
                    datetime.date.today().isoformat(),
                    'Tuşiýewa Abadan (Starşy)'
                )
            ]
            cursor.executemany('''
                INSERT INTO topics (id, subject_id, title, content, homework, date, created_by)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', initial_topics)

        # Seed initial announcements if empty
        cursor.execute('SELECT COUNT(*) as count FROM announcements')
        if cursor.fetchone()['count'] == 0:
            initial_announcements = [
                (
                    'ann_01',
                    '📢 Ertirki Ders Wagty Özgerdi',
                    'Salam topar! Ertir ir bilen sagat 09:00-da bolmaly dersimiz sagat 10:30-a geçirildi. Ähliňiz wagtynda geliň.',
                    'Tuşiýewa Abadan (Starşy)',
                    '+993 61 76 28 19',
                    (datetime.datetime.now() - datetime.timedelta(hours=2)).isoformat(),
                    25,
                    1
                ),
                (
                    'ann_02',
                    '📚 Öý Işi we Amaly Ýapgylar',
                    'Web Programmirleme dersi boýunça berlen 3-nji amaly işi şu anna gününe çenli tabşyrmaly.',
                    'Tuşiýewa Abadan (Starşy)',
                    '+993 61 76 28 19',
                    (datetime.datetime.now() - datetime.timedelta(days=1)).isoformat(),
                    25,
                    0
                )
            ]
            cursor.executemany('''
                INSERT INTO announcements (id, title, content, sender_name, sender_phone, timestamp, recipient_count, is_urgent)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', initial_announcements)

        # Seed a welcome chat message if chat is empty
        cursor.execute('SELECT COUNT(*) as count FROM chat_messages')
        if cursor.fetchone()['count'] == 0:
            cursor.execute('''
                INSERT INTO chat_messages (id, sender_name, sender_phone, message, timestamp, role)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                'msg_01',
                'Tuşiýewa Abadan (Starşy)',
                '+993 61 76 28 19',
                'Salam toparadaşlarym! Topar-115 umumy söhbetdeşlik toparyna hoş geldiňiz! 🎓',
                (datetime.datetime.now() - datetime.timedelta(minutes=30)).isoformat(),
                'starshy'
            ))

        conn.commit()


# Automatically initialize on module load
init_db()
