import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/announcements/presentation/screens/announcements_feed_screen.dart';
import 'package:topar_115/features/chat/presentation/screens/group_chat_screen.dart';
import 'package:topar_115/features/settings/presentation/screens/settings_screen.dart';
import 'package:topar_115/features/subjects/presentation/screens/subjects_screen.dart';
import 'package:topar_115/features/timetable/presentation/screens/timetable_screen.dart';
import 'package:topar_115/l10n/app_localizations.dart';

// ── Active Tab Provider ───────────────────────────────────────────────────────

final activeTabProvider = StateProvider<int>((ref) => 0);

// ── Main Navigation Shell With Horizontal Swipe ───────────────────────────────

/// Root scaffold that hosts the 5-tab [NavigationBar] and [PageView].
///
/// Supports both bottom bar tap navigation and smooth horizontal swipe (saga-sola kaydyrma).
///
/// Tabs:
///   0 — Duýduryşlar (Announcements Feed)
///   1 — Topar Chat (Group Chat)
///   2 — Raspisanie (Timetable)
///   3 — Sapak Temalary (Subjects & Lessons)
///   4 — Sazlamalar (Settings)
class FifteenScaffold extends ConsumerStatefulWidget {
  const FifteenScaffold({super.key});

  @override
  ConsumerState<FifteenScaffold> createState() => _FifteenScaffoldState();
}

class _FifteenScaffoldState extends ConsumerState<FifteenScaffold> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: ref.read(activeTabProvider));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
            Gap(10),
            Text('Çykmak isleýärsiňizmi?'),
          ],
        ),
        content: const Text(
          'Hakykatdan hem programmadan çykmak isleýärsiňizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ýok'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hawa, Çyk'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeTabProvider);
    final cs = Theme.of(context).colorScheme;

    ref.listen<int>(activeTabProvider, (previous, next) {
      if (_pageController.hasClients && _pageController.page?.round() != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (activeTab != 0) {
          ref.read(activeTabProvider.notifier).state = 0;
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          await _showExitConfirmationDialog(context);
        }
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: PageView(
          controller: _pageController,
          onPageChanged: (i) {
            HapticUtils.light();
            ref.read(activeTabProvider.notifier).state = i;
          },
          children: const [
            _KeepAlivePage(child: AnnouncementsFeedScreen()),
            _KeepAlivePage(child: GroupChatScreen()),
            _KeepAlivePage(child: TimetableScreen()),
            _KeepAlivePage(child: SubjectsScreen()),
            _KeepAlivePage(child: SettingsScreen()),
          ],
        ),
        bottomNavigationBar: _FifteenNavBar(
          activeIndex: activeTab,
          onTap: (i) {
            HapticUtils.light();
            ref.read(activeTabProvider.notifier).state = i;
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ),
    );
  }
}

// ── Keep Alive Page Wrapper ───────────────────────────────────────────────────

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
