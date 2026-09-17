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
  final bool isOnline;

  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.senderName,
    required this.senderPhone,
    required this.timestamp,
    required this.recipientCount,
    this.isUrgent = false,
    this.isOnline = true,
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day.$month.$year, $hour:$minute';
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    if (json['timestamp'] != null) {
      parsedTime = DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    return Announcement(
      id: json['id']?.toString() ?? 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Tuşiýewa Abadan (Starşy)',
      senderPhone: json['senderPhone']?.toString() ?? '+993 61 76 28 19',
      timestamp: parsedTime,
      recipientCount: (json['recipientCount'] as num?)?.toInt() ?? 25,
      isUrgent: json['isUrgent'] == true || json['isUrgent'] == 1,
      isOnline: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'timestamp': timestamp.toIso8601String(),
      'recipientCount': recipientCount,
      'isUrgent': isUrgent,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? senderName,
    String? senderPhone,
    DateTime? timestamp,
    int? recipientCount,
    bool? isUrgent,
    bool? isOnline,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      timestamp: timestamp ?? this.timestamp,
      recipientCount: recipientCount ?? this.recipientCount,
      isUrgent: isUrgent ?? this.isUrgent,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
