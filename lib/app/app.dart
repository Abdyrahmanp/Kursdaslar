import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/app/theme/app_theme.dart';

// ── Theme State Providers ─────────────────────────────────────────────────────

/// Controls the current [ThemeMode] (light / dark / system).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Controls the active UI locale (Turkmen or English).
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

// ── Root Application Widget ───────────────────────────────────────────────────

/// Root widget for the "Fifteen" application.
///
/// Wraps [MaterialApp] with Riverpod-driven theme and locale state so that
/// the Sazlamalar (Settings) tab can toggle them live without a rebuild of
/// the entire subtree.
class FifteenApp extends ConsumerWidget {
  const FifteenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kursdaşlar',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // i18n wired in Step 4 (Sazlamalar):
      // locale: ref.watch(localeProvider),
      // localizationsDelegates: AppLocalizations.localizationsDelegates,
      // supportedLocales: AppLocalizations.supportedLocales,
      home: const _AppShell(),
    );
  }
}

// ── App Shell ─────────────────────────────────────────────────────────────────

/// Internal shell — resolved lazily here to avoid a circular import.
/// [FifteenScaffold] is defined in shared/widgets/fifteen_scaffold.dart.
class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    // Resolved via the shared scaffold import in fifteen_scaffold.dart
    return const _FifteenScaffoldProxy();
  }
}

/// Proxy widget that delegates to [FifteenScaffold].
/// Placed here to allow `app.dart` to compile without importing the scaffold
/// directly — the actual import happens in main.dart.
class _FifteenScaffoldProxy extends StatelessWidget {
  const _FifteenScaffoldProxy();

  @override
  Widget build(BuildContext context) {
    // This widget is replaced at the main.dart level — see comments there.
    throw UnimplementedError('Use FifteenScaffold directly from main.dart');
  }
}
