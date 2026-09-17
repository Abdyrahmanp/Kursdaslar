"""
Topar-115 / Kursdaşlar — Announcements API Server
Compatible with Alwaysdata Python WSGI hosting.
"""

from flask import Flask, request, jsonify
import sqlite3
import datetime
import os

app = Flask(__name__)

# Enable Cross-Origin requests (resilient: uses flask_cors if available, or native after_request)
try:
    from flask_cors import CORS
    CORS(app)
except ImportError:
    @app.after_request
    def add_cors_headers(response):
        response.headers['Access-Control-Allow-Origin'] = '*'
        response.headers['Access-Control-Allow-Headers'] = 'Content-Type,Authorization'
        response.headers['Access-Control-Allow-Methods'] = 'GET,PUT,POST,DELETE,OPTIONS'
        return response

# Database file location
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'announcements.db')


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    """Initializes the database schema if not already present."""
    with get_db() as conn:
        cursor = conn.cursor()
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
        # Insert initial announcements if table is empty
        cursor.execute('SELECT COUNT(*) as count FROM announcements')
        if cursor.fetchone()['count'] == 0:
            initial_data = [
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
                    'Matematika we Kompýuter Ylymlary dersi boýunça berlen 3-nji amaly işi şu anna gününe çenli tabşyrmaly.',
                    'Tuşiýewa Abadan (Starşy)',
                    '+993 61 76 28 19',
                    (datetime.datetime.now() - datetime.timedelta(days=1)).isoformat(),
                    25,
                    0
                ),
                (
                    'ann_03',
                    '🎓 Topar Ýygnagy',
                    'Şenbe güni sagat 14:00-da fakultet zalynda umumy topar ýygnagy bolar. Gatnaşmak ähli talyplar üçin hökmanydyr.',
                    'Tuşiýewa Abadan (Starşy)',
                    '+993 61 76 28 19',
                    (datetime.datetime.now() - datetime.timedelta(days=2)).isoformat(),
                    25,
                    0
                )
            ]
            cursor.executemany('''
                INSERT INTO announcements (id, title, content, sender_name, sender_phone, timestamp, recipient_count, is_urgent)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', initial_data)
        conn.commit()


# Initialize database on startup
init_db()


@app.route('/', methods=['GET'])
def index():
    return jsonify({
        'name': 'Topar-115 Announcements API',
        'status': 'running',
        'endpoints': {
            'health': '/api/health',
            'announcements': '/api/announcements'
        }
    })


@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.datetime.now().isoformat()
    })


@app.route('/api/announcements', methods=['GET'])
def get_announcements():
    """Returns all announcements sorted by timestamp descending."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM announcements ORDER BY timestamp DESC')
            rows = cursor.fetchall()
            
            results = []
            for row in rows:
                results.append({
                    'id': row['id'],
                    'title': row['title'],
                    'content': row['content'],
                    'senderName': row['sender_name'],
                    'senderPhone': row['sender_phone'],
                    'timestamp': row['timestamp'],
                    'recipientCount': row['recipient_count'],
                    'isUrgent': bool(row['is_urgent'])
                })
            return jsonify(results), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/announcements', methods=['POST'])
def create_announcement():
    """Creates a new announcement sent by Starşy."""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'JSON body talap edilýär'}), 400

    content = data.get('content', '').strip()
    if not content:
        return jsonify({'error': 'content meýdany hökman gerek'}), 400

    title = data.get('title', '').strip()
    if not title:
        title = content[:30] + '…' if len(content) > 30 else content

    sender_name = data.get('senderName', 'Tuşiýewa Abadan (Starşy)')
    sender_phone = data.get('senderPhone', '+993 61 76 28 19')
    is_urgent = 1 if data.get('isUrgent', False) else 0
    recipient_count = int(data.get('recipientCount', 25))
    timestamp = data.get('timestamp') or datetime.datetime.now().isoformat()
    ann_id = data.get('id') or f"ann_{int(datetime.datetime.now().timestamp() * 1000)}"

    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO announcements (id, title, content, sender_name, sender_phone, timestamp, recipient_count, is_urgent)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (ann_id, title, content, sender_name, sender_phone, timestamp, recipient_count, is_urgent))
            conn.commit()

        return jsonify({
            'id': ann_id,
            'title': title,
            'content': content,
            'senderName': sender_name,
            'senderPhone': sender_phone,
            'timestamp': timestamp,
            'recipientCount': recipient_count,
            'isUrgent': bool(is_urgent),
            'message': 'Duýduryş üstünlikli ýerleşdirildi'
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/announcements/<ann_id>', methods=['DELETE'])
def delete_announcement(ann_id):
    """Deletes an announcement by its ID."""
    try:
        with get_db() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM announcements WHERE id = ?', (ann_id,))
            conn.commit()
            if cursor.rowcount > 0:
                return jsonify({'message': f'{ann_id} pozuldy'}), 200
            else:
                return jsonify({'error': 'Duýduryş tapylmady'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Local dev server
    app.run(host='0.0.0.0', port=5000, debug=True)
