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
    // 1. Öňki ýerli ýatda saklanan (cache) hatlary derrew ekrana çykar (boş bolmasyn)
    await _loadCachedMessages();

    // 2. Eger ýerli ýat entek boş bolsa, serwerden iň soňky hatlary çek
    if (state.isEmpty) {
      try {
        final initial = await _apiService.fetchMessages(limit: 15);
        final valid = _filterExpiredMessages(initial);
        if (valid.isNotEmpty) {
          state = valid;
          _updateLastSeenId(valid);
          await _saveCachedMessages(valid);
        }
      } catch (e) {
        debugPrint('[ChatNotifier] Initial fetch error: $e');
      }
    }

    // 3. Serwerdäki iň soňky hatyň ID-sini alýarys
    await _initLatestId();

    // 4. Täze hatlary soramak üçin polling başla
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.chatPollInterval, (_) {
      _pollNewMessages();
    });
  }

  /// 7 günden geçen hatlary arassalamak (Möhleti geçen hatlar görkezilmeýär)
  List<ChatMessage> _filterExpiredMessages(List<ChatMessage> list) {
    return list.where((m) => !m.isExpired).toList();
  }

  /// Serwerdäki iň soňky hatyň ID-sini anyklamak
  Future<void> _initLatestId() async {
    try {
      final latest = await _apiService.fetchMessages(limit: 1);
      final valid = _filterExpiredMessages(latest);
      if (valid.isNotEmpty) {
        final lastMsg = valid.last;
        final idNum = int.tryParse(lastMsg.id) ?? 0;
        if (idNum > _lastSeenId) {
          _lastSeenId = idNum;
        }
        _ref?.read(hasOlderMessagesProvider.notifier).state = true;
      } else if (latest.isEmpty) {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
      }
    } catch (e) {
      debugPrint('[ChatNotifier] _initLatestId error: $e');
      _ref?.read(hasOlderMessagesProvider.notifier).state = true;
    }
  }

  /// Lokal ýatdan saklanan hatlary okamak
  Future<void> _loadCachedMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefKeyChatCache);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson);
        if (decoded is List) {
          final rawList = decoded
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList();
          final validList = _filterExpiredMessages(rawList);

          if (validList.length != rawList.length) {
            // Möhleti geçen hatlar arassalandy, täze halyny ýatda sakla
            await _saveCachedMessages(validList);
          }

          if (validList.isNotEmpty) {
            state = validList;
            _updateLastSeenId(validList);
          }
        }
      }
    } catch (e) {
      debugPrint('[ChatNotifier] Load cache error: $e');
    }
  }

  /// Hatlary lokal ýatda saklamak (diňe möhleti geçmedik 7 günlik hatlar)
  Future<void> _saveCachedMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _filterExpiredMessages(
        messages.where((m) => !m.isPending && !m.isFailed).toList(),
      );
      final limited = toSave.length > 100
          ? toSave.sublist(toSave.length - 100)
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

  /// Öňki ýazyşmalary ýüklemek (yzygiderli 10 hat limit bilen)
  Future<void> loadOlderMessages() async {
    try {
      // Eger chat alany boş bolsa: iň soňky 10 haty ýükle
      if (state.isEmpty) {
        final messages = await _apiService.fetchMessages(limit: 10);
        final valid = _filterExpiredMessages(messages);
        if (valid.isNotEmpty) {
          state = valid;
          _updateLastSeenId(valid);
          await _saveCachedMessages(valid);
          _ref?.read(hasOlderMessagesProvider.notifier).state = messages.length >= 10;
        } else {
          _ref?.read(hasOlderMessagesProvider.notifier).state = false;
        }
        return;
      }

      // Eger hatlar bar bolsa: iň kiçi (iň köne) hatyň ID-sini tap
      int? minId;
      for (final m in state) {
        final parsed = int.tryParse(m.id);
        if (parsed != null && !m.isPending) {
          if (minId == null || parsed < minId) {
            minId = parsed;
          }
        }
      }

      if (minId == null || minId <= 1) {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
        return;
      }

      final older = await _apiService.fetchOlderMessages(beforeId: minId, limit: 10);
      final validOlder = _filterExpiredMessages(older);

      if (validOlder.isNotEmpty) {
        final existingIds = state.map((m) => m.id).toSet();
        final newItems = validOlder.where((m) => !existingIds.contains(m.id)).toList();
        if (newItems.isNotEmpty) {
          final merged = [...newItems, ...state];
          // Tertibi: iň köneden iň täzä tarap
          merged.sort((a, b) {
            final aId = int.tryParse(a.id);
            final bId = int.tryParse(b.id);
            if (aId != null && bId != null) return aId.compareTo(bId);
            return a.timestamp.compareTo(b.timestamp);
          });
          state = merged;
          await _saveCachedMessages(merged);
        }
      }

      // Eger serwerden gelen hat sany 10-dan az bolsa ýa-da möhleti geçen bolsa, indiki gezek öňki ýok
      if (older.length < 10) {
        _ref?.read(hasOlderMessagesProvider.notifier).state = false;
      } else {
        _ref?.read(hasOlderMessagesProvider.notifier).state = true;
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
        final filtered = _filterExpiredMessages(
          newMessages.where((m) => !existingIds.contains(m.id)).toList(),
        );

        if (filtered.isNotEmpty) {
          // Pending hatlary sakla, möhleti geçenleri arassala
          final pendingMsgs = state.where((m) => m.isPending).toList();
          final withoutPending = _filterExpiredMessages(
            state.where((m) => !m.isPending).toList(),
          );
          final updated = [...withoutPending, ...filtered, ...pendingMsgs];
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

