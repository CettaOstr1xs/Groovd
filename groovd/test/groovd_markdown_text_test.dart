import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/presentation/widgets/groovd_markdown_text.dart';

void main() {
  group('GroovdMarkdownText', () {
    testWidgets('renders bold and italic styled TextSpans', (WidgetTester tester) async {
      const markdown = 'This is **bold album** and this is *tilted track*.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroovdMarkdownText(text: markdown),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      expect(richTextFinder, findsWidgets);

      final richText = tester.widget<RichText>(richTextFinder.first);
      final textSpan = richText.text as TextSpan;
      expect(textSpan.toPlainText(), contains('This is bold album and this is tilted track.'));

      // Check for bold span
      bool hasBold = false;
      bool hasItalic = false;

      textSpan.visitChildren((span) {
        if (span is TextSpan) {
          if (span.text == 'bold album' && span.style?.fontWeight == FontWeight.w800) {
            hasBold = true;
          }
          if (span.text == 'tilted track' && span.style?.fontStyle == FontStyle.italic) {
            hasItalic = true;
          }
        }
        return true;
      });

      expect(hasBold, isTrue, reason: 'Expected to find bold span for bold album');
      expect(hasItalic, isTrue, reason: 'Expected to find italic span for tilted track');
    });

    testWidgets('uses Space Mono font family for base text style', (WidgetTester tester) async {
      const markdown = 'Groovd AI music critique';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroovdMarkdownText(text: markdown),
          ),
        ),
      );

      final richTextFinder = find.byType(RichText);
      final richText = tester.widget<RichText>(richTextFinder.first);
      final textSpan = richText.text as TextSpan;
      expect(textSpan.style?.fontFamily, contains('SpaceMono'));
    });

    testWidgets('renders headers and bullet lists properly', (WidgetTester tester) async {
      const markdown = '### THE VERDICT\n- Track 1: Masterpiece\n- Track 2: Skip';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroovdMarkdownText(text: markdown),
          ),
        ),
      );

      expect(find.textContaining('THE VERDICT'), findsOneWidget);
      expect(find.textContaining('Track 1: Masterpiece', findRichText: true), findsOneWidget);
      expect(find.textContaining('Track 2: Skip', findRichText: true), findsOneWidget);
    });

    testWidgets('handles incomplete streaming markdown without throwing', (WidgetTester tester) async {
      const incomplete = 'Currently streaming **Incomplete bold and *tilt';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroovdMarkdownText(text: incomplete),
          ),
        ),
      );

      expect(find.byType(GroovdMarkdownText), findsOneWidget);
    });

    testWidgets('strips unicode emojis from text before rendering', (WidgetTester tester) async {
      const textWithEmojis = 'This album is pure fire! 🔥🎸 Masterpiece vibes 💀';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GroovdMarkdownText(text: textWithEmojis),
          ),
        ),
      );

      expect(find.byType(GroovdMarkdownText), findsOneWidget);
      expect(find.textContaining('🔥', findRichText: true), findsNothing);
      expect(find.textContaining('🎸', findRichText: true), findsNothing);
      expect(find.textContaining('💀', findRichText: true), findsNothing);
    });
  });
}
