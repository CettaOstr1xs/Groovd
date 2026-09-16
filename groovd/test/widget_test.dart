import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/main.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';

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

  testWidgets('WriteReviewModal renders extremely long title without overflow on narrow screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final longTitleItem = MusicItem(
      id: 'synk_complex',
      name: 'SYNK : COMPLAEXITY - 2026 SPECIAL DIGITAL SINGLE - ULTRA EXTENDED VERSION',
      artist: 'aespa & VIRTUOSO SOUND LAB',
      type: MusicType.song,
      coverUrl: '',
      releaseDate: '2026-09-16',
      genres: ['HYPERPOP', 'ELECTRONIC'],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WriteReviewModal.show(context, longTitleItem),
                child: const Text('OPEN MODAL'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN MODAL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LOG YOUR REVIEW'), findsOneWidget);
    // Ensure no overflow errors occurred
    expect(tester.takeException(), isNull);
  });
}
