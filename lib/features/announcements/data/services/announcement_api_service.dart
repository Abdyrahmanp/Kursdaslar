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
      debugPrint('[AnnouncementApiService] Failed: ${response.statusCode}');
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
  }) async {
    try {
      final finalTitle = title ??
          (content.length > 40 ? '${content.substring(0, 40)}…' : content);

      final response = await _client
          .post(
            _annUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'title': finalTitle,
              'body': content,
              'sender_name': senderName,
              'sender_role': senderRole,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] postAnnouncement error: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}
