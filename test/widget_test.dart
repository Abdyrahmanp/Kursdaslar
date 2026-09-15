import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topar_115/app/theme/app_theme.dart';
import 'package:topar_115/shared/widgets/fifteen_scaffold.dart';

void main() {
  testWidgets('FifteenScaffold renders 4-tab NavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const FifteenScaffold(),
        ),
      ),
    );

    // Verify the NavigationBar destinations are present.
    expect(find.text('Duyurular'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('AI Tutor'), findsOneWidget);
    expect(find.text('Sazlamalar'), findsOneWidget);
  });
}
