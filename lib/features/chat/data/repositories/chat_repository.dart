import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import '../models/chat_message_model.dart';
import '../services/chat_api_service.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  final service = ChatApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatApiService _apiService;
  Timer? _pollTimer;
  int _lastSeenId = 0;
  static const String _prefKeyChatCache = 'topar115_cached_chat_messages_v1';

  ChatNotifier(this._apiService) : super(const []) {
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Ilki offline/lokal cache-den hatlary derrew ekrana çykar
    await _loadCachedMessages();
    // 2. Soňra serwerden iň soňky hatlary çek
    await loadMessages();
    // 3. 3 sekuntdan bir täze hat barlygyny barla
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.chatPollInterval, (_) {
      _pollNewMessages();
    });
  }

  /// Lokal ýatdan saklanan hatlary okamak
  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefKeyChatCache);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is List) {
          final list = decoded
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty && state.isEmpty) {
            state = list;
            _updateLastSeenId(list);
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatNotifier] Load cache error: $e');
    }
  }

  /// Hatlary lokal ýatda saklamak (offline-da hem durar ýaly)
  Future<void> _saveCachedMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Iň soňky 80 haty sakla
      final toSave = messages.length > 80
          ? messages.sublist(messages.length - 80)
          : messages;
      final raw = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString(_prefKeyChatCache, raw);
    } catch (e) {
      debugPrint('[ChatNotifier] Save cache error: $e');
    }
  }

  void _updateLastSeenId(List<ChatMessage> list) {
    for (final m in list) {
      final idNum = int.tryParse(m.id) ?? 0;
      if (idNum > _lastSeenId) {
        _lastSeenId = idNum;
      }
    }
  }

  /// Serwerden ähli soňky hatlary çekmek
  Future<void> loadMessages() async {
    try {
      final messages = await _apiService.fetchMessages(limit: 60);
      if (messages.isNotEmpty) {
        state = messages;
        _updateLastSeenId(messages);
        await _saveCachedMessages(messages);
      }
    } catch (e) {
      debugPrint('[ChatNotifier] loadMessages error: $e');
    }
  }

  /// Polling: Diňe täze gelen hatlary almak
  Future<void> _pollNewMessages() async {
    if (_lastSeenId == 0) {
      await loadMessages();
      return;
    }
    try {
      final newMessages = await _apiService.fetchNewMessages(_lastSeenId);
      if (newMessages.isNotEmpty) {
        // Gaýtalanýan hat bolmazlygy üçin barla
        final existingIds = state.map((m) => m.id).toSet();
        final filtered = newMessages.where((m) => !existingIds.contains(m.id)).toList();

        if (filtered.isNotEmpty) {
          final updated = [...state, ...filtered];
          state = updated;
          _updateLastSeenId(filtered);
          await _saveCachedMessages(updated);
        }
      }
    } catch (_) {
      // Bökdençsiz dowam etsin
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Mesaj göndermek
  Future<bool> sendMessage({
    required String senderName,
    required String senderRole,
    required String message,
  }) async {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = ChatMessage(
      id: tempId,
      senderName: senderName,
      senderPhone: '',
      message: message,
      timestamp: DateTime.now(),
      role: senderRole,
    );

    // Ekrana derrew çykar
    state = [...state, localMsg];

    final ok = await _apiService.sendMessage(
      senderName: senderName,
      senderRole: senderRole,
      message: message,
    );

    if (ok) {
      // Serwerdäki iň soňky täze hatlary derrew sorap al
      await _pollNewMessages();
    } else {
      // Ugradyp bolmadyk bolsa arassala
      state = state.where((m) => m.id != tempId).toList();
    }
    return ok;
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return ChatNotifier(apiService);
});
