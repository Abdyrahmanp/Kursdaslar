import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/network/byethost_http_client.dart';
import '../models/chat_message_model.dart';

class ChatApiService {
  final http.Client _client;

  ChatApiService({http.Client? client}) : _client = client ?? ByethostHttpClient();

  static final Uri _chatUri = Uri.parse(AppConstants.chatUrl);

  // ── Ilkinji ýükleme: soňky 25 haty getir ───────────────────────────────────
  Future<List<ChatMessage>> fetchMessages({int limit = 25}) async {
    try {
      final uri = _chatUri.replace(
        queryParameters: {'limit': '$limit'},
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ChatApiService] fetchMessages error: $e');
      return [];
    }
  }

  // ── Öňki ýazyşmalar: beforeId-den öňki hatlary getir ───────────────────────
  Future<List<ChatMessage>> fetchOlderMessages({
    required int beforeId,
    int limit = 25,
  }) async {
    try {
      final uri = _chatUri.replace(
        queryParameters: {
          'before': '$beforeId',
          'limit': '$limit',
        },
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ChatApiService] fetchOlderMessages error: $e');
      return [];
    }
  }

  // ── Short Polling: afterId'den sonraki yeni mesajları getir ───────────────
  Future<List<ChatMessage>> fetchNewMessages(int afterId) async {
    try {
      final uri = _chatUri.replace(
        queryParameters: {'after': '$afterId'},
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && decoded['data'] is List) {
          return (decoded['data'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[ChatApiService] fetchNewMessages error: $e');
      return [];
    }
  }

  // ── Mesaj gönder ──────────────────────────────────────────────────────────
  Future<bool> sendMessage({
    required String senderName,
    required String senderRole,
    required String message,
    String? replyToId,
    String? replyToName,
    String? replyToText,
  }) async {
    try {
      final body = {
        'sender_name': senderName,
        'sender_role': senderRole,
        'message': message,
        if (replyToId != null && replyToId.isNotEmpty) 'reply_to_id': replyToId,
        if (replyToName != null && replyToName.isNotEmpty) 'reply_to_name': replyToName,
        if (replyToText != null && replyToText.isNotEmpty) 'reply_to_text': replyToText,
      };

      final response = await _client
          .post(
            _chatUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApiService] sendMessage error: $e');
      return false;
    }
  }

  // ── Mesaj sil ─────────────────────────────────────────────────────────────
  Future<bool> deleteMessage(String messageId) async {
    try {
      final uri = _chatUri.replace(
        queryParameters: {'id': messageId},
      );
      final response = await _client
          .delete(uri, headers: {'Accept': 'application/json'})
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApiService] deleteMessage error: $e');
      return false;
    }
  }

  // ── Mesaj düzenle ─────────────────────────────────────────────────────────
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      final response = await _client
          .put(
            _chatUri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'id': messageId,
              'message': newText,
            }),
          )
          .timeout(AppConstants.apiTimeout);

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ChatApiService] editMessage error: $e');
      return false;
    }
  }

  void dispose() => _client.close();
}

