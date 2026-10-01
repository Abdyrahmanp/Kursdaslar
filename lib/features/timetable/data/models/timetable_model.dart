import 'package:flutter/foundation.dart';

@immutable
class ClassEntry {
  final int period;
  final String subject;
  final String teacher;
  final String room;
  final String startTime;
  final String endTime;

  const ClassEntry({
    required this.period,
    required this.subject,
    required this.teacher,
    required this.room,
    this.startTime = '',
    this.endTime = '',
  });

  /// Default period time intervals (115-topar schedule)
  static (String, String) defaultTimesForPeriod(int period) {
    switch (period) {
      case 1:
        return ('09:00', '10:20');
      case 2:
        return ('10:30', '11:50');
      case 3:
        return ('12:20', '13:40');
      case 4:
        return ('13:50', '15:10');
      case 5:
        return ('15:20', '16:40');
      case 6:
        return ('16:50', '18:10');
      default:
        return ('13:50', '15:10');
    }
  }

  String get effectiveStartTime {
    if (startTime.isNotEmpty) return startTime;
    return defaultTimesForPeriod(period).$1;
  }

  String get effectiveEndTime {
    if (endTime.isNotEmpty) return endTime;
    return defaultTimesForPeriod(period).$2;
  }

  ClassEntry copyWith({
    int? period,
    String? subject,
    String? teacher,
    String? room,
    String? startTime,
    String? endTime,
  }) {
    return ClassEntry(
      period: period ?? this.period,
      subject: subject ?? this.subject,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  factory ClassEntry.fromJson(Map<String, dynamic> json) {
    final p = (json['period'] as num?)?.toInt() ?? 1;
    final defaults = defaultTimesForPeriod(p);
    return ClassEntry(
      period: p,
      subject: json['subject']?.toString() ?? '',
      teacher: json['teacher']?.toString() ?? '',
      room: json['room']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? defaults.$1,
      endTime: json['end_time']?.toString() ?? defaults.$2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'subject': subject,
      'teacher': teacher,
      'room': room,
      'start_time': effectiveStartTime,
      'end_time': effectiveEndTime,
    };
  }
}
