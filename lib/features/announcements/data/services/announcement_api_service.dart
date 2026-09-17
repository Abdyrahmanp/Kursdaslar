import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:topar_115/core/constants/app_constants.dart';
import '../models/announcement_model.dart';

class AnnouncementApiService {
  final String baseUrl;
  final http.Client _client;

  AnnouncementApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConstants.apiBaseUrl,
        _client = client ?? http.Client();

  /// Normalizes endpoint URL to prevent double slashes.
  Uri _buildUri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  /// Checks if the Alwaysdata server is reachable and healthy.
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(_buildUri('/health'))
          .timeout(AppConstants.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] Health check failed: $e');
      return false;
    }
  }

  /// Fetches all announcements from Alwaysdata server.
  Future<List<Announcement>> fetchAnnouncements() async {
    try {
      // In PHP mode, path might be root or /announcements, we support both
      final uri = baseUrl.contains('.php')
          ? Uri.parse(baseUrl)
          : _buildUri('/announcements');

      final response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          return decoded
              .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (decoded is Map<String, dynamic> && decoded.containsKey('announcements')) {
          final list = decoded['announcements'] as List;
          return list
              .map((item) => Announcement.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      debugPrint('[AnnouncementApiService] Failed with status: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('[AnnouncementApiService] fetchAnnouncements error: $e');
      rethrow;
    }
  }

  /// Sends a new announcement to Alwaysdata server.
  Future<Announcement> postAnnouncement({
    required String content,
    String? title,
    String senderName = 'Tuşiýewa Abadan (Starşy)',
    String senderPhone = '+993 61 76 28 19',
    int recipientCount = 25,
    bool isUrgent = false,
  }) async {
    try {
      final uri = baseUrl.contains('.php')
          ? Uri.parse(baseUrl)
          : _buildUri('/announcements');

      final bodyData = {
        'content': content,
        'title': title ?? (content.length > 30 ? '${content.substring(0, 30)}…' : content),
        'senderName': senderName,
        'senderPhone': senderPhone,
        'recipientCount': recipientCount,
        'isUrgent': isUrgent,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(bodyData),
          )
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> decoded =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return Announcement.fromJson(decoded);
      } else {
        throw Exception('Serwer ýalňyşlygy: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AnnouncementApiService] postAnnouncement error: $e');
      rethrow;
    }
  }

  /// Deletes an announcement on Alwaysdata server.
  Future<bool> deleteAnnouncement(String id) async {
    try {
      final uri = baseUrl.contains('.php')
          ? Uri.parse('$baseUrl?id=$id')
          : _buildUri('/announcements/$id');

      final response = await _client
          .delete(uri)
          .timeout(AppConstants.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AnnouncementApiService] deleteAnnouncement error: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
