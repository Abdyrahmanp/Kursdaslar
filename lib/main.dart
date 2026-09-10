import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/app/theme/app_theme.dart';
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

  // Step 2: Firebase.initializeApp() goes here after adding google-services.json.

  runApp(
    const ProviderScope(
      child: _FifteenRoot(),
    ),
  );
}

/// Minimal root widget that wires [AppTheme] and hands off to [FifteenScaffold].
class _FifteenRoot extends ConsumerWidget {
  const _FifteenRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Fifteen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const FifteenScaffold(),
    );
  }
}
