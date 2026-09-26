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
  final Ref? _ref;
  Timer? _pollTimer;
  int _lastSeenId = 0;
  static const String _prefKeyChatCache = 'topar115_cached_chat_messages_v1';

  ChatNotifier(this._apiService, [this._ref]) : super(const []) {
    _initChat();
  }

  Future<void> _initChat() async {
    // 1. Täze giren ulanyjy üçin chat alany boş başlaýar (öňki hatlary awtomatiki indirmez)
    state = const [];
    // 2. Serwerdäki iň soňky hatyň ID-sini alýarys (diňe şondan soňky täze hatlary real-wagtda görkezmek üçin)
    await _initLatestId();
    // 3. 3 sekuntdan bir täze hat barlygyny barla
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.chatPollInterval, (_) {
      _pollNewMessages();
    });
  }

  /// Serwerdäki iň soňky hatyň ID-sini anyklamak (chat alanyna goşmazdan)
  Future<void> _initLatestId() async {
    try {
      final latest = await _apiService.fetchMessages(limit: 1);
      if (latest.isNotEmpty) {
        final lastMsg = latest.last;
        _lastSeenId = int.tryParse(lastMsg.id) ?? 0;
        _ref?.read(hasOlderMessagesProvider.notifier).state = true;
      } else {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
      }
    } catch (e) {
      debugPrint('[ChatNotifier] _initLatestId error: $e');
      _ref?.read(hasOlderMessagesProvider.notifier).state = true;
    }
  }

  /// Lokal ýatdan saklanan hatlary okamak (islege görä)
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

  /// Hatlary lokal ýatda saklamak
  Future<void> _saveCachedMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

  /// Öňki ýazyşmalary ýüklemek (10 hat limit bilen)
  Future<void> loadOlderMessages() async {
    try {
      // Eger chat alany entek boş bolsa: iň soňky 10 haty ýükle
      if (state.isEmpty) {
        final messages = await _apiService.fetchMessages(limit: 10);
        if (messages.isNotEmpty) {
          state = messages;
          _updateLastSeenId(messages);
          if (messages.length < 10) {
            _ref?.read(hasOlderMessagesProvider.notifier).state = false;
          } else {
            _ref?.read(hasOlderMessagesProvider.notifier).state = true;
          }
        } else {
          _ref?.read(hasOlderMessagesProvider.notifier).state = false;
        }
        return;
      }

      // Eger hatlar bar bolsa: iň birinji (iň köne) hatdan öňki 10 haty getir
      final oldestMsg = state
          .where((m) => !m.isPending && int.tryParse(m.id) != null)
          .firstOrNull;
      if (oldestMsg == null) {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
        return;
      }

      final beforeId = int.parse(oldestMsg.id);
      final older = await _apiService.fetchOlderMessages(beforeId: beforeId, limit: 10);
      if (older.isNotEmpty) {
        final existingIds = state.map((m) => m.id).toSet();
        final filtered = older.where((m) => !existingIds.contains(m.id)).toList();
        if (filtered.isNotEmpty) {
          state = [...filtered, ...state];
        }
      }
      if (older.length < 10) {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
      }
    } catch (e) {
      debugPrint('[ChatNotifier] loadOlderMessages error: $e');
    }
  }

  /// Polling: Diňe täze gelen hatlary almak
  Future<void> _pollNewMessages() async {
    if (_lastSeenId == 0) {
      await _initLatestId();
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

final hasOlderMessagesProvider = StateProvider<bool>((ref) => true);

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final apiService = ref.watch(chatApiServiceProvider);
  return ChatNotifier(apiService, ref);
});

