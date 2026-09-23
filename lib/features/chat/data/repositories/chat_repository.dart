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
      // Pending/failed hatlary cache-e goşma — diňe hakyky hatlary sakla
      final toSave = messages
          .where((m) => !m.isPending && !m.isFailed)
          .toList();
      final limited = toSave.length > 80
          ? toSave.sublist(toSave.length - 80)
          : toSave;
      final raw = jsonEncode(limited.map((m) => m.toJson()).toList());
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
        // Pending hatlary sakla, server'dan gelen confirmed hatlara ekle
        final pendingMsgs = state.where((m) => m.isPending).toList();
        state = [...messages, ...pendingMsgs];
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
        final existingIds = state
            .where((m) => !m.isPending && !m.isFailed)
            .map((m) => m.id)
            .toSet();
        final filtered = newMessages.where((m) => !existingIds.contains(m.id)).toList();

        if (filtered.isNotEmpty) {
          // Pending hatlary sakla
          final pendingMsgs = state.where((m) => m.isPending).toList();
          final withoutPending = state.where((m) => !m.isPending).toList();
          final updated = [...withoutPending, ...filtered, ...pendingMsgs];
          state = updated;
          _updateLastSeenId(filtered);
          final toCache = updated.where((m) => !m.isPending && !m.isFailed).toList();
          await _saveCachedMessages(toCache);
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
    ReplyInfo? replyTo,
  }) async {
    final tempId = 'tmp_${DateTime.now().millisecondsSinceEpoch}';
    final localMsg = ChatMessage(
      id: tempId,
      senderName: senderName,
      senderPhone: '',
      message: message,
      timestamp: DateTime.now(),
      role: senderRole,
      isPending: true,   // ← Gönderilmekte göstergesi
      isFailed: false,
      replyTo: replyTo,
    );

    // Ekrana derrew çykar (optimistic UI) — "pending" halynda
    state = [...state, localMsg];

    final ok = await _apiService.sendMessage(
      senderName: senderName,
      senderRole: senderRole,
      message: message,
      replyToId: replyTo?.messageId,
      replyToName: replyTo?.senderName,
      replyToText: replyTo?.message,
    );

    if (ok) {
      // Serwerdäki täze hatlary al
      final newMessages = await _apiService.fetchNewMessages(_lastSeenId);

      // Temp mesajy aýyr + hakyky serwer hatlaryny BIR GEZEKDE goş (titreme ýok)
      final withoutTemp = state.where((m) => m.id != tempId).toList();
      if (newMessages.isNotEmpty) {
        final existingIds = withoutTemp
            .where((m) => !m.isPending)
            .map((m) => m.id)
            .toSet();
        final filtered =
            newMessages.where((m) => !existingIds.contains(m.id)).toList();
        if (filtered.isNotEmpty) {
          final updated = [...withoutTemp, ...filtered];
          state = updated; // ← ýeke setState: temp gidýär + hakyky gelýär
          _updateLastSeenId(filtered);
          await _saveCachedMessages(updated);
        } else {
          state = withoutTemp;
        }
      } else {
        state = withoutTemp;
      }
    } else {
      // Ugradyp bolmadyk bolsa "failed" haly görkezýär — aýyrmaýar!
      state = state.map((m) {
        if (m.id == tempId) {
          return m.copyWith(isPending: false, isFailed: true);
        }
        return m;
      }).toList();
    }
    return ok;
  }

  /// Başarısız mesajı yeniden gönder
  Future<void> retryMessage(String tempId) async {
    final failedMsg = state.where((m) => m.id == tempId).firstOrNull;
    if (failedMsg == null) return;

    // failed → pending
    state = state.map((m) {
      if (m.id == tempId) return m.copyWith(isPending: true, isFailed: false);
      return m;
    }).toList();

    final ok = await _apiService.sendMessage(
      senderName: failedMsg.senderName,
      senderRole: failedMsg.role,
      message: failedMsg.message,
      replyToId: failedMsg.replyTo?.messageId,
      replyToName: failedMsg.replyTo?.senderName,
      replyToText: failedMsg.replyTo?.message,
    );

    if (ok) {
      // Başarılı — temp'i kaldır, server'dan al
      final newMessages = await _apiService.fetchNewMessages(_lastSeenId);
      final withoutTemp = state.where((m) => m.id != tempId).toList();
      if (newMessages.isNotEmpty) {
        final existingIds = withoutTemp.map((m) => m.id).toSet();
        final filtered = newMessages.where((m) => !existingIds.contains(m.id)).toList();
        final updated = filtered.isNotEmpty ? [...withoutTemp, ...filtered] : withoutTemp;
        state = updated;
        _updateLastSeenId(filtered);
        await _saveCachedMessages(updated);
      } else {
        state = withoutTemp;
      }
    } else {
      // Yine başarısız
      state = state.map((m) {
        if (m.id == tempId) return m.copyWith(isPending: false, isFailed: true);
        return m;
      }).toList();
    }
  }

  /// Mesaj silmek (yerel + server)
  Future<void> deleteMessage(String messageId) async {
    // Önce yerel listeden kaldır (anlık)
    state = state.where((m) => m.id != messageId).toList();
    await _saveCachedMessages(state);

    // Server'dan da sil (başarısız olsa bile yerel zaten silindi)
    if (!messageId.startsWith('tmp_')) {
      await _apiService.deleteMessage(messageId);
    }
  }

  /// Mesaj düzenlemek (yerel + server)
  Future<void> editMessage(String messageId, String newText) async {
    // Yerel listede güncelle
    state = state.map((m) {
      if (m.id == messageId) return m.copyWith(message: newText);
      return m;
    }).toList();
    await _saveCachedMessages(state);

    // Server'da güncelle
    if (!messageId.startsWith('tmp_')) {
      await _apiService.editMessage(messageId, newText);
    }
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return ChatNotifier(apiService);
});

