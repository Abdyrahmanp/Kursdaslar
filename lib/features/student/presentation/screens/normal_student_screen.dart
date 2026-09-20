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

final normalTabProvider = StateProvider<int>((ref) => 0);

/// Normal Student View Scaffold.
///
/// Shares the exact 4-tab NavigationBar structure as the Starşy screen ([FifteenScaffold]):
///   0 — Duyduryşlar (Read-only view of notices from Starşy)
///   1 — Chat        (Real-time Group Chat)
///   2 — Sapaklar    (Subjects & Lesson Topics)
///   3 — Sazlamalar  (Settings, Profile, Roster & Logout)
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
          SubjectsScreen(),
          _ProfileSettingsView(),
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
    final announcements = ref.watch(announcementProvider);
    final syncStatus = ref.watch(announcementSyncStatusProvider);
    final currentStudent = authState.currentStudent;
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
                            'Salam, ${currentStudent?.shortName ?? 'Talyp'}! 👋',
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

          // Server Connection Status Pill
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

// ── 2. Settings & Profile View for Normal Students ───────────────────────────

class _ProfileSettingsView extends ConsumerWidget {
  const _ProfileSettingsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final student = authState.currentStudent;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          pinned: true,
          backgroundColor: const Color(0xFF059669),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
            title: Text(
              'Sazlamalar ⚙️',
              style: tt.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Student Profile Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: student?.avatarBg ?? cs.primary,
                      child: Text(
                        student?.initials ?? 'T',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.name ?? 'Talyp',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            student?.phone ?? '',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const Gap(6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Normal Talyp • ${AppConstants.className}',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),

              // Classmates list entry button
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                tileColor: cs.surfaceContainerLow,
                leading: Icon(Icons.groups_rounded, color: cs.primary),
                title: const Text(
                  'Toparadaşlaryň sanawy 👥',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('25 kişilik talyplar sanawyny synlamak'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  HapticUtils.light();
                  _showRosterSheet(context);
                },
              ),
              const Gap(24),

              // Theme Options
              Text(
                'Tema / Display Mode',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(12),
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.light_mode_rounded),
                      title: const Text('Light ☀️'),
                      trailing: currentTheme == ThemeMode.light
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      onTap: () {
                        HapticUtils.light();
                        ref.read(themeModeProvider.notifier).state =
                            ThemeMode.light;
                      },
                    ),
                    Divider(height: 1, color: cs.outlineVariant.withAlpha(60)),
                    ListTile(
                      leading: const Icon(Icons.dark_mode_rounded),
                      title: const Text('Dark 🌙'),
                      trailing: currentTheme == ThemeMode.dark
                          ? Icon(Icons.check_circle_rounded, color: cs.primary)
                          : null,
                      onTap: () {
                        HapticUtils.light();
                        ref.read(themeModeProvider.notifier).state =
                            ThemeMode.dark;
                      },
                    ),
                  ],
                ),
              ),
              const Gap(32),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticUtils.light();
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
                  label: const Text(
                    'Çykyş etmek',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  void _showRosterSheet(BuildContext context) {
    final students = StudentRepository.classStudents;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const Gap(12),
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Gap(16),
            Text(
              'Toparadaşlaryň sanawy 👥',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Gap(4),
            Text(
              '${AppConstants.className} • Jemi ${students.length} talyp',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(12),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: students.length,
                itemBuilder: (ctx, index) {
                  final student = students[index];
                  return RecipientListTile(
                    student: student,
                    isSelected: false,
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
