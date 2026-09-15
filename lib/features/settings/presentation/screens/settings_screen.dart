import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';

/// The primary settings screen for "Fifteen" (Step 4 — Sazlamalar).
///
/// Provides live reactive configuration for:
///   • Application language (Turkmen 🇹🇲 / English 🇬🇧).
///   • Theme mode (Light ☀️ / Dark 🌙 / System ⚙️).
///   • System information & status.
///
/// Note: AppLocalizations (i18n) will be wired in Step 4.
/// Strings are currently hardcoded with // TODO: i18n markers.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF059669),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Sazlamalar ⚙️', // TODO: i18n — l10n.settingsTitle
                style: tt.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                  ),
                ),
              ),
            ),
          ),

          // ── Settings Body ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── App Card Banner ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [cs.primary, cs.tertiary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '🎓',
                            style: TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              AppConstants.className, // TODO: i18n — l10n.groupSubtitle
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Section 1: Language Settings ────────────────────────────
                _SectionTitle(
                  icon: Icons.language_rounded,
                  title: 'Dil / Language', // TODO: i18n
                  subtitle: 'Choose the display language', // TODO: i18n
                ),
                const Gap(12),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _LanguageTile(
                        flag: '🇹🇲',
                        title: 'Türkmençe', // TODO: i18n
                        subtitle: 'Türkmen dili',
                        isSelected: currentLocale.languageCode == 'tk',
                        onTap: () {
                          HapticUtils.light();
                          ref.read(localeProvider.notifier).state =
                              const Locale('tk');
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: cs.outlineVariant.withAlpha(60),
                      ),
                      _LanguageTile(
                        flag: '🇬🇧',
                        title: 'English', // TODO: i18n
                        subtitle: 'English language',
                        isSelected: currentLocale.languageCode == 'en',
                        onTap: () {
                          HapticUtils.light();
                          ref.read(localeProvider.notifier).state =
                              const Locale('en');
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(28),

                // ── Section 2: Theme Settings ───────────────────────────────
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  title: 'Tema / Theme', // TODO: i18n
                  subtitle: 'Light, dark or system default', // TODO: i18n
                ),
                const Gap(12),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _ThemeTile(
                        icon: Icons.light_mode_rounded,
                        title: 'Light ☀️', // TODO: i18n
                        isSelected: currentTheme == ThemeMode.light,
                        onTap: () {
                          HapticUtils.light();
                          ref.read(themeModeProvider.notifier).state =
                              ThemeMode.light;
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: cs.outlineVariant.withAlpha(60),
                      ),
                      _ThemeTile(
                        icon: Icons.dark_mode_rounded,
                        title: 'Dark 🌙', // TODO: i18n
                        isSelected: currentTheme == ThemeMode.dark,
                        onTap: () {
                          HapticUtils.light();
                          ref.read(themeModeProvider.notifier).state =
                              ThemeMode.dark;
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: cs.outlineVariant.withAlpha(60),
                      ),
                      _ThemeTile(
                        icon: Icons.brightness_auto_rounded,
                        title: 'System ⚙️', // TODO: i18n
                        isSelected: currentTheme == ThemeMode.system,
                        onTap: () {
                          HapticUtils.light();
                          ref.read(themeModeProvider.notifier).state =
                              ThemeMode.system;
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(32),

                // ── Version Footer ──────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text(
                        '${AppConstants.appName} • v1.0.0', // TODO: i18n — l10n.appVersion
                        style: tt.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(140),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        'Dual-Mode (Offline GSM + Online Realtime)',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const Gap(10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(
        title,
        style: tt.titleSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isSelected
            ? Container(
                key: const ValueKey('checked'),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : const SizedBox.shrink(key: ValueKey('unchecked')),
      ),
    );
  }
}

// ── Theme Tile ────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: tt.titleSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: cs.primary)
          : null,
    );
  }
}
