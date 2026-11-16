import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/presentation/widgets/groovd_markdown_text.dart';
import 'package:groovd/presentation/widgets/scramble_text.dart';

void main() {
  testWidgets('ScrambleText animates smoothly and resolves into GroovdMarkdownText on completion', (WidgetTester tester) async {
    bool completed = false;
    const testText = 'GROOVD AI UNCOMPROMISING CRITIQUE';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrambleText(
            text: testText,
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    // Initial pump at t=0
    await tester.pump();
    expect(completed, isFalse);

    // Mid-flight pump at t=500ms: Scramble in progress
    await tester.pump(const Duration(milliseconds: 500));
    expect(completed, isFalse);

    // Complete animation at t=1000ms (+100ms buffer)
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(completed, isTrue);
    expect(find.byType(GroovdMarkdownText), findsOneWidget);
    expect(find.text(testText, findRichText: true), findsOneWidget);
  });

  testWidgets('ScrambleText handles empty text without errors', (WidgetTester tester) async {
    bool completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrambleText(
            text: '',
            duration: const Duration(milliseconds: 300),
            onComplete: () {
              completed = true;
            },
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(completed, isTrue);
  });
}
