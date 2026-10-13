import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents an attachment associated with a subject topic (PDF, PPTX, Image).
@immutable
class TopicAttachment {
  final String id;
  final String name;
  /// Type: 'pdf' | 'pptx' | 'image'
  final String type;
  /// Formatted size string e.g. "2.4 MB"
  final String size;
  /// Base64 data URI or remote/asset URL
  final String urlOrData;
  /// For PDF/PPTX: slide or page count
  final int pageCount;
  /// Optional slide preview titles or outline items
  final List<String> slideTitles;
  /// Optional base64 or SVG/preview string for first slide / thumbnail
  final String? thumbnail;

  const TopicAttachment({
    required this.id,
    required this.name,
    required this.type,
    required this.size,
    required this.urlOrData,
    this.pageCount = 1,
    this.slideTitles = const [],
    this.thumbnail,
  });

  bool get isPdf => type.toLowerCase() == 'pdf';
  bool get isPptx => type.toLowerCase() == 'pptx' || type.toLowerCase() == 'ppt';
  bool get isImage =>
      type.toLowerCase() == 'image' ||
      type.toLowerCase() == 'jpg' ||
      type.toLowerCase() == 'jpeg' ||
      type.toLowerCase() == 'png' ||
      type.toLowerCase() == 'webp';

  factory TopicAttachment.fromJson(Map<String, dynamic> json) {
    List<String> titles = [];
    final rawTitles = json['slide_titles'] ?? json['slideTitles'];
    if (rawTitles is List) {
      titles = rawTitles.map((e) => e.toString()).toList();
    } else if (rawTitles is String && rawTitles.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTitles);
        if (decoded is List) {
          titles = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return TopicAttachment(
      id: json['id']?.toString() ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Faýl',
      type: json['type']?.toString().toLowerCase() ?? 'pdf',
      size: json['size']?.toString() ?? '1.2 MB',
      urlOrData: json['url_or_data']?.toString() ??
          json['url']?.toString() ??
          json['data']?.toString() ??
          '',
      pageCount: int.tryParse(json['page_count']?.toString() ?? json['pageCount']?.toString() ?? '1') ?? 1,
      slideTitles: titles,
      thumbnail: json['thumbnail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'size': size,
      'url_or_data': urlOrData,
      'page_count': pageCount,
      'slide_titles': slideTitles,
      if (thumbnail != null) 'thumbnail': thumbnail,
    };
  }
}

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
  final List<TopicAttachment> attachments;

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
    this.attachments = const [],
  });

  bool get hasHomework => homework.trim().isNotEmpty;
  bool get hasAttachments => attachments.isNotEmpty;

  factory Topic.fromJson(Map<String, dynamic> json) {
    final rawSubName = json['subject_name']?.toString() ?? json['subjectName']?.toString() ?? '';
    final fixedSubName = rawSubName.replaceAll('I?lis', 'Iňlis').replaceAll('i?lis', 'iňlis');

    List<TopicAttachment> parsedAttachments = [];
    final rawAtts = json['attachments'];
    if (rawAtts is List) {
      parsedAttachments = rawAtts
          .map((a) => a is Map<String, dynamic>
              ? TopicAttachment.fromJson(a)
              : a is Map
                  ? TopicAttachment.fromJson(Map<String, dynamic>.from(a))
                  : null)
          .whereType<TopicAttachment>()
          .toList();
    } else if (rawAtts is String && rawAtts.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawAtts);
        if (decoded is List) {
          parsedAttachments = decoded
              .map((a) => a is Map ? TopicAttachment.fromJson(Map<String, dynamic>.from(a)) : null)
              .whereType<TopicAttachment>()
              .toList();
        }
      } catch (_) {}
    }

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
      attachments: parsedAttachments,
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
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  Topic copyWith({
    String? id,
    String? subjectId,
    String? subjectName,
    String? subjectCode,
    String? title,
    String? content,
    String? homework,
    String? date,
    String? createdBy,
    List<TopicAttachment>? attachments,
  }) {
    return Topic(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectCode: subjectCode ?? this.subjectCode,
      title: title ?? this.title,
      content: content ?? this.content,
      homework: homework ?? this.homework,
      date: date ?? this.date,
      createdBy: createdBy ?? this.createdBy,
      attachments: attachments ?? this.attachments,
    );
  }
}
