import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/network/byethost_http_client.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/l10n/app_localizations.dart';

/// The unified settings screen for all users (both Starşy and Normal Students).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showContactDialog(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final student = authState.currentStudent;
    final isStarshy = authState.isStarshy;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ContactDialogContent(
        studentName: student?.name ?? '',
        studentPhone: student?.phone ?? '',
        isStarshy: isStarshy,
      ),
    );

    if (result == true && context.mounted) {
      HapticUtils.medium();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              Gap(10),
              Expanded(
                child: Text(
                  'Hatyňyz döredijä üstünlikli ugradyldy! Sag boluň. 🎉',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.settingsLogoutTitle),
        content: Text(
          l.settingsLogoutBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.settingsLogoutCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              HapticUtils.medium();
              ref.read(authProvider.notifier).logout();
            },
            child: Text(l.settingsLogoutConfirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final student = authState.currentStudent;
    final isStarshy = authState.isStarshy;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
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
                l.settingsTitle,
                style: tt.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── User Profile Banner ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: isStarshy
                            ? const Color(0xFFF59E0B)
                            : (student?.avatarBg ?? cs.primary),
                        child: Text(
                          isStarshy
                              ? 'TA'
                              : (student?.initials ?? 'T'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isStarshy
                                  ? 'Tuşiýewa Abadan'
                                  : (student?.name ?? 'Talyp'),
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              isStarshy
                                  ? '+993 61 76 28 19'
                                  : (student?.phone ?? ''),
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
                                color: isStarshy
                                    ? const Color(0xFFFEF3C7)
                                    : cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isStarshy
                                    ? 'Topar Starşysy ⭐ • ${AppConstants.className}'
                                    : 'Topar Talyby 🎓 • ${AppConstants.className}',
                                style: tt.labelSmall?.copyWith(
                                  color: isStarshy
                                      ? const Color(0xFFB45309)
                                      : cs.onPrimaryContainer,
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
                const Gap(24),

                // ── Section 1: Dil Saýlawy (Language) ───────────────────────
                _SectionTitle(
                  icon: Icons.language_rounded,
                  title: l.settingsLanguageTitle,
                  subtitle: l.settingsLanguageSubtitle,
                ),
                const Gap(12),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withAlpha(60)),
                  ),
                  child: Column(
                    children: [
                      _LanguageTile(
                        flag: '🇹🇲',
                        title: 'Türkmençe',
                        subtitle: 'Ene dili',
                        isSelected: currentLocale.languageCode == 'tk',
                        onTap: () async {
                          HapticUtils.light();
                          ref.read(localeProvider.notifier).state =
                              const Locale('tk');
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('kursdaslar_locale', 'tk');
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
                        title: 'English',
                        subtitle: 'English language',
                        isSelected: currentLocale.languageCode == 'en',
                        onTap: () async {
                          HapticUtils.light();
                          ref.read(localeProvider.notifier).state =
                              const Locale('en');
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('kursdaslar_locale', 'en');
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Section 2: Görünüş / Tema (Theme) ───────────────────────
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  title: l.settingsThemeTitle,
                  subtitle: l.settingsThemeSubtitle,
                ),
                const Gap(12),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withAlpha(60)),
                  ),
                  child: Column(
                    children: [
                      _ThemeTile(
                        icon: Icons.brightness_auto_rounded,
                        title: l.settingsThemeSystem,
                        isSelected: currentTheme == ThemeMode.system,
                        onTap: () {
                          HapticUtils.light();
                          ref.read(themeModeProvider.notifier).state =
                              ThemeMode.system;
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: cs.outlineVariant.withAlpha(60),
                      ),
                      _ThemeTile(
                        icon: Icons.light_mode_rounded,
                        title: l.settingsThemeLight,
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
                        title: l.settingsThemeDark,
                        isSelected: currentTheme == ThemeMode.dark,
                        onTap: () {
                          HapticUtils.light();
                          ref.read(themeModeProvider.notifier).state =
                              ThemeMode.dark;
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Section 3: Gizlinlik we Syýasat Accordion ─────────────────
                _SectionTitle(
                  icon: Icons.shield_outlined,
                  title: l.settingsPrivacyTitle,
                  subtitle: l.settingsPrivacySubtitle,
                ),
                const Gap(12),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.outlineVariant.withAlpha(60)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.privacy_tip_rounded,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        l.settingsPrivacyExpand,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        l.settingsPrivacyExpandSub,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(160),
                          fontSize: 11.5,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      children: [
                        const Divider(height: 1),
                        const Gap(12),
                        _buildPolicyItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Şahsy Maglumatlaryň Howpsuzlygy:',
                          body:
                              'Bu programmada agzalaryň şahsy maglumatlary (ady, familiýasy, telefon belgisi) diňe Oguz han Inžener-tehnologiýalar uniwersitetiniň 115-nji toparynyň 25 talybynyň arasynda, topar içi aragatnaşygy ýeňilleşdirmek üçin ulanylýar.',
                        ),
                        const Gap(10),
                        _buildPolicyItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Üçünji Taraplara Berilmeýär:',
                          body:
                              'Talyplaryň hiç bir maglumaty programma döredijisi tarapyndan daşarky adamlara ýa-da üçünji taraplara hiç haçan we hiç hili ýagdaýda paýlaşylmaýar we satylmaýar.',
                        ),
                        const Gap(10),
                        _buildPolicyItem(
                          icon: Icons.school_outlined,
                          title: 'Programmanyň Maksady:',
                          body:
                              'Bu programma diňe uniwersitetiň, toparyň we talyplaryň arasyndaky agzybirligi, sapaklaryň we öý işleriniň ýetişigini hem-de umumy okuw hilini kämilleşdirmek maksady bilen döredildi.',
                        ),
                        const Gap(10),
                        _buildPolicyItem(
                          icon: Icons.campaign_outlined,
                          title: 'Ulanyş Şertleri:',
                          body:
                              'Topara degişli möhüm duýduryşlar, ýygnaklar we täze ders temalary topar starşysy we ygtyýarly dolandyryjylar tarapyndan resmi taýdan goşulýar we gözegçilik edilýär.',
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(28),

                // ── Section 4: Habarlaşmak we Teklip (Feedback & Contact) ────
                const _SectionTitle(
                  icon: Icons.mark_email_unread_outlined,
                  title: 'Habarlaşmak we Teklip',
                  subtitle: 'Döredijä hat, sorag ýa-da teklip ugradyň',
                ),
                const Gap(12),
                _FeedbackCard(
                  onTap: () => _showContactDialog(context, ref),
                ),
                const Gap(28),

                // ── Logout Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: Text(
                      l.settingsLogout,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
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
                const Gap(32),

                // ── Programma Döredijisi Karty (Developer Card) ─────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primaryContainer.withAlpha(120),
                        cs.surfaceContainerHighest.withAlpha(140),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cs.primary.withAlpha(60)),
                    boxShadow: [
                      BoxShadow(
                        color: cs.primary.withAlpha(15),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withAlpha(80),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.code_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Döwletgulyýew Abdyrahman',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const Gap(2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Programma Döredijisi 👨‍💻',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),
                      const Divider(height: 1),
                      const Gap(10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Oguz han ETUT • Topar-115',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withAlpha(160),
                              fontSize: 11,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: cs.outlineVariant.withAlpha(70)),
                            ),
                            child: Text(
                              'Kursdaşlar v${AppConstants.appVersion}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Gap(24),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF059669)),
        const Gap(8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF374151),
                height: 1.45,
              ),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
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

    return ListTile(
      onTap: onTap,
      leading: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: cs.onSurfaceVariant,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: cs.primary)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.radio_button_checked_rounded, color: cs.primary)
          : Icon(Icons.radio_button_unchecked_rounded,
              color: cs.onSurfaceVariant.withAlpha(120)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// ── Feedback Card ─────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FeedbackCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticUtils.light();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFF6366F1),
                      size: 22,
                    ),
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Döredijä hat ýazmak',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'Sorag, mesele ýa-da teklip barmy? Göni ugradyň',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(160),
                          fontSize: 11.5,
                        ),
                      ),
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.mail_outline_rounded,
                                size: 12, color: Color(0xFF4F46E5)),
                            Gap(4),
                            Text(
                              'abdyrahmandevoloper@gmail.com',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(120),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Contact Dialog Content ────────────────────────────────────────────────────

class _ContactDialogContent extends StatefulWidget {
  final String studentName;
  final String studentPhone;
  final bool isStarshy;

  const _ContactDialogContent({
    required this.studentName,
    required this.studentPhone,
    required this.isStarshy,
  });

  @override
  State<_ContactDialogContent> createState() => _ContactDialogContentState();
}

class _ContactDialogContentState extends State<_ContactDialogContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;
  String _selectedCategory = '💡 Teklip';
  bool _isSending = false;
  String? _errorMessage;

  static const List<String> _categories = [
    '💡 Teklip',
    '⚠️ Ýalňyşlyk',
    '❓ Sorag',
    '💬 Başga',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentName);
    _phoneController = TextEditingController(text: widget.studentPhone);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _errorMessage = 'Haýyş, hatyňyzyň mazmunyny ýazyň!';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final client = ByethostHttpClient();
    try {
      final response = await client.post(
        Uri.parse(AppConstants.feedbackUrl),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': widget.isStarshy ? 'starshy' : 'student',
          'subject': _selectedCategory,
          'message': message,
        }),
      ).timeout(AppConstants.apiTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSending = false;
          _errorMessage =
              'Serwer bilen baglanyşykda säwlik boldy (${response.statusCode}). Gaýtadan synanyşyň.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Baglanyşyk ýalňyşlygy: Internetiňizi barlaň.';
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Döredijä hat ýazmak',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'abdyrahmandevoloper@gmail.com',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant.withAlpha(180),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed:
                        _isSending ? null : () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Gap(16),

              // Info notice
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFF059669).withAlpha(40)),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF059669),
                    ),
                    Gap(8),
                    Expanded(
                      child: Text(
                        'Hatyňyz gönümel döredijiniň poçtasyna we serwere ygtybarly ugradylar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF047857),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),

              // Category selector
              Text(
                'Hatyň görnüşi:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSel = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    onSelected: _isSending
                        ? null
                        : (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      color: isSel ? cs.primary : cs.onSurfaceVariant,
                    ),
                    backgroundColor: cs.surfaceContainerLow,
                    selectedColor: cs.primaryContainer,
                    side: BorderSide(
                      color:
                          isSel ? cs.primary : cs.outlineVariant.withAlpha(60),
                    ),
                  );
                }).toList(),
              ),
              const Gap(14),

              // Name and Phone
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        labelText: 'Adyňyz',
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      enabled: !_isSending,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        labelStyle: const TextStyle(fontSize: 12),
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // Message field
              TextField(
                controller: _messageController,
                enabled: !_isSending,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Meseleňizi, teklibiňizi ýa-da soragyňyzy giňişleýin ýazyň...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant.withAlpha(140)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.all(14),
                  alignLabelWithHint: true,
                ),
              ),

              if (_errorMessage != null) ...[
                const Gap(6),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.red, size: 16),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              const Gap(18),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSending ? null : () => Navigator.of(context).pop(),
                    child: const Text('Ýatyr'),
                  ),
                  const Gap(10),
                  FilledButton.icon(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_isSending ? 'Iberilýär...' : 'Ugrat'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

