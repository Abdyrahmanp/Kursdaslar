import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:topar_115/features/settings/presentation/screens/settings_screen.dart';

// ── Active Tab Provider ───────────────────────────────────────────────────────

final activeTabProvider = StateProvider<int>((ref) => 0);

// ── Main Navigation Shell ─────────────────────────────────────────────────────

/// Root scaffold that hosts the 4-tab [NavigationBar] and [IndexedStack].
///
/// Tabs:
///   0 — Announcements & SMS Dispatcher  (Step 1 — active)
///   1 — Group Chat                       (Step 2 — stub)
///   2 — AI Tutor & Quizzes              (Step 3 — stub)
///   3 — Sazlamalar (Settings)           (Step 4 — stub)
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
          _StubScreen(
            title: 'Group Chat',
            subtitle: 'Realtime discussion — coming in Step 2',
            icon: Icons.chat_bubble_rounded,
            color: Color(0xFF4A90E2),
          ),
          _StubScreen(
            title: 'AI Tutor & Quizzes',
            subtitle: 'Gemini-powered study assistant — coming in Step 3',
            icon: Icons.psychology_rounded,
            color: Color(0xFF8B5CF6),
          ),
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
    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: onTap,
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
          icon: Icon(Icons.psychology_outlined),
          selectedIcon: Icon(Icons.psychology_rounded),
          label: 'AI Tutor',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Sazlamalar',
        ),
      ],
    );
  }
}

// ── Stub Screens ──────────────────────────────────────────────────────────────

class _StubScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StubScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: tt.titleLarge?.copyWith(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withAlpha(180)],
                  ),
                ),
              ),
            ),
            backgroundColor: color,
          ),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: color),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withAlpha(60)),
                      ),
                      child: Text(
                        '🚧  Under Construction',
                        style: tt.labelLarge?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
