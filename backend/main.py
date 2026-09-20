"""
Topar-115 (Kursdaşlar) FastAPI Server
Runs on Fly.io (Docker + Uvicorn) with WebSocket Chat, Announcements & Subjects.
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
import datetime
import uuid
import json

from database import get_db, init_db

# Initialize database tables
init_db()

app = FastAPI(
    title="Topar-115 API Server",
    description="Dual-Mode Realtime Class Management API for Topar-115 (Kursdaşlar)",
    version="2.0.0"
)

# Enable CORS for Flutter mobile, web, and emulator clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Pydantic Request Models ───────────────────────────────────────────────────

class AnnouncementCreate(BaseModel):
    title: Optional[str] = None
    content: str
    senderName: str = "Tuşiýewa Abadan (Starşy)"
    senderPhone: str = "+993 61 76 28 19"
    recipientCount: int = 25
    isUrgent: bool = False
    timestamp: Optional[str] = None


class ChatMessageCreate(BaseModel):
    senderName: str
    senderPhone: str
    message: str
    role: str = "student"  # 'starshy', 'admin', or 'student'


class SubjectCreate(BaseModel):
    name: str
    code: str
    teacherName: str
    iconName: str = "school"


class TopicCreate(BaseModel):
    subjectId: str
    title: str
    content: str
    homework: Optional[str] = ""
    date: Optional[str] = None
    createdBy: str = "Tuşiýewa Abadan (Starşy)"


# ── WebSocket Connection Manager ───────────────────────────────────────────────

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        if websocket in self.active_connections:
            self.active_connections.remove(websocket)

    async def broadcast(self, message_data: dict):
        """Broadcasts a message to all connected clients."""
        payload = json.dumps(message_data, ensure_ascii=False)
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_text(payload)
            except Exception:
                disconnected.append(connection)
        for dead_conn in disconnected:
            self.disconnect(dead_conn)


ws_manager = ConnectionManager()


# ── Basic & Health Endpoints ───────────────────────────────────────────────────

@app.get("/")
def root():
    return {
        "name": "Topar-115 API Server (Fly.io)",
        "version": "2.0.0",
        "status": "online",
        "docs": "/docs",
        "endpoints": {
            "announcements": "/api/announcements",
            "chat_messages": "/api/chat/messages",
            "chat_websocket": "/ws/chat",
            "subjects": "/api/subjects",
            "health": "/api/health"
        }
    }


@app.get("/api/health")
def health():
    return {
        "status": "ok",
        "timestamp": datetime.datetime.now().isoformat(),
        "connections": len(ws_manager.active_connections)
    }


# ── 1. Announcements (Duýduryşlar) Endpoints ──────────────────────────────────

@app.get("/api/announcements")
def get_announcements():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM announcements ORDER BY timestamp DESC")
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "title": row["title"],
                "content": row["content"],
                "senderName": row["sender_name"],
                "senderPhone": row["sender_phone"],
                "timestamp": row["timestamp"],
                "recipientCount": row["recipient_count"],
                "isUrgent": bool(row["is_urgent"]),
                "isOnline": True,
            }
            for row in rows
        ]


@app.post("/api/announcements", status_code=201)
def create_announcement(data: AnnouncementCreate):
    content = data.content.strip()
    if not content:
        raise HTTPException(status_code=400, detail="Duýduryşyň mazmuny boş bolup bilmez.")

    title = data.title.strip() if data.title else (content[:30] + "…" if len(content) > 30 else content)
    ann_id = f"ann_{int(datetime.datetime.now().timestamp() * 1000)}"
    timestamp = data.timestamp or datetime.datetime.now().isoformat()

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO announcements (id, title, content, sender_name, sender_phone, timestamp, recipient_count, is_urgent)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            ann_id,
            title,
            content,
            data.senderName,
            data.senderPhone,
            timestamp,
            data.recipientCount,
            1 if data.isUrgent else 0
        ))
        conn.commit()

    return {
        "id": ann_id,
        "title": title,
        "content": content,
        "senderName": data.senderName,
        "senderPhone": data.senderPhone,
        "timestamp": timestamp,
        "recipientCount": data.recipientCount,
        "isUrgent": data.isUrgent,
        "isOnline": True,
        "message": "Duýduryş serwere goşuldy."
    }


@app.delete("/api/announcements/{ann_id}")
def delete_announcement(ann_id: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM announcements WHERE id = ?", (ann_id,))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Duýduryş tapylmady.")
        return {"message": f"{ann_id} pozuldy."}


# ── 2. Real-time Chat Endpoints & WebSocket ───────────────────────────────────

@app.get("/api/chat/messages")
def get_chat_messages(limit: int = Query(default=100, le=200)):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM chat_messages 
            ORDER BY timestamp DESC 
            LIMIT ?
        """, (limit,))
        rows = cursor.fetchall()
        # Return in chronological order (oldest to newest)
        results = [
            {
                "id": row["id"],
                "senderName": row["sender_name"],
                "senderPhone": row["sender_phone"],
                "message": row["message"],
                "timestamp": row["timestamp"],
                "role": row["role"]
            }
            for row in rows
        ]
        results.reverse()
        return results


@app.post("/api/chat/messages", status_code=201)
async def post_chat_message(data: ChatMessageCreate):
    msg_id = f"msg_{int(datetime.datetime.now().timestamp() * 1000)}"
    timestamp = datetime.datetime.now().isoformat()

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO chat_messages (id, sender_name, sender_phone, message, timestamp, role)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (
            msg_id,
            data.senderName,
            data.senderPhone,
            data.message,
            timestamp,
            data.role
        ))
        conn.commit()

    message_payload = {
        "id": msg_id,
        "senderName": data.senderName,
        "senderPhone": data.senderPhone,
        "message": data.message,
        "timestamp": timestamp,
        "role": data.role
    }

    # Broadcast to all live WebSocket listeners
    await ws_manager.broadcast(message_payload)
    return message_payload


@app.websocket("/ws/chat")
async def websocket_chat_endpoint(websocket: WebSocket):
    """
    Realtime WebSocket channel for instant bidirectional chat.
    Clients send JSON: {"senderName": "...", "senderPhone": "...", "message": "...", "role": "..."}
    """
    await ws_manager.connect(websocket)
    try:
        while True:
            text_data = await websocket.receive_text()
            try:
                data = json.loads(text_data)
                sender_name = data.get("senderName", "Talyp")
                sender_phone = data.get("senderPhone", "")
                msg_text = data.get("message", "").strip()
                role = data.get("role", "student")

                if not msg_text:
                    continue

                msg_id = f"msg_{int(datetime.datetime.now().timestamp() * 1000)}"
                timestamp = datetime.datetime.now().isoformat()

                with get_db() as conn:
                    cursor = conn.cursor()
                    cursor.execute("""
                        INSERT INTO chat_messages (id, sender_name, sender_phone, message, timestamp, role)
                        VALUES (?, ?, ?, ?, ?, ?)
                    """, (msg_id, sender_name, sender_phone, msg_text, timestamp, role))
                    conn.commit()

                payload = {
                    "id": msg_id,
                    "senderName": sender_name,
                    "senderPhone": sender_phone,
                    "message": msg_text,
                    "timestamp": timestamp,
                    "role": role
                }
                await ws_manager.broadcast(payload)
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket)


# ── 3. Subjects & Topics (Sapak Temalary) Endpoints ───────────────────────────

@app.get("/api/subjects")
def get_subjects():
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM subjects ORDER BY name ASC")
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "name": row["name"],
                "code": row["code"],
                "teacherName": row["teacher_name"],
                "iconName": row["icon_name"]
            }
            for row in rows
        ]


@app.post("/api/subjects", status_code=201)
def create_subject(data: SubjectCreate):
    sub_id = f"sub_{uuid.uuid4().hex[:8]}"
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO subjects (id, name, code, teacher_name, icon_name)
            VALUES (?, ?, ?, ?, ?)
        """, (sub_id, data.name, data.code, data.teacherName, data.iconName))
        conn.commit()

    return {
        "id": sub_id,
        "name": data.name,
        "code": data.code,
        "teacherName": data.teacherName,
        "iconName": data.iconName
    }


@app.get("/api/subjects/{subject_id}/topics")
def get_subject_topics(subject_id: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT * FROM topics 
            WHERE subject_id = ? 
            ORDER BY date DESC
        """, (subject_id,))
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "subjectId": row["subject_id"],
                "title": row["title"],
                "content": row["content"],
                "homework": row["homework"],
                "date": row["date"],
                "createdBy": row["created_by"]
            }
            for row in rows
        ]


@app.get("/api/topics")
def get_all_topics():
    """Returns all topics across all subjects, sorted by date descending."""
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT t.*, s.name as subject_name, s.code as subject_code
            FROM topics t
            JOIN subjects s ON t.subject_id = s.id
            ORDER BY t.date DESC
        """)
        rows = cursor.fetchall()
        return [
            {
                "id": row["id"],
                "subjectId": row["subject_id"],
                "subjectName": row["subject_name"],
                "subjectCode": row["subject_code"],
                "title": row["title"],
                "content": row["content"],
                "homework": row["homework"],
                "date": row["date"],
                "createdBy": row["created_by"]
            }
            for row in rows
        ]


@app.post("/api/topics", status_code=201)
def create_topic(data: TopicCreate):
    topic_id = f"top_{int(datetime.datetime.now().timestamp() * 1000)}"
    date_str = data.date or datetime.date.today().isoformat()

    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO topics (id, subject_id, title, content, homework, date, created_by)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            topic_id,
            data.subjectId,
            data.title,
            data.content,
            data.homework or "",
            date_str,
            data.createdBy
        ))
        conn.commit()

    return {
        "id": topic_id,
        "subjectId": data.subjectId,
        "title": data.title,
        "content": data.content,
        "homework": data.homework or "",
        "date": date_str,
        "createdBy": data.createdBy,
        "message": "Sapak temasy üstünlikli goşuldy."
    }


@app.delete("/api/topics/{topic_id}")
def delete_topic(topic_id: str):
    with get_db() as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM topics WHERE id = ?", (topic_id,))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Tema tapylmady.")
        return {"message": f"{topic_id} pozuldy."}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
