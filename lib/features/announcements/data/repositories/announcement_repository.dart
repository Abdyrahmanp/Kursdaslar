import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import '../models/announcement_model.dart';
import '../services/announcement_api_service.dart';

enum SyncStatus {
  idle,
  syncing,
  online,
  offline,
}

/// Provider for API Service instance
final announcementApiServiceProvider = Provider<AnnouncementApiService>((ref) {
  final service = AnnouncementApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for Sync Status (Online, Offline, Syncing)
final announcementSyncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

class AnnouncementNotifier extends StateNotifier<List<Announcement>> {
  final AnnouncementApiService _apiService;
  final Ref _ref;
  Timer? _autoSyncTimer;

  static const String _prefKey = 'topar115_cached_announcements_v1';

  AnnouncementNotifier(this._apiService, this._ref) : super(const []) {
    _initAnnouncements();
  }

  Future<void> _initAnnouncements() async {
    // 1. Önce cache'den göster (offline'da da çalışır)
    await _loadCachedAnnouncements();
    // 2. Sonra serverdan sync
    await syncWithServer();
    // 3. Periyodik sync başlat
    _startAutoSync();
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(AppConstants.autoSyncInterval, (_) {
      syncWithServer(silent: true);
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  // ── Cache ──────────────────────────────────────────────────────────────────

  Future<void> _loadCachedAnnouncements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          final list = decoded
              .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty && state.isEmpty) {
            state = list;
          }
        }
      }
    } catch (e) {
      debugPrint('[AnnouncementNotifier] Load cache error: $e');
    }
  }

  Future<void> _saveCachedAnnouncements(List<Announcement> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Son 50 duyuruyu sakla
      final toSave = list.length > 50 ? list.sublist(0, 50) : list;
      final raw = jsonEncode(toSave.map((a) => a.toJson()).toList());
      await prefs.setString(_prefKey, raw);
    } catch (e) {
      debugPrint('[AnnouncementNotifier] Save cache error: $e');
    }
  }

  // ── Server Sync ────────────────────────────────────────────────────────────

  /// Synchronizes announcements with server.
  Future<void> syncWithServer({bool silent = false}) async {
    if (!silent) {
      _ref.read(announcementSyncStatusProvider.notifier).state =
          SyncStatus.syncing;
    }

    try {
      final remoteList = await _apiService.fetchAnnouncements();
      if (remoteList.isNotEmpty) {
        state = remoteList;
        await _saveCachedAnnouncements(remoteList);
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.online;
      } else {
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.online;
      }
    } catch (e) {
      debugPrint('[AnnouncementNotifier] sync error: $e');
      _ref.read(announcementSyncStatusProvider.notifier).state =
          SyncStatus.offline;
      // Cache'deki verileri koru — boşaltma!
    }
  }

  /// Sends announcement to server and prepends to local state.
  Future<bool> sendOnlineAnnouncement({
    required String content,
    String? title,
    String senderName = 'Tuşiýewa Abadan (Starşy)',
    String senderPhone = '+993 61 76 28 19',
    int recipientCount = 25,
    bool isUrgent = false,
  }) async {
    final effectiveTitle = title ??
        (content.length > 30 ? '${content.substring(0, 30)}…' : content);

    // Optimistically create local instance
    final localItem = Announcement(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: effectiveTitle,
      content: content,
      senderName: senderName,
      senderPhone: senderPhone,
      timestamp: DateTime.now(),
      recipientCount: recipientCount,
      isUrgent: isUrgent,
      isOnline: true,
    );

    try {
      final ok = await _apiService.postAnnouncement(
        content: content,
        title: effectiveTitle,
        senderName: senderName,
        senderRole: isUrgent ? 'starshy' : 'student',
        isUrgent: isUrgent,
      );

      if (ok) {
        state = [localItem, ...state];
        await _saveCachedAnnouncements(state);
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.online;
      } else {
        state = [localItem, ...state];
        await _saveCachedAnnouncements(state);
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.offline;
      }
      return ok;
    } catch (e) {
      debugPrint('[AnnouncementNotifier] Failed to send online: $e');
      state = [localItem, ...state];
      await _saveCachedAnnouncements(state);
      _ref.read(announcementSyncStatusProvider.notifier).state =
          SyncStatus.offline;
      return false;
    }
  }

  /// Offline / GSM method fallback to add locally.
  void addAnnouncement({
    required String content,
    int recipientCount = 25,
    bool isUrgent = false,
  }) {
    final title =
        content.length > 30 ? '${content.substring(0, 30)}…' : content;

    final newAnn = Announcement(
      id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: content,
      senderName: 'Tuşiýewa Abadan (Starşy)',
      senderPhone: '+993 61 76 28 19',
      timestamp: DateTime.now(),
      recipientCount: recipientCount,
      isUrgent: isUrgent,
      isOnline: false,
    );

    state = [newAnn, ...state];
    _saveCachedAnnouncements(state);
  }
}

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, List<Announcement>>((ref) {
  final apiService = ref.watch(announcementApiServiceProvider);
  return AnnouncementNotifier(apiService, ref);
});
