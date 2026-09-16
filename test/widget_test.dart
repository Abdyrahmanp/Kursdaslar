import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topar_115/app/theme/app_theme.dart';
import 'package:topar_115/features/auth/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen renders header, title, inputs, and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const LoginScreen(),
        ),
      ),
    );

    // Verify main title and separated form elements render correctly.
    expect(find.text('Kursdaşlar'), findsOneWidget);
    expect(find.text('Adyňyz'), findsOneWidget);
    expect(find.text('Familiýaňyz'), findsOneWidget);
    expect(find.text('Telefon belgisi'), findsOneWidget);
    expect(find.text('Ulgama gir'), findsOneWidget);
  });
}
