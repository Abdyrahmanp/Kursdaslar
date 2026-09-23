import 'package:flutter/foundation.dart';

@immutable
class ReplyInfo {
  final String messageId;
  final String senderName;
  final String message; // first 80 chars

  const ReplyInfo({
    required this.messageId,
    required this.senderName,
    required this.message,
  });

  factory ReplyInfo.fromJson(Map<String, dynamic> json) {
    return ReplyInfo(
      messageId: json['reply_to_id']?.toString() ?? '',
      senderName: json['reply_to_name']?.toString() ?? '',
      message: json['reply_to_text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply_to_id': messageId,
      'reply_to_name': senderName,
      'reply_to_text': message,
    };
  }

  String get preview =>
      message.length > 80 ? '${message.substring(0, 80)}…' : message;
}

@immutable
class ChatMessage {
  final String id;
  final String senderName;
  final String senderPhone;
  final String message;
  final DateTime timestamp;
  final String role; // 'starshy', 'admin', 'student'
  final bool isPending; // Gönderilmekte — optimistic UI
  final bool isFailed;  // Gönderilemedi
  final ReplyInfo? replyTo; // Yanıtlanan mesaj (null ise yanıt değil)

  const ChatMessage({
    required this.id,
    required this.senderName,
    this.senderPhone = '',
    required this.message,
    required this.timestamp,
    this.role = 'student',
    this.isPending = false,
    this.isFailed = false,
    this.replyTo,
  });

  bool get isStarshy => role == 'starshy';
  bool get isAdmin => role == 'admin';
  bool get hasReply => replyTo != null && replyTo!.messageId.isNotEmpty;

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  ChatMessage copyWith({
    String? id,
    String? senderName,
    String? senderPhone,
    String? message,
    DateTime? timestamp,
    String? role,
    bool? isPending,
    bool? isFailed,
    ReplyInfo? replyTo,
    bool clearReply = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      role: role ?? this.role,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
      replyTo: clearReply ? null : (replyTo ?? this.replyTo),
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    final rawTime = json['created_at'] ?? json['timestamp'];
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString()) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    // Parse reply info if present
    ReplyInfo? replyTo;
    final replyId = json['reply_to_id']?.toString();
    if (replyId != null && replyId.isNotEmpty && replyId != '0' && replyId != 'null') {
      replyTo = ReplyInfo(
        messageId: replyId,
        senderName: json['reply_to_name']?.toString() ?? '',
        message: json['reply_to_text']?.toString() ?? '',
      );
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
      isPending: false,
      isFailed: false,
      replyTo: replyTo,
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
      if (replyTo != null) ...replyTo!.toJson(),
    };
  }
}
