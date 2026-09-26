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
  final List<String> targetIds; // Empty or containing 'all' means all students

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
    this.targetIds = const [],
  });

  String get formattedTime {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final year = timestamp.year;
    return '$day.$month.$year, $hour:$minute';
  }

  /// Whether a student with the given id or phone is an intended recipient.
  bool isRecipient(String? studentId, String? studentPhone) {
    if (targetIds.isEmpty || targetIds.contains('all')) return true;
    if (studentId != null && targetIds.contains(studentId)) return true;
    if (studentPhone != null && studentPhone.isNotEmpty) {
      final cleanP = studentPhone.replaceAll(RegExp(r'\D'), '');
      for (final t in targetIds) {
        if (t == studentPhone) return true;
        final cleanT = t.replaceAll(RegExp(r'\D'), '');
        if (cleanT.isNotEmpty && cleanP.endsWith(cleanT)) return true;
      }
    }
    return false;
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    // Preserve original timestamp; fall back only if null
    final rawTime = json['created_at'] ?? json['timestamp'];
    DateTime parsedTime;
    if (rawTime != null) {
      parsedTime = DateTime.tryParse(rawTime.toString()) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    final rawBody = (json['content'] ?? json['body'] ?? '').toString();

    // Parse target_ids (if present directly or via embedded tag)
    List<String> parsedTargets = [];
    if (json['target_ids'] != null) {
      if (json['target_ids'] is List) {
        parsedTargets = (json['target_ids'] as List)
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else {
        parsedTargets = json['target_ids']
            .toString()
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    // Backwards-compatible check: embedded <!--targets:s01,s02--> in body/content
    String finalContent = rawBody;
    final regex = RegExp(r'<!--targets:(.*?)-->');
    final match = regex.firstMatch(rawBody);
    if (match != null) {
      final idsStr = match.group(1) ?? '';
      if (parsedTargets.isEmpty && idsStr.isNotEmpty) {
        parsedTargets = idsStr
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      finalContent = rawBody.replaceAll(regex, '').trim();
    }

    return Announcement(
      id: json['id']?.toString() ?? 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      content: finalContent,
      senderName: json['sender_name']?.toString() ??
          json['senderName']?.toString() ??
          'Tuşiýewa Abadan (Starşy)',
      senderPhone: json['sender_phone']?.toString() ??
          json['senderPhone']?.toString() ??
          '+993 61 76 28 19',
      timestamp: parsedTime,
      recipientCount: (json['recipientCount'] as num?)?.toInt() ??
          (parsedTargets.isNotEmpty ? parsedTargets.length : 25),
      isUrgent: json['isUrgent'] == true ||
          json['isUrgent'] == 1 ||
          json['is_urgent'] == 1 ||
          json['is_urgent'] == '1',
      isOnline: true,
      targetIds: parsedTargets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'body': content,
      'sender_name': senderName,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'timestamp': timestamp.toIso8601String(),
      'created_at': timestamp.toIso8601String(),
      'recipientCount': recipientCount,
      'isUrgent': isUrgent,
      'target_ids': targetIds.join(','),
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
    List<String>? targetIds,
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
      targetIds: targetIds ?? this.targetIds,
    );
  }
}
