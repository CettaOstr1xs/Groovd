import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/main.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';

void main() {
  testWidgets('Groovd app renders main navigation and home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GroovdApp(),
      ),
    );

    // Initial pump and advance animation timers
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify main brand name and tabs render
    expect(find.text('GROOVD'), findsOneWidget);
    expect(find.text('DISPATCH'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
  });

  testWidgets('LoggedReviewsScreen renders with smooth entrance animation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LoggedReviewsScreen(),
          ),
        ),
      ),
    );

    // Verify initial pump
    await tester.pump();
    expect(find.text('MY LOGGED REVIEWS'), findsOneWidget);

    // Let entrance animation complete
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('MY LOGGED REVIEWS'), findsOneWidget);
  });
}
