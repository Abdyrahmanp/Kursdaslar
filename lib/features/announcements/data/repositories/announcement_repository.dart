import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  AnnouncementNotifier(this._apiService, this._ref)
      : super(_initialAnnouncements) {
    // Automatically attempt initial sync with Alwaysdata server
    syncWithServer();
    // Start periodic background sync check
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

  static final List<Announcement> _initialAnnouncements = [];

  /// Synchronizes announcements with Alwaysdata Cloud server.
  Future<void> syncWithServer({bool silent = false}) async {
    if (!silent) {
      _ref.read(announcementSyncStatusProvider.notifier).state =
          SyncStatus.syncing;
    }

    try {
      final remoteList = await _apiService.fetchAnnouncements();
      if (remoteList.isNotEmpty) {
        state = remoteList;
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
    }
  }

  /// Sends announcement to Alwaysdata server and prepends to local state.
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
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.online;
      } else {
        state = [localItem, ...state];
        _ref.read(announcementSyncStatusProvider.notifier).state =
            SyncStatus.offline;
      }
      return ok;
    } catch (e) {
      debugPrint('[AnnouncementNotifier] Failed to send online, saved locally: $e');
      state = [localItem, ...state];
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
  }
}

final announcementProvider =
    StateNotifierProvider<AnnouncementNotifier, List<Announcement>>((ref) {
  final apiService = ref.watch(announcementApiServiceProvider);
  return AnnouncementNotifier(apiService, ref);
});
