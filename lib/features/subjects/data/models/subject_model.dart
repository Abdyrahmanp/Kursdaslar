import 'package:flutter/foundation.dart';

@immutable
class Subject {
  final String id;
  final String name;
  final String code;
  final String teacherName;
  final String iconName;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.teacherName,
    this.iconName = 'school',
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final fixedName = rawName.replaceAll('I?lis', 'Iňlis').replaceAll('i?lis', 'iňlis');
    return Subject(
      id: json['id']?.toString() ?? '',
      name: fixedName,
      code: json['code']?.toString() ?? '',
      teacherName: json['teacher_name']?.toString() ??
          json['teacher']?.toString() ??
          json['teacherName']?.toString() ??
          '',
      iconName: json['icon_name']?.toString() ??
          json['iconName']?.toString() ??
          'school',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'teacher_name': teacherName,
      'icon_name': iconName,
    };
  }
}
