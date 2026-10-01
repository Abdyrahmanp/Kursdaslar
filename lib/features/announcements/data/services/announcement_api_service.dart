import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/network/byethost_http_client.dart';
import '../models/announcement_model.dart';

class AnnouncementApiService {
  final http.Client _client;

  AnnouncementApiService({http.Client? client})
      : _client = client ?? ByethostHttpClient();

  static final Uri _annUri = Uri.parse(AppConstants.announcementsUrl);

  // ── Tüm duyuruları getir ──────────────────────────────────────────────────
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final response = await _client
          .get(_annUri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        // PHP API: { success: true, data: [...] }
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Eski format uyumu (düz liste)
        if (decoded is List) {
          return decoded
              .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      debugPrint('[AnnouncementApiService] Failed: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      debugPrint('[AnnouncementApiService] fetchAnnouncements error: $e');
      return [];
    }
  }

  // ── Yeni duyuru gönder ────────────────────────────────────────────────────
  Future<bool> postAnnouncement({
    required String content,
    String? title,
    String senderName = 'Tuşiýewa Abadan (Starşy)',
    String senderRole = 'starshy',
    bool isUrgent = false,
    List<String> targetIds = const [],
  }) async {
    try {
      final finalTitle = title ??
          (content.length > 40 ? '${content.substring(0, 40)}…' : content);

      String effectiveBody = content;
      if (targetIds.isNotEmpty && !targetIds.contains('all')) {
        // Embed targets in body comment tag for backwards compatibility with existing PHP backend
        effectiveBody = '$content\n<!--targets:${targetIds.join(',')}-->';
      }

      final response = await _client
          .post(
            _annUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'title': finalTitle,
              'body': effectiveBody,
              'sender_name': senderName,
              'sender_role': senderRole,
              'target_ids': targetIds.join(','),
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] postAnnouncement error: $e');
      return false;
    }
  }

  // ── Duyuru sil ─────────────────────────────────────────────────────────────
  Future<bool> deleteAnnouncement(String id) async {
    try {
      final uri = _annUri.replace(queryParameters: {'id': id});
      final response = await _client
          .delete(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) return true;

      // Fallback: POST with _method = DELETE if server restricts DELETE
      final fallbackResponse = await _client.post(
        _annUri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'_method': 'DELETE', 'id': id}),
      ).timeout(AppConstants.apiTimeout);

      return fallbackResponse.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] deleteAnnouncement error: $e');
      return false;
    }
  }

  // ── Duyuru düzenle ─────────────────────────────────────────────────────────
  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    bool isUrgent = false,
    List<String>? targetIds,
  }) async {
    try {
      final payload = {
        'id': id,
        'title': title,
        'body': content,
        'is_urgent': isUrgent ? 1 : 0,
        if (targetIds != null) 'target_ids': targetIds.join(','),
      };

      final response = await _client
          .put(
            _annUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) return true;

      // Fallback: POST with _method = PUT
      final fallbackPayload = Map<String, dynamic>.from(payload)..['_method'] = 'PUT';
      final fallbackResponse = await _client.post(
        _annUri,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(fallbackPayload),
      ).timeout(AppConstants.apiTimeout);

      return fallbackResponse.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] updateAnnouncement error: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}
