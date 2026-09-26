import 'package:flutter/material.dart';
import 'package:topar_115/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:topar_115/features/chat/presentation/screens/group_chat_screen.dart';
import 'package:topar_115/features/settings/presentation/screens/settings_screen.dart';
import 'package:topar_115/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:topar_115/features/timetable/presentation/screens/timetable_screen.dart';

// ── Active Tab Provider ───────────────────────────────────────────────────────

final activeTabProvider = StateProvider<int>((ref) => 0);

// ── Main Navigation Shell ─────────────────────────────────────────────────────

/// Root scaffold that hosts the 5-tab [NavigationBar] and [IndexedStack].
///
/// Tabs:
///   0 — Duýduryşlar (Announcements)
///   1 — Topar Chat (Group Chat)
///   2 — Raspisanie (Timetable)
///   3 — Sapak Temalary (Subjects & Lessons)
///   4 — Sazlamalar (Settings)
class FifteenScaffold extends ConsumerWidget {
  const FifteenScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: IndexedStack(
        index: activeTab,
        children: const [
          AnnouncementsScreen(),
          GroupChatScreen(),
          TimetableScreen(),
          SubjectsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _FifteenNavBar(
        activeIndex: activeTab,
        onTap: (i) {
          ref.read(activeTabProvider.notifier).state = i;
        },
      ),
    );
  }
}

// ── Navigation Bar ────────────────────────────────────────────────────────────

class _FifteenNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _FifteenNavBar({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 400),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.campaign_outlined),
          selectedIcon: const Icon(Icons.campaign_rounded),
          label: l.tabAnnouncements,
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
          label: l.tabChat,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_today_outlined),
          selectedIcon: const Icon(Icons.calendar_today_rounded),
          label: l.tabTimetable,
        ),
        NavigationDestination(
          icon: const Icon(Icons.menu_book_outlined),
          selectedIcon: const Icon(Icons.menu_book_rounded),
          label: l.tabSubjects,
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: l.tabSettings,
        ),
      ],
    );
  }
}
