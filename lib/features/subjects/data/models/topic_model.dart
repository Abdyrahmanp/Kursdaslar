import 'package:flutter/foundation.dart';

@immutable
class Topic {
  final String id;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String title;
  final String content;
  final String homework;
  final String date;
  final String createdBy;

  const Topic({
    required this.id,
    required this.subjectId,
    this.subjectName = '',
    this.subjectCode = '',
    required this.title,
    required this.content,
    this.homework = '',
    required this.date,
    required this.createdBy,
  });

  bool get hasHomework => homework.trim().isNotEmpty;

  factory Topic.fromJson(Map<String, dynamic> json) {
    final rawSubName = json['subject_name']?.toString() ?? json['subjectName']?.toString() ?? '';
    final fixedSubName = rawSubName.replaceAll('I?lis', 'Iňlis').replaceAll('i?lis', 'iňlis');
    return Topic(
      id: json['id']?.toString() ?? '',
      subjectId: json['subject_id']?.toString() ?? json['subjectId']?.toString() ?? '',
      subjectName: fixedSubName,
      subjectCode: json['subject_code']?.toString() ?? json['subjectCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      homework: json['homework']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? json['createdBy']?.toString() ?? 'Starşy',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'subject_code': subjectCode,
      'title': title,
      'content': content,
      'homework': homework,
      'date': date,
      'created_by': createdBy,
    };
  }
}
