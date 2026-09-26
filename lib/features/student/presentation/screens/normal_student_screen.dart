import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/announcements/data/models/announcement_model.dart';
import 'package:topar_115/features/announcements/data/repositories/announcement_repository.dart';
import 'package:topar_115/features/announcements/data/repositories/student_repository.dart';
import 'package:topar_115/features/announcements/presentation/widgets/recipient_list_tile.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/features/chat/presentation/screens/group_chat_screen.dart';
import 'package:topar_115/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:topar_115/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:topar_115/features/settings/presentation/screens/settings_screen.dart';

final normalTabProvider = StateProvider<int>((ref) => 0);

/// Normal Student View Scaffold.
///
/// 5-tab NavigationBar:
///   0 — Duyduryşlar (Read-only view of notices from Starşy)
///   1 — Chat        (Real-time Group Chat)
///   2 — Raspisanie  (Timetable)
///   3 — Sapaklar    (Subjects & Lesson Topics)
///   4 — Sazlamalar  (Settings, Profile, Roster & Logout)
class NormalStudentScreen extends ConsumerWidget {
  const NormalStudentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(normalTabProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: IndexedStack(
        index: activeTab,
        children: const [
          _AnnouncementsView(),
          GroupChatScreen(),
          TimetableScreen(),
          SubjectsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab,
        onDestinationSelected: (i) {
          HapticUtils.light();
          ref.read(normalTabProvider.notifier).state = i;
        },
        animationDuration: const Duration(milliseconds: 400),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Duyduryşlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'Raspisanie',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Sapaklar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Sazlamalar',
          ),
        ],
      ),
    );
  }
}
// ── 1. Announcements View for Normal Students ───────────────────────────────

class _AnnouncementsView extends ConsumerWidget {
  const _AnnouncementsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allAnnouncements = ref.watch(announcementProvider);
    final syncStatus = ref.watch(announcementSyncStatusProvider);
    final currentStudent = authState.currentStudent;
    final announcements = authState.isStarshy
        ? allAnnouncements
        : allAnnouncements
            .where((a) => a.isRecipient(currentStudent?.id, currentStudent?.phone))
            .toList();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () async {
        HapticUtils.light();
        await ref.read(announcementProvider.notifier).syncWithServer();
      },
      color: cs.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: cs.primary,
            actions: [
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: syncStatus == SyncStatus.syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
                tooltip: 'Täzele',
                onPressed: () {
                  HapticUtils.light();
                  ref.read(announcementProvider.notifier).syncWithServer();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                'Kursdaşlar 🎓',
                style: tt.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Welcome Header Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(120),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: currentStudent?.avatarBg ?? cs.primary,
                      child: Text(
                        currentStudent?.initials ?? 'T',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salam, ${currentStudent?.name ?? 'Talyp'}! 👋',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Starşy (Tuşiýewa Abadan) tarapyndan ugradylan duýduryşlar.',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onPrimaryContainer.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Server Connection Status Pill (diňe onlaýn bolanda)
          if (syncStatus == SyncStatus.online || syncStatus == SyncStatus.syncing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _buildSyncStatusBanner(context, syncStatus),
              ),
            ),

          // Title Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.mark_chat_unread_rounded, size: 20, color: cs.primary),
                  const Gap(8),
                  Text(
                    'Gelen Duýduryşlar (${announcements.length})',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Announcement Feed
          if (announcements.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Şu wagt täze duýduryş ýok.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = announcements[index];
                    return _AnnouncementCard(announcement: item);
                  },
                  childCount: announcements.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBanner(BuildContext context, SyncStatus status) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case SyncStatus.online:
        bg = const Color(0xFF10B981).withAlpha(25);
        border = const Color(0xFF10B981).withAlpha(80);
        textColor = const Color(0xFF047857);
        icon = Icons.cloud_done_rounded;
        text = 'Onlaýn Serwere Baglanan • Täze duýduryşlar elýeterli';
        break;
      case SyncStatus.syncing:
        bg = const Color(0xFF3B82F6).withAlpha(25);
        border = const Color(0xFF3B82F6).withAlpha(80);
        textColor = const Color(0xFF1D4ED8);
        icon = Icons.sync_rounded;
        text = 'Maglumatlar täzelenýär…';
        break;
      case SyncStatus.offline:
      case SyncStatus.idle:
        bg = const Color(0xFFF59E0B).withAlpha(25);
        border = const Color(0xFFF59E0B).withAlpha(80);
        textColor = const Color(0xFFB45309);
        icon = Icons.cloud_off_rounded;
        text = 'Offline Režim • Ýerli saklanan duýduryşlar';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const Gap(8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: announcement.isUrgent
              ? Colors.orange.withAlpha(150)
              : cs.outlineVariant.withAlpha(60),
          width: announcement.isUrgent ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Sender + Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.star_rounded, size: 16, color: cs.primary),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  announcement.senderName,
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              Text(
                announcement.formattedTime,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withAlpha(140),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Gap(10),

          // Title
          Text(
            announcement.title,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const Gap(6),

          // Content
          Text(
            announcement.content,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withAlpha(220),
              height: 1.45,
            ),
          ),
          const Gap(12),

          // Footer Badges
          Row(
            children: [
              // Online / Alwaysdata Badge
              if (announcement.isOnline)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.public_rounded,
                          size: 12, color: Color(0xFF0284C7)),
                      Gap(4),
                      Text(
                        'Onlaýn Bulut',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 12, color: Colors.green),
                      Gap(4),
                      Text(
                        'GSM SMS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

              // Urgent Badge
              if (announcement.isUrgent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.priority_high_rounded,
                          size: 12, color: Colors.orange),
                      Gap(3),
                      Text(
                        'Gyssagly',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
