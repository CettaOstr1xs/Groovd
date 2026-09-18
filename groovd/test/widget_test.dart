import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/main.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';
import 'package:groovd/presentation/screens/lists/user_lists_screen.dart';
import 'package:groovd/presentation/screens/profile/adjust_avatar_screen.dart';
import 'package:groovd/presentation/screens/profile/profile_screen.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/data/services/spotify_mock_data.dart';

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

  testWidgets('UserListsScreen renders header and empty state properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: UserListsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CURATED LISTS'), findsWidgets);
    expect(find.text('+ CREATE NEW LIST'), findsOneWidget);
    expect(find.text('NO CURATED LISTS YET'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders avatar and both Wantlist and Curated Lists buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Avatar default monogram 'YOU'
    expect(find.text('YOU'), findsWidgets);

    // Wantlist shortcut button
    expect(find.text('CRITIC WANTLIST // QUEUE'), findsOneWidget);

    // Curated Lists shortcut button directly below
    expect(find.text('CURATED LISTS // ARCHIVES'), findsOneWidget);

    // App bar shows curated lists, wantlist and settings icons
    expect(find.byIcon(Icons.queue_music_outlined), findsWidgets);
    expect(find.byIcon(Icons.bookmark_outline), findsWidgets);
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // User bio statement is rendered below the handle
    expect(find.textContaining('Sonic explorer'), findsOneWidget);

    // Data source badge should NOT be present on the profile screen
    expect(find.textContaining('DATA SOURCE:'), findsNothing);

    // Tap settings icon in AppBar
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Settings modal appears with Light / Dark Mode buttons, Header Banner and Bio
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('HEADER BANNER PHOTO'), findsOneWidget);
    expect(find.text('ADD BACKGROUND PHOTO'), findsOneWidget);
    expect(find.text('CRITIC BIO // SELF-EXPRESSION'), findsOneWidget);
    expect(find.text('DARK MODE'), findsOneWidget);
    expect(find.text('LIGHT MODE'), findsOneWidget);

    // Spotify API config should NOT be present
    expect(find.text('SPOTIFY API CONFIG'), findsNothing);
    expect(find.text('SPOTIFY CLIENT ID'), findsNothing);
    expect(find.text('SPOTIFY CLIENT SECRET'), findsNothing);
  });

  testWidgets('AdjustAvatarScreen renders crop viewport and interactive controls', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync();
    final testFile = File('${tempDir.path}/test_img.png');
    // 1x1 transparent PNG bytes
    testFile.writeAsBytesSync([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: AdjustAvatarScreen(imageFile: testFile),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ADJUST AVATAR'), findsOneWidget);
    expect(find.text('ARRANGE POSITION // 1:1 RATIO'), findsOneWidget);
    expect(find.text('DRAG TO PAN • PINCH TO ZOOM'), findsOneWidget);
    expect(find.text('ROTATE 90°'), findsOneWidget);
    expect(find.text('RE-CENTER'), findsOneWidget);
    expect(find.text('CONFIRM AVATAR // SET PHOTO'), findsOneWidget);

    // Tap rotate
    await tester.tap(find.text('ROTATE 90°'));
    await tester.pump();

    // Tap zoom in
    await tester.tap(find.byTooltip('Zoom In'));
    await tester.pump();

    // Clean up
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('MusicDetailScreen renders Critical Reviews and More by Artist exploration shelf', (WidgetTester tester) async {
    final blonde = SpotifyMockData.trendingAlbums.firstWhere((item) => item.id == 'album_blonde');

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MusicDetailScreen(item: blonde),
        ),
      ),
    );

    // Allow initial data to resolve and entrance animations to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify album title and artist
    expect(find.text('BLONDE'), findsWidgets);
    expect(find.text('FRANK OCEAN'), findsWidgets);

    // Verify Critical Reviews section header
    expect(find.text('CRITICAL REVIEWS'), findsOneWidget);

    // Verify More by Artist section is rendered below reviews
    expect(find.text('MORE BY FRANK OCEAN'), findsOneWidget);

    // Verify other Frank Ocean pieces (NIGHTS) appear in the shelf
    expect(find.text('NIGHTS'), findsOneWidget);

    // Ensure no exceptions or overflows occurred
    expect(tester.takeException(), isNull);
  });
}

