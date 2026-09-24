import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';

/// The unified settings screen for all users (both Starşy and Normal Students).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hasapdan çykmak'),
        content: const Text(
          'Hakykatdan hem hasabyňyzdan çykmak isleýärsiňizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              HapticUtils.medium();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Çykyş et'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final currentTheme = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final student = authState.currentStudent;
    final isStarshy = authState.isStarshy;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                'Sazlamalar ⚙️',
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
                  title: 'Dil / Language',
                  subtitle: 'Programmanyň görkezilýän dili',
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
                        title: 'English',
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
                const Gap(24),

                // ── Section 2: Görünüş / Tema (Theme) ───────────────────────
                _SectionTitle(
                  icon: Icons.palette_outlined,
                  title: 'Tema / Theme',
                  subtitle: 'Görünüş rejesi (Açyk, Garaňky, Sistem)',
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
                        title: 'Sistem ⚙️',
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
                        title: 'Açyk rejim ☀️',
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
                        title: 'Garaňky rejim 🌙',
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
                  title: 'Howpsuzlyk & Düzgünler',
                  subtitle: 'Gizlinlik syýasaty we ulanyş şertleri',
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
                      title: const Text(
                        'Gizlinlik we Ulanyş Syýasaty',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Maglumatlaryň goralmagy barada',
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

                // ── Logout Button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text(
                      'Hasapdan çykmak',
                      style: TextStyle(
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
                            child: const Text(
                              'Kursdaşlar v2.4.0',
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
