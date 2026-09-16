import 'package:flutter/foundation.dart';

@immutable
class Announcement {
  final String id;
  final String title;
  final String content;
  final String senderName;
  final String senderPhone;
  final DateTime timestamp;
  final int recipientCount;
  final bool isUrgent;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.senderName,
    required this.senderPhone,
    required this.timestamp,
    required this.recipientCount,
    this.isUrgent = false,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    return '$day.$month.2026, $hour:$minute';
  }
}
