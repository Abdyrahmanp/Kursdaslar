import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:topar_115/core/constants/app_constants.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';

class SubjectApiService {
  final http.Client _client;

  SubjectApiService({http.Client? client}) : _client = client ?? http.Client();

  static final Uri _subjectsUri = Uri.parse(AppConstants.subjectsUrl);

  // ── Tüm dersleri getir ────────────────────────────────────────────────────
  Future<List<Subject>> fetchSubjects() async {
    try {
      final uri = _subjectsUri.replace(
        queryParameters: {'type': 'subjects'},
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Subject.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SubjectApiService] fetchSubjects error: $e');
      return [];
    }
  }

  // ── Tüm temaları getir ────────────────────────────────────────────────────
  Future<List<Topic>> fetchAllTopics() async {
    try {
      final uri = _subjectsUri.replace(
        queryParameters: {'type': 'topics'},
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SubjectApiService] fetchAllTopics error: $e');
      return [];
    }
  }

  // ── Belirli derse ait temaları getir ──────────────────────────────────────
  Future<List<Topic>> fetchTopicsForSubject(String subjectId) async {
    try {
      final uri = _subjectsUri.replace(
        queryParameters: {'type': 'topics', 'subject': subjectId},
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SubjectApiService] fetchTopicsForSubject error: $e');
      return [];
    }
  }

  // ── Yeni tema ekle ────────────────────────────────────────────────────────
  Future<bool> createTopic({
    required String subjectId,
    required String title,
    required String content,
    String homework = '',
    required String createdBy,
  }) async {
    try {
      final uri = _subjectsUri.replace(queryParameters: {'type': 'topic'});
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'type': 'topic', // ekstra guvenlik ucin body'e hem goshyas
              'subject_id': int.tryParse(subjectId) ?? 0,
              'title': title,
              'content': content,
              'homework': homework,
              'created_by': createdBy,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['success'] == true) {
          return true;
        }
        debugPrint('[SubjectApiService] createTopic server error: ${decoded['error']}');
        return false;
      }
      debugPrint('[SubjectApiService] createTopic HTTP ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('[SubjectApiService] createTopic error: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}
