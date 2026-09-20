import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String id;
  final String senderName;
  final String senderPhone;
  final String message;
  final DateTime timestamp;
  final String role; // 'starshy', 'admin', 'student'

  const ChatMessage({
    required this.id,
    required this.senderName,
    this.senderPhone = '',
    required this.message,
    required this.timestamp,
    this.role = 'student',
  });

  bool get isStarshy => role == 'starshy';
  bool get isAdmin => role == 'admin';

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['created_at'] ?? json['timestamp'];
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString()) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderName: json['sender_name']?.toString() ??
          json['senderName']?.toString() ??
          'Talyp',
      senderPhone: json['sender_phone']?.toString() ??
          json['senderPhone']?.toString() ??
          '',
      message: json['message']?.toString() ?? '',
      timestamp: parsedTime,
      role: json['sender_role']?.toString() ??
          json['role']?.toString() ??
          'student',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'sender_role': role,
    };
  }
}
