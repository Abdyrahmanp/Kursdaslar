import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/app/theme/app_theme.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/features/auth/presentation/screens/login_screen.dart';
import 'package:topar_115/features/student/presentation/screens/normal_student_screen.dart';
import 'package:topar_115/shared/widgets/fifteen_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — class management app doesn't benefit from landscape.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar so the warm gradient AppBar bleeds to the top.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Load saved locale preference (defaults to Turkmen if not set).
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('kursdaslar_locale') ?? 'tk';
  final savedLocale = Locale(savedLang);

  runApp(
    ProviderScope(
      overrides: [
        localeProvider.overrideWith((ref) => savedLocale),
      ],
      child: const _FifteenRoot(),
    ),
  );
}

/// Root widget that wires [AppTheme], reactive theme toggle, and hands off to
/// the appropriate screen based on authentication & role:
///   • Not logged in  → [LoginScreen]
///   • Starşy (Tuşiýewa Abadan) → [FifteenScaffold] (Full announcement dispatch rights)
///   • Normal Student → [NormalStudentScreen] (View-only announcements & roster)
class _FifteenRoot extends ConsumerWidget {
  const _FifteenRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    Widget homeScreen;
    if (!authState.isInitialized) {
      homeScreen = const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (!authState.isAuthenticated) {
      homeScreen = const LoginScreen();
    } else if (authState.isStarshy) {
      homeScreen = const FifteenScaffold();
    } else {
      homeScreen = const NormalStudentScreen();
    }

    return MaterialApp(
      title: 'Kursdaşlar',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: homeScreen,
    );
  }
}

