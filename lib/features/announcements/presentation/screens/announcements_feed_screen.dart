import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/announcements/data/models/announcement_model.dart';
import 'package:topar_115/features/announcements/data/repositories/announcement_repository.dart';
import 'package:topar_115/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/l10n/app_localizations.dart';

class AnnouncementsFeedScreen extends ConsumerWidget {
  const AnnouncementsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final allAnnouncements = ref.watch(announcementProvider);
    final syncStatus = ref.watch(announcementSyncStatusProvider);
    final currentStudent = authState.currentStudent;
    final announcements = authState.isSpecialManager
        ? allAnnouncements
        : allAnnouncements
            .where((a) => a.isRecipient(currentStudent?.id, currentStudent?.phone))
            .toList();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticUtils.light();
          await ref.read(announcementProvider.notifier).syncWithServer();
        },
        color: cs.primary,
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
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
                  AppLocalizations.of(context).announcementsTitle,
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
                              authState.isSpecialManager
                                  ? 'Duýduryşlary dolandyrmak we täze habar ibermek elýeterli.'
                                  : 'Topar ýolbaşçylary tarapyndan ugradylan duýduryşlar.',
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
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Şu wagt täze duýduryş ýok.',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
      ),
      floatingActionButton: authState.canSendAnnouncements
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Täze Duýduryş'),
              onPressed: () {
                HapticUtils.light();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AnnouncementsScreen(),
                  ),
                );
              },
            )
          : null,
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

class _AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;

  const _AnnouncementCard({required this.announcement});

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: announcement.title);
    final contentCtrl = TextEditingController(text: announcement.content);
    bool isUrgent = announcement.isUrgent;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF6366F1)),
              Gap(10),
              Text('Duýduryşy Düzet'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Başlyk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Duýduryş teksti',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gyssagly duýduryş'),
                  value: isUrgent,
                  onChanged: (v) => setModalState(() => isUrgent = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ýatyr'),
            ),
            FilledButton(
              onPressed: () async {
                final newTitle = titleCtrl.text.trim();
                final newContent = contentCtrl.text.trim();
                if (newTitle.isEmpty && newContent.isEmpty) return;
                Navigator.pop(ctx);
                HapticUtils.medium();

                final effectiveTitle = newTitle.isEmpty
                    ? (newContent.length > 30 ? '${newContent.substring(0, 30)}…' : newContent)
                    : newTitle;

                final ok = await ref.read(announcementProvider.notifier).updateAnnouncement(
                      id: announcement.id,
                      title: effectiveTitle,
                      content: newContent,
                      isUrgent: isUrgent,
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Duýduryş üstünlikli üýtgedildi! ✅' : 'Duýduryş ýerli üýtgedildi.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Ýatda sakla'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            Gap(10),
            Text('Duýduryşy Pozmak'),
          ],
        ),
        content: const Text(
          'Hakykatdan hem bu duýduryşy serwerden we programmadan pozmak isleýärsiňizmi?\nBu amal yzyna gaýtarylyp bilinmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticUtils.medium();
              final ok = await ref.read(announcementProvider.notifier).deleteAnnouncement(announcement.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Duýduryş üstünlikli pozuldy! 🗑️' : 'Duýduryş aýryldy.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Hawa, Poz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final canManage = authState.canManageAnnouncements && announcement.isOnline;

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
          // Header row: Sender + Time + Actions
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
              if (canManage) ...[
                const Gap(4),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (val) {
                    if (val == 'edit') {
                      _showEditDialog(context, ref);
                    } else if (val == 'delete') {
                      _showDeleteDialog(context, ref);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.blue, size: 18),
                          Gap(10),
                          Text('Düzetmek'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                          Gap(10),
                          Text('Pozmak', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.public_rounded, size: 12, color: Color(0xFF0284C7)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.priority_high_rounded, size: 12, color: Colors.orange),
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
