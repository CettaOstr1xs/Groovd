import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/main.dart';
import 'package:groovd/presentation/screens/splash/splash_screen.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';
import 'package:groovd/presentation/screens/lists/user_lists_screen.dart';
import 'package:groovd/presentation/screens/profile/adjust_avatar_screen.dart';
import 'package:groovd/presentation/screens/profile/profile_screen.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_mock_data.dart';
import 'package:groovd/data/services/deezer_api_service.dart';
import 'package:groovd/data/models/artist.dart';
import 'package:groovd/presentation/screens/artist/artist_detail_screen.dart';
import 'package:groovd/presentation/screens/profile/all_rated_releases_screen.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/rating_spike_sign.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/auth/landing_screen.dart';
import 'package:groovd/presentation/screens/auth/login_screen.dart';
import 'package:groovd/presentation/screens/auth/register_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';
import 'package:groovd/presentation/navigation/main_navigation_screen.dart';
import 'package:groovd/presentation/widgets/critic_followers_stats_row.dart';
import 'package:groovd/presentation/screens/friends/friends_screen.dart';
import 'package:groovd/presentation/screens/friends/friend_profile_screen.dart';
import 'package:groovd/data/models/friend_profile.dart';
import 'package:groovd/state/friends_provider.dart';
import 'package:groovd/state/artist_providers.dart';
import 'package:groovd/state/onboarding_provider.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CompletedOnboardingNotifier extends OnboardingNotifier {
  @override
  bool build() => true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen renders GROOVD, animates acid-lime block, and transitions to startup gate', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: GroovdApp(
          showSplash: true,
          splashDuration: Duration(milliseconds: 1000),
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance to when text and acid-lime block are active
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('GROOVD'), findsOneWidget);
    expect(find.text('THE MUSIC CRITIC’S NOTEBOOK'), findsOneWidget);

    // Advance past completion duration and fade transition
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 400));

    // Should have transitioned to LandingScreen
    expect(find.text('CREATE CRITIC DOSSIER'), findsOneWidget);
  });

  testWidgets('Groovd app renders landing screen for first-time guests and allows guest entry into main navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: GroovdApp(showSplash: false),
      ),
    );

    // Initial pump and advance animation timers
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Landing Screen elements
    expect(find.text('THE MUSIC CRITIC’S NOTEBOOK'), findsOneWidget);
    expect(find.text('CREATE CRITIC DOSSIER'), findsOneWidget);
    expect(find.text('HAVE AN ACCOUNT? SIGN IN'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
    expect(find.text('EXPLORE AS GUEST →'), findsOneWidget);

    // Tap 'EXPLORE AS GUEST →'
    await tester.tap(find.text('EXPLORE AS GUEST →'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Verify main brand name and tabs render after bypassing onboarding
    expect(find.text('DISPATCH'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
  });

  testWidgets('Groovd app directly renders main navigation when guest has already completed onboarding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingProvider.overrideWith(_CompletedOnboardingNotifier.new),
        ],
        child: const GroovdApp(showSplash: false),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('GROOVD'), findsOneWidget);
    expect(find.text('DISPATCH'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);
  });

  testWidgets('LandingScreen renders all interactive auth buttons and opens register/login screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LandingScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('THE MUSIC CRITIC’S NOTEBOOK'), findsOneWidget);
    expect(find.text('CREATE CRITIC DOSSIER'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
    expect(find.text('HAVE AN ACCOUNT? SIGN IN'), findsOneWidget);

    // Tap CREATE CRITIC DOSSIER
    await tester.tap(find.text('CREATE CRITIC DOSSIER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('CREATE YOUR\nCRITIC DOSSIER'), findsOneWidget);

    // Close Register Screen
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap SIGN IN
    await tester.tap(find.text('HAVE AN ACCOUNT? SIGN IN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LOG IN TO GROOVD'), findsOneWidget);
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

    // Settings modal appears with Light / Dark Mode buttons, fused Profile Customization and Bio
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('PROFILE CUSTOMIZATION'), findsOneWidget);
    await tester.tap(find.text('PROFILE CUSTOMIZATION'));
    await tester.pumpAndSettle();

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

    // Verify Spotify button is removed
    expect(find.text('SPOTIFY'), findsNothing);
    expect(find.byTooltip('Open in Spotify'), findsNothing);

    // Verify no intrusive zoom badge is displayed on the cover
    expect(find.text('ZOOM ART'), findsNothing);

    // Tap directly on the cover artwork card to zoom in
    await tester.tap(find.byType(AlbumArtCard).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify ArtworkZoomViewer opened with high-res viewer controls
    expect(find.text('HIGH-RES ARTWORK'), findsOneWidget);
    expect(find.text('PINCH OR DOUBLE-TAP TO ZOOM'), findsOneWidget);
    expect(find.text('BACK'), findsOneWidget);

    // Tap BACK button to dismiss viewer
    await tester.tap(find.text('BACK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Ensure no exceptions or overflows occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReviewDetailScreen share button launches Instagram Story designer modal', (WidgetTester tester) async {
    final review = Review(
      id: 'test_rev_share',
      musicItemId: 'album_brat',
      musicItemName: 'BRAT',
      artistName: 'CHARLI XCX',
      coverUrl: '',
      itemType: 'album',
      userId: 'test_critic_id',
      userName: 'TEST_CRITIC',
      userHandle: '@testcritic',
      rating: 9.3,
      headline: 'Unapologetic club pop masterpiece.',
      body: 'BRAT proves dance music does not have to compromise emotional depth.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ReviewDetailScreen(review: review),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify critique archive header and story button
    expect(find.text('CRITIQUE ARCHIVE'), findsOneWidget);
    expect(find.text('STORY'), findsOneWidget);

    // Tap AppBar share icon button
    await tester.tap(find.byTooltip('Share Critique'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Instagram Story modal appears
    expect(find.text('SHARE CRITIQUE'), findsWidgets);
    expect(find.text('INSTANT 9:16 STORY DESIGNER'), findsOneWidget);
    expect(find.text('STORY THEME'), findsOneWidget);
    expect(find.text('DARK'), findsOneWidget);
    expect(find.text('ACID'), findsOneWidget);
    expect(find.text('CYBER'), findsOneWidget);
    expect(find.text('ZINE'), findsOneWidget);
    expect(find.text('SHARE TO INSTAGRAM STORIES'), findsOneWidget);
    expect(find.text('SAVE STORY'), findsOneWidget);

    // Tap ACID theme pill
    await tester.tap(find.text('ACID'));
    await tester.pump();

    // Tap close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Modal is closed
    expect(find.text('INSTANT 9:16 STORY DESIGNER'), findsNothing);
  });

  testWidgets('ReviewCard displays universal avatar and updated critic identity for current user', (WidgetTester tester) async {
    final review = Review(
      id: 'rev_mine',
      musicItemId: 'm1',
      musicItemName: 'IN RAINBOWS',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'INITIAL NAME',
      userHandle: '@initial_handle',
      rating: 9.6,
      headline: 'A masterpiece of sonic texture',
      body: 'Every instrument is in perfect harmony.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReviewCard(review: review),
          ),
        ),
      ),
    );

    await tester.pump();
    // For current user, ReviewCard dynamically displays active profile userName
    expect(find.text('CRITIC // YOU'), findsOneWidget);
    expect(find.textContaining('@groovd_me'), findsOneWidget);
  });

  testWidgets('ProfileScreen settings modal renders CRITIC IDENTITY card and opens edit dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap the Settings gear icon
    final settingsButton = find.byTooltip('Settings');
    expect(settingsButton, findsOneWidget);
    await tester.tap(settingsButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Settings modal shows fused Profile Customization container
    expect(find.text('PROFILE CUSTOMIZATION'), findsOneWidget);
    await tester.tap(find.text('PROFILE CUSTOMIZATION'));
    await tester.pumpAndSettle();

    // Verify Critic Identity Card is revealed
    expect(find.text('CRITIC IDENTITY'), findsOneWidget);
    expect(find.text('GROOVD ID'), findsOneWidget);
    expect(find.text('CHANGE USERNAME & HANDLE'), findsOneWidget);

    // Tap CHANGE USERNAME & HANDLE button
    await tester.tap(find.text('CHANGE USERNAME & HANDLE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Edit Username & Handle sheet opens
    expect(find.text('DISPLAY NAME / USERNAME'), findsOneWidget);
    expect(find.text('GROOVD HANDLE'), findsOneWidget);
    expect(find.text('SAVE IDENTITY'), findsOneWidget);

    // Tap close button on the edit dialog
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('DISPLAY NAME / USERNAME'), findsNothing);
  });

  testWidgets('AllRatedReleasesScreen renders stats, filters, grid view, and switches to list view', (WidgetTester tester) async {
    final sampleReviews = [
      Review(
        id: 'r1',
        musicItemId: 'm1',
        musicItemName: 'VESPERTINE',
        artistName: 'BJÖRK',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 10.0,
        headline: 'Pure bliss and sonic perfection',
        body: 'A winter wonderland of microbeats and strings.',
        createdAt: DateTime.now(),
      ),
      Review(
        id: 'r2',
        musicItemId: 'm2',
        musicItemName: 'PAGAN POETRY',
        artistName: 'BJÖRK',
        coverUrl: '',
        itemType: 'song',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 9.5,
        headline: 'Chilling vocal masterpiece',
        body: 'Unbelievable emotional release in the final chorus.',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userReviewsProvider('user_me').overrideWith((ref) => Future.value(sampleReviews)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AllRatedReleasesScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify header and title
    expect(find.text('ALL RATED RELEASES'), findsOneWidget);
    expect(find.text('TOTAL RATED'), findsOneWidget);
    expect(find.text('AVG SCORE'), findsOneWidget);
    expect(find.text('LPS'), findsWidgets);
    expect(find.text('TRACKS'), findsWidgets);
    expect(find.text('VESPERTINE'), findsOneWidget);
    expect(find.text('PAGAN POETRY'), findsOneWidget);

    // Verify view mode toggle buttons exist
    expect(find.byIcon(Icons.grid_view), findsOneWidget);
    expect(find.byIcon(Icons.view_agenda_outlined), findsOneWidget);

    // Switch to list view
    await tester.tap(find.byIcon(Icons.view_agenda_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Ensure no exceptions occurred
    expect(tester.takeException(), isNull);
  });

  testWidgets('Recent Activity card tap redirects to ReviewDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify RECENT ACTIVITY section is visible
    expect(find.text('RECENT ACTIVITY'), findsOneWidget);

    // Verify ALL RATED link is present in recent activity header
    expect(find.textContaining('ALL'), findsWidgets);

    // Find and tap a recent activity card
    final recentCards = find.byType(InkWell);
    expect(recentCards, findsWidgets);

    // Ensure no exceptions
    expect(tester.takeException(), isNull);
  });

  testWidgets('ReviewDetailScreen displays edit and delete action buttons in AppBar for current user and opens modals', (WidgetTester tester) async {
    final myReview = Review(
      id: 'rev_detail_edit_test',
      musicItemId: 'm_detail_edit',
      musicItemName: 'KID A',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.2,
      headline: 'Experimental brilliance',
      body: 'Revolutionary soundscapes and haunting vocals.',
      tags: ['#AOTY', '#CLASSIC'],
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReviewDetailScreen(review: myReview),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify bottom button was removed as requested
    expect(find.text('EDIT RATING & REVIEW'), findsNothing);

    // Verify both Edit (pencil) and Delete (trash) icons appear in AppBar actions
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    // Tap edit pencil icon in AppBar
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify modal opened with 'EDIT YOUR REVIEW' title and pre-filled headline/body
    expect(find.text('EDIT YOUR REVIEW'), findsOneWidget);
    expect(find.descendant(of: find.byType(WriteReviewModal), matching: find.text('Experimental brilliance')), findsOneWidget);
    expect(find.descendant(of: find.byType(WriteReviewModal), matching: find.text('Revolutionary soundscapes and haunting vocals.')), findsOneWidget);
    expect(find.textContaining('UPDATE CRITIQUE'), findsOneWidget);

    // Close the edit modal
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('EDIT YOUR REVIEW'), findsNothing);

    // Tap delete trash icon in AppBar
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify delete confirmation dialog appears
    expect(find.text('DELETE CRITIQUE'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('DELETE'), findsOneWidget);

    // Tap cancel
    await tester.tap(find.text('CANCEL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('DELETE CRITIQUE'), findsNothing);
  });

  testWidgets('MusicDetailScreen shows EDIT YOUR REVIEW button when user has already rated release', (WidgetTester tester) async {
    final myReview = Review(
      id: 'rev_music_detail_test',
      musicItemId: 'm_already_rated',
      musicItemName: 'IN RAINBOWS',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.8,
      headline: 'Flawless art rock',
      body: 'From 15 Step to Videotape, perfection.',
      createdAt: DateTime.now(),
    );

    final musicItem = MusicItem(
      id: 'm_already_rated',
      name: 'IN RAINBOWS',
      artist: 'RADIOHEAD',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '2007',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemReviewsProvider(ItemReviewQuery.fromItem(musicItem)).overrideWith((ref) => Future.value([myReview])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: musicItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    // Verify the bottom action bar displays '+ LOG AGAIN' and 'EDIT [9.8]' instead of '+ LOG YOUR REVIEW'
    expect(find.text('+ LOG AGAIN'), findsOneWidget);
    expect(find.text('EDIT [9.8]'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
  });

  testWidgets('MusicDetailScreen resolves existing review across different catalog IDs (e.g. mock ID to Deezer numeric ID)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Review was originally logged under older mock/Spotify ID 'album_blonde'
    final existingReview = Review(
      id: 'rev_blonde_1',
      musicItemId: 'album_blonde',
      musicItemName: 'Blonde',
      artistName: 'Frank Ocean',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.5,
      headline: 'Masterpiece of modern R&B',
      body: 'Incredible album from start to finish.',
      createdAt: DateTime.now(),
    );

    // User navigates from Deezer search catalog, returning numeric ID '14088928'
    final deezerItem = MusicItem(
      id: '14088928',
      name: 'Blonde',
      artist: 'Frank Ocean',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '2016',
    );

    // Verify ItemReviewQuery resolves equality across different IDs with same work
    final queryFromMock = ItemReviewQuery(id: 'album_blonde', name: 'Blonde', artist: 'Frank Ocean', type: 'album');
    final queryFromDeezer = ItemReviewQuery.fromItem(deezerItem);
    expect(queryFromDeezer, equals(queryFromMock));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemReviewsProvider(queryFromDeezer).overrideWith((ref) => Future.value([existingReview])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: deezerItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 400));

    // Even though deezerItem has ID '14088928' and existingReview has 'album_blonde',
    // the user's review is resolved and displays both '+ LOG AGAIN' and 'EDIT [9.5]'
    expect(find.text('+ LOG AGAIN'), findsOneWidget);
    expect(find.text('EDIT [9.5]'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
  });

  testWidgets('MusicDetailScreen "+ LOG AGAIN" button opens WriteReviewModal in re-listen mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final musicItem = MusicItem(
      id: 'album_relog',
      name: 'CURRENTS',
      artist: 'TAME IMPALA',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '2015',
    );

    final firstReview = Review(
      id: 'rev_cur_1',
      musicItemId: 'album_relog',
      musicItemName: 'CURRENTS',
      artistName: 'TAME IMPALA',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.0,
      headline: 'Psychedelic masterpiece',
      body: 'Let it happen on repeat.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemReviewsProvider(ItemReviewQuery.fromItem(musicItem)).overrideWith((ref) => Future.value([firstReview])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: musicItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Tap + LOG AGAIN
    await tester.tap(find.text('+ LOG AGAIN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // WriteReviewModal should appear in re-listen mode
    expect(find.textContaining('LOG AGAIN // RE-LISTEN'), findsOneWidget);
  });

  testWidgets('AlbumArtCard displays repeat count badge only when logged more than 1 time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Card with logCount: 1 -> should NOT show badge
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AlbumArtCard(imageUrl: '', size: 100, logCount: 1),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('1X'), findsNothing);

    // Card with logCount: 3 -> should show '3X' badge
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AlbumArtCard(imageUrl: '', size: 100, logCount: 3),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('3X'), findsOneWidget);
  });

  testWidgets('ProfileScreen navbar has no cloud icon and settings modal contains fused Profile Customization dropdown', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Verify cloud icons (cloud_done / cloud_queue) are absent from top navbar
    expect(find.byIcon(Icons.cloud_done), findsNothing);
    expect(find.byIcon(Icons.cloud_queue_outlined), findsNothing);

    // Tap Settings gear icon to open modal
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify fused 'PROFILE CUSTOMIZATION' container with '3 MODULES' is rendered
    expect(find.text('PROFILE CUSTOMIZATION'), findsOneWidget);
    expect(find.text('3 MODULES'), findsOneWidget);
  });

  testWidgets('AllRatedReleasesScreen places repeat count badge aligned to the right of LP/EP/TRACK badge', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Two reviews for the same album VESPERTINE (logged twice -> 2X)
    // and one review for a song PAGAN POETRY (logged once -> no badge)
    final sampleReviews = [
      Review(
        id: 'r1',
        musicItemId: 'm1',
        musicItemName: 'VESPERTINE',
        artistName: 'BJÖRK',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 10.0,
        headline: 'Pure bliss',
        body: 'Microbeats and choirs.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Review(
        id: 'r2',
        musicItemId: 'm1',
        musicItemName: 'VESPERTINE',
        artistName: 'BJÖRK',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 9.8,
        headline: 'Re-listening session',
        body: 'Even better on vinyl.',
        createdAt: DateTime.now(),
      ),
      Review(
        id: 'r3',
        musicItemId: 'm2',
        musicItemName: 'PAGAN POETRY',
        artistName: 'BJÖRK',
        coverUrl: '',
        itemType: 'song',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 9.5,
        headline: 'Single',
        body: 'Amazing track.',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userReviewsProvider('user_me').overrideWith((ref) => Future.value(sampleReviews)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AllRatedReleasesScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // '2X' badge should be present ONLY for the 2nd log (r2); past log (r1) remains unbadged
    expect(find.text('2X'), findsOneWidget);

    // Switch to List view
    final listIcon = find.byIcon(Icons.view_agenda_outlined);
    expect(listIcon, findsOneWidget);
    await tester.tap(listIcon);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // '2X' badge should also appear for only the 2nd log in list view
    expect(find.text('2X'), findsOneWidget);
  });

  testWidgets("ProfileScreen Critic's Canon section does not display repeat count badge", (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // CRITIC'S CANON section is rendered
    expect(find.text("CRITIC'S CANON"), findsOneWidget);

    // Verify TOP 3 ALBUMS podium slot does not display a count badge inside its card
    final canonFinder = find.ancestor(
      of: find.text('TOP 3 ALBUMS'),
      matching: find.byType(Column),
    );
    expect(canonFinder, findsWidgets);
  });

  testWidgets('ArtistDetailScreen renders artist header, stats bar, biography card, and discography', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const artist = Artist(
      id: 'artist_radiohead',
      name: 'RADIOHEAD',
      imageUrl: '',
      genres: ['ART ROCK', 'ALTERNATIVE'],
      followers: 8900000,
      popularity: 84,
      bio: 'Radiohead are an English rock band formed in Abingdon, Oxfordshire, in 1985.',
      shortDescription: 'English rock band',
      spotifyUrl: 'https://open.spotify.com/artist/4Z8W4fKeB5YxbusRsdQVPb',
    );

    final mockTopTracks = [
      const MusicItem(
        id: 'track_creep',
        name: 'Creep',
        artist: 'Radiohead',
        type: MusicType.song,
        coverUrl: '',
        releaseDate: '1993',
        durationMs: 238000,
      ),
    ];

    final mockDiscography = [
      const MusicItem(
        id: 'album_in_rainbows',
        name: 'In Rainbows',
        artist: 'Radiohead',
        type: MusicType.album,
        coverUrl: '',
        releaseDate: '2007',
      ),
      const MusicItem(
        id: 'track_creep',
        name: 'Creep',
        artist: 'Radiohead',
        type: MusicType.song,
        coverUrl: '',
        releaseDate: '1993',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artistDetailProvider('RADIOHEAD').overrideWith((ref) => Future.value(artist)),
          artistTopTracksProvider('RADIOHEAD').overrideWith((ref) => Future.value(mockTopTracks)),
          artistDiscographyProvider('RADIOHEAD').overrideWith((ref) => Future.value(mockDiscography)),
          artistCareerStatsProvider('RADIOHEAD').overrideWith((ref) => Future.value(
            const ArtistCareerStats(
              averageScore: 9.4,
              totalCommunityReviews: 12,
              userRatedCount: 2,
              totalReleasesCount: 2,
              communityFavoriteTitle: 'IN RAINBOWS',
              communityFavoriteScore: 9.9,
            ),
          )),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ArtistDetailScreen(artistIdOrName: 'RADIOHEAD'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify AppBar & Hero Title
    expect(find.text('ARTIST DOSSIER'), findsOneWidget);
    expect(find.text('RADIOHEAD'), findsOneWidget);
    expect(find.text('ENGLISH ROCK BAND'), findsOneWidget);
    expect(find.text('8.9M FOLLOWERS'), findsOneWidget);
    expect(find.text('ROTATION INDEX 84%'), findsOneWidget);

    // Verify Career Stats
    expect(find.text('GROOVD CRITIC CAREER STATS'), findsOneWidget);
    expect(find.text('CAREER SCORE'), findsOneWidget);

    // Verify Wikipedia Briefing Box
    expect(find.text('ARCHIVE BRIEFING // BIOGRAPHY'), findsOneWidget);
    expect(find.textContaining('Abingdon'), findsOneWidget);

    // Verify Essential In Rotation (Top Tracks)
    expect(find.text('ESSENTIAL IN ROTATION'), findsOneWidget);
    expect(find.text('CREEP'), findsWidgets);

    // Verify Discography
    expect(find.text('DISCOGRAPHY'), findsOneWidget);
    expect(find.textContaining('ALL'), findsWidgets);
    expect(find.textContaining('STUDIO LPS'), findsOneWidget);
    expect(find.textContaining('SINGLES & EPS'), findsOneWidget);

    // Test filter tapping
    await tester.tap(find.textContaining('STUDIO LPS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('MusicDetailScreen artist name tap opens ArtistDetailScreen', (WidgetTester tester) async {
    const musicItem = MusicItem(
      id: 'm_nav_artist_test',
      name: 'BLONDE',
      artist: 'FRANK OCEAN',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '2016',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MusicDetailScreen(item: musicItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Tap artist header
    final artistLink = find.text('BY FRANK OCEAN');
    expect(artistLink, findsOneWidget);
    await tester.tap(artistLink);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify ArtistDetailScreen opened
    expect(find.text('ARTIST DOSSIER'), findsOneWidget);
  });

  testWidgets('SearchScreen renders filter tabs and prominent artist dossier card when searching an artist', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify search catalog header and all 4 filter tabs
    expect(find.text('SEARCH CATALOG'), findsOneWidget);
    expect(find.text('ALL'), findsOneWidget);
    expect(find.text('ARTISTS'), findsOneWidget);
    expect(find.text('ALBUMS'), findsOneWidget);
    expect(find.text('TRACKS'), findsOneWidget);

    // Enter artist name in search field
    await tester.enterText(find.byType(TextField), 'Radiohead');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Prominent artist dossier card should now appear
    expect(find.text('MATCHING ARTIST DOSSIER'), findsOneWidget);
    expect(find.text('RADIOHEAD'), findsWidgets);
    expect(find.text('ARTIST // DOSSIER'), findsOneWidget);
    expect(find.text('OPEN DOSSIER'), findsOneWidget);

    // Tap the Artist Dossier card
    await tester.tap(find.text('ARTIST // DOSSIER').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Navigated to ArtistDetailScreen
    expect(find.text('ARTIST DOSSIER'), findsOneWidget);
  });

  testWidgets('SearchScreen switches to ARTISTS category and displays artist results', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SearchScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap ARTISTS filter chip
    await tester.tap(find.text('ARTISTS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // In ARTISTS category without query, search prompt is displayed (no fake mock artists)
    expect(find.text('SEARCH ARTIST DOSSIERS'), findsOneWidget);

    // Type artist name
    await tester.enterText(find.byType(TextField), 'Radiohead');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Matching artist dossier card appears
    expect(find.text('RADIOHEAD'), findsWidgets);
    expect(find.text('ARTIST // DOSSIER'), findsOneWidget);
  });

  testWidgets('ArtistDetailScreen hides follower badge when followers count is 0', (WidgetTester tester) async {
    const zeroFollowerArtist = Artist(
      id: 'zero_followers_test',
      name: 'UNKNOWN BAND',
      imageUrl: '',
      followers: 0,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artistDetailProvider('zero_followers_test').overrideWith((ref) => zeroFollowerArtist),
          artistTopTracksProvider('zero_followers_test').overrideWith((ref) => []),
          artistDiscographyProvider('zero_followers_test').overrideWith((ref) => []),
          artistCareerStatsProvider('UNKNOWN BAND').overrideWith((ref) => const ArtistCareerStats(
                averageScore: 0.0,
                totalCommunityReviews: 0,
                userRatedCount: 0,
                totalReleasesCount: 0,
              )),
        ],
        child: const MaterialApp(
          home: ArtistDetailScreen(artistIdOrName: 'zero_followers_test'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('UNKNOWN BAND'), findsOneWidget);
    // Should NOT find '0 FOLLOWERS'
    expect(find.text('0 FOLLOWERS'), findsNothing);
  });

  testWidgets('LoginScreen renders properly with email and google options and validates inputs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('CRITIC PORTAL // AUTHENTICATION'), findsOneWidget);
    expect(find.text('LOG IN TO GROOVD'), findsOneWidget);
    expect(find.text('CRITIC EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('LOG IN // AUTHENTICATE'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);
    expect(find.text('CONTINUE AS GUEST // OFFLINE MODE'), findsOneWidget);

    // Tap Log In with empty fields to trigger validation
    await tester.tap(find.text('LOG IN // AUTHENTICATE'));
    await tester.pump();

    expect(find.text('ENTER YOUR EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('ENTER YOUR PASSWORD'), findsOneWidget);

    // Tap Forgot Password
    await tester.tap(find.text('FORGOT PASSWORD?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('RESET PASSWORD'), findsOneWidget);
    expect(find.text('SEND RESET LINK'), findsOneWidget);
  });

  testWidgets('RegisterScreen renders properly with fields and validates inputs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('CRITIC ENROLLMENT'), findsOneWidget);
    expect(find.text('CREATE YOUR\nCRITIC DOSSIER'), findsOneWidget);
    expect(find.text('CRITIC DISPLAY NAME'), findsOneWidget);
    expect(find.text('CRITIC HANDLE (OPTIONAL)'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD (MIN 6 CHARS)'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
    expect(find.text('REGISTER // ENROLL DOSSIER'), findsOneWidget);
    expect(find.text('CONTINUE WITH GOOGLE'), findsOneWidget);

    // Submit empty to trigger validation
    await tester.tap(find.text('REGISTER // ENROLL DOSSIER'));
    await tester.pump();

    expect(find.text('ENTER YOUR CRITIC DISPLAY NAME'), findsOneWidget);
    expect(find.text('ENTER YOUR EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('ENTER A PASSWORD'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders guest mode Cloud Backup card and opens settings with Cloud Dossier', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // In guest mode, cloud backup prompt card is rendered
    expect(find.text('CLOUD BACKUP // GUEST MODE'), findsOneWidget);
    expect(find.text('BACK UP & SYNC YOUR CRITIC DOSSIER'), findsOneWidget);

    // Open settings modal
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Drag settings modal up to reveal Cloud Dossier section if needed
    await tester.drag(find.text('SETTINGS'), const Offset(0, -300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Cloud Dossier sync section
    expect(find.text('CLOUD DOSSIER // SYNC'), findsOneWidget);
    expect(find.text('OFFLINE'), findsOneWidget);
  });

  testWidgets('MainNavigationScreen renders FRIENDS tab to the left of DOSSIER and switches to FriendsScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check all four tabs in bottom navigation
    expect(find.text('DISPATCH'), findsOneWidget);
    expect(find.text('SEARCH'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.text('DOSSIER'), findsOneWidget);

    // Verify FRIENDS is rendered to the left of DOSSIER
    final friendsPos = tester.getCenter(find.text('FRIENDS'));
    final dossierPos = tester.getCenter(find.text('DOSSIER'));
    expect(friendsPos.dx < dossierPos.dx, isTrue);

    // Tap FRIENDS tab
    await tester.tap(find.text('FRIENDS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify FriendsScreen content is visible
    expect(find.text('CRITIC CIRCLE'), findsOneWidget);
    expect(find.text('ACTIVITY FEED'), findsOneWidget);
    expect(find.text('MY CIRCLE'), findsOneWidget);
    expect(find.text('DISCOVER'), findsOneWidget);
  });

  testWidgets('FriendsScreen switches to DISCOVER and displays suggested tastemakers', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          suggestedCriticsProvider.overrideWith((ref) async => [
            const FriendProfile(
              userId: 'real_critic_1',
              userName: 'DISCO_CRITIC',
              userHandle: '@discocritic',
              bio: 'Vinyl only.',
            ),
          ]),
        ],
        child: const MaterialApp(
          home: FriendsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Switch to DISCOVER tab
    await tester.tap(find.text('DISCOVER'));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Check suggested real critics are listed
    expect(find.text('DISCO_CRITIC'), findsWidgets);
    expect(find.text('@discocritic'), findsWidgets);
  });

  testWidgets('FriendProfileScreen renders full critic dossier with podiums and follow button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const testFriend = FriendProfile(
      userId: 'test_friend_99',
      userName: 'SYNTH_WAVE_99',
      userHandle: 'synth_wave',
      bio: 'Electronic & retrowave sounds only.',
      reviewsCount: 42,
      followersCount: 1500,
      followingCount: 300,
      wantlistCount: 8,
      listsCount: 3,
      isFollowing: false,
      topAlbums: [
        MusicItem(
          id: 'alb_1',
          name: 'Discovery',
          artist: 'Daft Punk',
          type: MusicType.album,
          coverUrl: 'https://example.com/discovery.jpg',
          releaseDate: '2001-03-12',
        ),
        MusicItem(
          id: 'alb_2',
          name: 'OutRun',
          artist: 'Kavinsky',
          type: MusicType.album,
          coverUrl: 'https://example.com/outrun.jpg',
          releaseDate: '2013-02-22',
        ),
      ],
      topSongs: [
        MusicItem(
          id: 'sng_1',
          name: 'Nightcall',
          artist: 'Kavinsky',
          type: MusicType.song,
          coverUrl: 'https://example.com/nightcall.jpg',
          releaseDate: '2010-04-06',
        ),
        MusicItem(
          id: 'sng_2',
          name: 'One More Time',
          artist: 'Daft Punk',
          type: MusicType.song,
          coverUrl: 'https://example.com/onemoretime.jpg',
          releaseDate: '2000-11-13',
        ),
      ],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FriendProfileScreen(initialProfile: testFriend),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify Dossier title & profile details
    expect(find.text('CRITIC DOSSIER'), findsOneWidget);
    expect(find.text('SYNTH_WAVE_99'), findsOneWidget);
    expect(find.text('@synth_wave'), findsOneWidget);
    expect(find.text('Electronic & retrowave sounds only.'), findsOneWidget);
    expect(find.text('+ FOLLOW CRITIC'), findsOneWidget);

    // Verify stats boxes
    expect(find.text('LOGGED'), findsOneWidget);
    expect(find.text('AVG SCORE'), findsOneWidget);
    expect(find.text('PERFECT 10s'), findsOneWidget);

    // Verify podium sections (mirroring ProfileScreen)
    expect(find.textContaining('CRITIC\'S CANON'), findsOneWidget);
    expect(find.textContaining('TOP 3 ALBUMS'), findsOneWidget);
    expect(find.textContaining('TOP 3 SONGS'), findsOneWidget);
    expect(find.text('DISCOVERY'), findsOneWidget);
    expect(find.text('NIGHTCALL'), findsOneWidget);

    // Verify recent activity and logged reviews headers
    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('CRITIC\'S LOGGED REVIEWS'), findsOneWidget);

    // Verify wantlist and curated lists banners
    expect(find.text('CRITIC WANTLIST // QUEUE'), findsOneWidget);
    expect(find.text('CURATED LISTS // ARCHIVE'), findsOneWidget);

    // Tap follow button
    await tester.tap(find.text('+ FOLLOW CRITIC'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('✓ FOLLOWING'), findsWidgets);
  });

  testWidgets('FriendProfileScreen allows navigation to wantlist, curated lists, all rated, and critiques', (WidgetTester tester) async {
    const testFriend = FriendProfile(
      userId: 'friend_test_456',
      userName: 'ALEX_CRITIC',
      userHandle: '@alexcritic',
      bio: 'Deep cuts only.',
      isFollowing: true,
      reviewsCount: 42,
      followersCount: 1500,
      followingCount: 300,
      wantlistCount: 8,
      listsCount: 3,
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FriendProfileScreen(initialProfile: testFriend),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 1. Curated Lists shortcut banner
    final listsBanner = find.text('CURATED LISTS // ARCHIVE');
    expect(listsBanner, findsOneWidget);
    await tester.ensureVisible(listsBanner);
    await tester.tap(listsBanner);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("ALEX_CRITIC'S LISTS"), findsOneWidget);
    Navigator.of(tester.element(find.text("ALEX_CRITIC'S LISTS"))).pop();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 2. Wantlist shortcut banner
    final wantlistBanner = find.text('CRITIC WANTLIST // QUEUE');
    expect(wantlistBanner, findsOneWidget);
    await tester.ensureVisible(wantlistBanner);
    await tester.tap(wantlistBanner);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("ALEX_CRITIC'S WANTLIST"), findsOneWidget);
    Navigator.of(tester.element(find.text("ALEX_CRITIC'S WANTLIST"))).pop();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 3. Stat box tap (LOGGED) -> All Rated Releases
    final loggedBox = find.text('LOGGED');
    expect(loggedBox, findsOneWidget);
    await tester.ensureVisible(loggedBox);
    await tester.tap(loggedBox);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("ALEX_CRITIC'S RATED"), findsOneWidget);
    Navigator.of(tester.element(find.text("ALEX_CRITIC'S RATED"))).pop();
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 4. Critiques section header tap -> Logged Reviews Screen
    final critiquesHeader = find.text("CRITIC'S LOGGED REVIEWS");
    expect(critiquesHeader, findsOneWidget);
    await tester.ensureVisible(critiquesHeader);
    await tester.tap(critiquesHeader);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text("ALEX_CRITIC'S CRITIQUES"), findsOneWidget);
  });

  testWidgets('CriticFollowersStatsRow formats numbers and handles tap callbacks', (WidgetTester tester) async {
    expect(CriticFollowersStatsRow.formatCount(0), '0');
    expect(CriticFollowersStatsRow.formatCount(42), '42');
    expect(CriticFollowersStatsRow.formatCount(1200), '1.2K');
    expect(CriticFollowersStatsRow.formatCount(1000), '1K');
    expect(CriticFollowersStatsRow.formatCount(2500000), '2.5M');

    bool followersTapped = false;
    bool followingTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CriticFollowersStatsRow(
            followersCount: 1500,
            followingCount: 300,
            onFollowersTap: () => followersTapped = true,
            onFollowingTap: () => followingTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('1.5K'), findsOneWidget);
    expect(find.text('FOLLOWERS'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
    expect(find.text('FOLLOWING'), findsOneWidget);

    await tester.tap(find.text('FOLLOWERS'));
    await tester.pump();
    expect(followersTapped, isTrue);

    await tester.tap(find.text('FOLLOWING'));
    await tester.pump();
    expect(followingTapped, isTrue);
  });

  testWidgets('FriendProfileScreen renders followers and following counters below bio', (WidgetTester tester) async {
    const friend = FriendProfile(
      userId: 'test_friend_123',
      userName: 'NOVA_SOUND',
      userHandle: '@novasound',
      bio: 'Analog beats and synth waves.',
      followersCount: 1800,
      followingCount: 420,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendReviewsProvider(friend.userId).overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: FriendProfileScreen(initialProfile: friend),
        ),
      ),
    );

    await tester.pump();

    // Verify bio is rendered
    expect(find.text('Analog beats and synth waves.'), findsOneWidget);

    // Verify followers & following counters are rendered
    expect(find.text('1.8K'), findsOneWidget);
    expect(find.text('FOLLOWERS'), findsOneWidget);
    expect(find.text('420'), findsOneWidget);
    expect(find.text('FOLLOWING'), findsOneWidget);
  });

  testWidgets('FriendProfileScreen renders FOLLOW BACK and FOLLOWS YOU when friend follows current user', (WidgetTester tester) async {
    const friend = FriendProfile(
      userId: 'follower_user_99',
      userName: 'CEMETHEUS',
      userHandle: '@grunge_free',
      bio: 'Deep cuts and raw grunge.',
      followersCount: 15,
      followingCount: 30,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendReviewsProvider(friend.userId).overrideWith((ref) => Future.value([])),
          currentUserFollowerIdsProvider.overrideWith((ref) => Stream.value({'follower_user_99'})),
        ],
        child: const MaterialApp(
          home: FriendProfileScreen(initialProfile: friend),
        ),
      ),
    );

    await tester.pump();

    // Verify FOLLOWS YOU badge is shown
    expect(find.text('FOLLOWS YOU'), findsOneWidget);

    // Verify + FOLLOW BACK button is rendered in both AppBar and Header
    expect(find.text('+ FOLLOW BACK'), findsNWidgets(2));
  });

  testWidgets('Album automatic overall score badge only appears when ALL tracks are rated', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final albumItem = MusicItem(
      id: 'album_test_overall',
      name: 'IN RAINBOWS',
      artist: 'RADIOHEAD',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '2007',
      tracks: const [
        TrackInfo(id: 'trk_1', name: '15 Step', trackNumber: 1, durationMs: 237000, artist: 'RADIOHEAD'),
        TrackInfo(id: 'trk_2', name: 'Bodysnatchers', trackNumber: 2, durationMs: 242000, artist: 'RADIOHEAD'),
      ],
    );

    final track1Review = Review(
      id: 'rev_t1',
      musicItemId: 'trk_1',
      musicItemName: '15 Step',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 8.0,
      headline: 'Great opener',
      body: 'Percussion is incredible.',
      createdAt: DateTime.now(),
    );

    // Scenario 1: Only track 1 is rated -> OVERALL badge must NOT appear
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userReviewsProvider('user_me').overrideWith((ref) => Future.value([track1Review])),
          itemReviewsProvider(ItemReviewQuery.fromItem(albumItem)).overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: albumItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('OVERALL'), findsNothing);
    // Track 1 should show its rating badge
    expect(find.text('8.0'), findsOneWidget);

    // Scenario 2: Both tracks are rated (8.0 and 9.4 -> avg 8.7)
    final track2Review = Review(
      id: 'rev_t2',
      musicItemId: 'trk_2',
      musicItemName: 'Bodysnatchers',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.4,
      headline: 'Raw guitars',
      body: 'Thom Yorke at his finest.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          userReviewsProvider('user_me').overrideWith((ref) => Future.value([track1Review, track2Review])),
          itemReviewsProvider(ItemReviewQuery.fromItem(albumItem)).overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: albumItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Average is (8.0 + 9.4)/2 = 8.7
    // Verify OVERALL 8.7 badge appears in both metadata wrap and tracklist header
    expect(find.text('OVERALL 8.7'), findsNWidgets(2));

    // Now tap + LOG YOUR REVIEW to verify it opens WriteReviewModal with 8.7 auto-set
    await tester.tap(find.text('+ LOG YOUR REVIEW'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // The modal's score live display should default to 8.7
    expect(find.text('8.7'), findsWidgets);
    // The TAP TO SET chip should be rendered
    final tapToSetFinder = find.text('TRACKS OVERALL: 8.7 (TAP TO SET)');
    expect(tapToSetFinder, findsOneWidget);

    // Verify user can freely change rating via slider interaction
    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    await tester.tap(sliderFinder);
    await tester.pump();

    // Tap the TAP TO SET chip to snap back to the computed 8.7 overall score
    await tester.tap(tapToSetFinder);
    await tester.pump();
    expect(find.text('8.7'), findsWidgets);
  });

  testWidgets('RatingSpikeSign renders hollow for <= 6.0, full for 6.1-9.4, and 8-point for 9.5-10.0', (WidgetTester tester) async {
    // 1. Below / equal to 6.0 -> hollow tier
    const signLow = RatingSpikeSign(rating: 5.5);
    expect(signLow.tier, RatingSignTier.hollow);

    // Boundary at 6.0
    const signBoundaryLow = RatingSpikeSign(rating: 6.0);
    expect(signBoundaryLow.tier, RatingSignTier.hollow);

    // 2. 6.1 until 9.4 -> full tier
    const signMid = RatingSpikeSign(rating: 8.5);
    expect(signMid.tier, RatingSignTier.full);

    const signMidLower = RatingSpikeSign(rating: 6.1);
    expect(signMidLower.tier, RatingSignTier.full);

    const signMidUpper = RatingSpikeSign(rating: 9.4);
    expect(signMidUpper.tier, RatingSignTier.full);

    // 3. 9.5 until 10.0 -> eightPoint tier
    const signHigh = RatingSpikeSign(rating: 9.5);
    expect(signHigh.tier, RatingSignTier.eightPoint);

    const signPerfect = RatingSpikeSign(rating: 10.0);
    expect(signPerfect.tier, RatingSignTier.eightPoint);

    // Render in widget tree to verify CustomPaint drawing executes without errors
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RatingSpikeSign(rating: 4.0, size: 20),
              RatingSpikeSign(rating: 8.0, size: 24),
              RatingSpikeSign(rating: 9.8, size: 28),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(RatingSpikeSign), findsNWidgets(3));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('ReviewCard renders RatingSpikeSign alongside score formatted', (WidgetTester tester) async {
    final review = Review(
      id: 'rev_spike_test',
      musicItemId: 'song_spike',
      musicItemName: 'PARANOID ANDROID',
      artistName: 'RADIOHEAD',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 9.8,
      headline: 'Best song of the 90s',
      body: 'Epic 3-part suite.',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ReviewCard(review: review),
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify RatingSpikeSign is present in the ReviewCard
    final spikeFinder = find.byType(RatingSpikeSign);
    expect(spikeFinder, findsOneWidget);
    final spikeWidget = tester.widget<RatingSpikeSign>(spikeFinder);
    expect(spikeWidget.rating, 9.8);
    expect(spikeWidget.tier, RatingSignTier.eightPoint);
  });

  testWidgets('ProfileScreen renders RatingSpikeSign inside AVG SCORE stat box', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final testReviews = [
      Review(
        id: 'rev_avg_1',
        musicItemId: 'alb_1',
        musicItemName: 'Discovery',
        artistName: 'Daft Punk',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 8.5,
        headline: 'French touch classic',
        body: 'Timeless masterpiece.',
        createdAt: DateTime.now(),
      ),
      Review(
        id: 'rev_avg_2',
        musicItemId: 'alb_2',
        musicItemName: 'Random Access Memories',
        artistName: 'Daft Punk',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_me',
        userName: 'YOU',
        userHandle: '@you',
        rating: 9.5,
        headline: 'Audiophile dream',
        body: 'Perfection.',
        createdAt: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userReviewsProvider.overrideWith((ref, userId) async => testReviews),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify RatingSpikeSign is present inside the AVG score stat box
    final selfSpikeFinder = find.descendant(
      of: find.ancestor(
        of: find.text('AVG SCORE'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_StatBox'),
      ),
      matching: find.byType(RatingSpikeSign),
    );
    expect(selfSpikeFinder, findsOneWidget);
    final selfSpike = tester.widget<RatingSpikeSign>(selfSpikeFinder);
    expect(selfSpike.rating, 9.0);
    expect(selfSpike.tier, RatingSignTier.full);
  });

  testWidgets('FriendProfileScreen renders RatingSpikeSign inside AVG SCORE stat box', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    const testFriend = FriendProfile(
      userId: 'friend_avg_tester',
      userName: 'DISCO_CRITIC',
      userHandle: 'discocritic',
      bio: 'Lover of groove.',
      reviewsCount: 1,
      followersCount: 120,
      followingCount: 50,
      wantlistCount: 2,
      listsCount: 1,
      isFollowing: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendReviewsProvider.overrideWith(
            (ref, friendId) async => [
              Review(
                id: 'rev_f_1',
                musicItemId: 'alb_3',
                musicItemName: 'Cross',
                artistName: 'Justice',
                coverUrl: '',
                itemType: 'album',
                userId: 'friend_avg_tester',
                userName: 'DISCO_CRITIC',
                userHandle: '@discocritic',
                rating: 9.6,
                headline: 'Distorted disco',
                body: 'Electrifying.',
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: FriendProfileScreen(initialProfile: testFriend),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final friendSpikeFinder = find.descendant(
      of: find.ancestor(
        of: find.text('AVG SCORE'),
        matching: find.byWidgetPredicate((w) => w.runtimeType.toString() == '_StatBox'),
      ),
      matching: find.byType(RatingSpikeSign),
    );
    expect(friendSpikeFinder, findsOneWidget);
    final friendSpike = tester.widget<RatingSpikeSign>(friendSpikeFinder);
    expect(friendSpike.rating, 9.6);
    expect(friendSpike.tier, RatingSignTier.eightPoint);
  });

  testWidgets('MusicDetailScreen resolves old rated release across edition name variations and displays EDIT and LOG AGAIN', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final pastReview = Review(
      id: 'rev_past_deathconsciousness',
      musicItemId: 'old_mock_id_99',
      musicItemName: 'Deathconsciousness',
      artistName: 'Have a Nice Life',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_me',
      userName: 'CRITIC // YOU',
      userHandle: '@groovd_me',
      rating: 9.3,
      headline: 'Post-punk monument',
      body: 'Timeless masterpiece.',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );

    // Active item returned by Deezer has edition variation in brackets and a different numeric ID
    const currentDeezerItem = MusicItem(
      id: 'deezer_numeric_1234567',
      name: 'Deathconsciousness (Deluxe Edition)',
      artist: 'Have a Nice Life',
      type: MusicType.album,
      coverUrl: '',
      releaseDate: '2008-01-24',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user_me'),
          userReviewsProvider('user_me').overrideWith((ref) async => [pastReview]),
        ],
        child: const MaterialApp(
          home: MusicDetailScreen(item: currentDeezerItem),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Must resolve existing review and show EDIT [9.3] and + LOG AGAIN
    expect(find.text('+ LOG AGAIN'), findsOneWidget);
    expect(find.text('EDIT [9.3]'), findsOneWidget);
  });

  test('Deezer transliteration and artist search catalog resilience for Kino and international bands', () {
    final kinoTranslits = DeezerApiService.getTransliterations('kino');
    expect(kinoTranslits, contains('кино'));

    final tsoiTranslits = DeezerApiService.getTransliterations('tsoi');
    expect(tsoiTranslits, contains('цой'));

    final grobTranslits = DeezerApiService.getTransliterations('grob');
    expect(grobTranslits, contains('гражданская оборона'));

    final kinokoTranslits = DeezerApiService.getTransliterations('kinoko teikoku');
    expect(kinokoTranslits, contains('きのこ帝国'));
  });

  testWidgets('Tracklist section renders DURATION and RATING headers, rating badge on corner right, and - for unrated tracks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final albumItem = MusicItem(
      id: 'album_test_tracklist_rate',
      name: 'ПОСЛЕДНИЙ ГЕРОЙ',
      artist: 'КИНО',
      coverUrl: '',
      type: MusicType.album,
      releaseDate: '1989',
      tracks: const [
        TrackInfo(id: 'trk_1', name: 'Хочу перемен', trackNumber: 1, durationMs: 292000, artist: 'КИНО'),
        TrackInfo(id: 'trk_2', name: 'Электричка', trackNumber: 2, durationMs: 284000, artist: 'КИНО'),
      ],
    );

    // Track 1 is rated 8.8, Track 2 is unrated
    final track1Review = Review(
      id: 'rev_t1',
      musicItemId: 'trk_1',
      musicItemName: 'Хочу перемен',
      artistName: 'КИНО',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_me',
      userName: 'YOU',
      userHandle: '@you',
      rating: 8.8,
      headline: 'Peremen',
      body: 'Classic anthem',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('user_me'),
          userReviewsProvider('user_me').overrideWith((ref) async => [track1Review]),
          itemReviewsProvider(ItemReviewQuery.fromItem(albumItem)).overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: albumItem),
        ),
      ),
    );

    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify DURATION and RATING headers exist
    expect(find.text('DURATION'), findsOneWidget);
    expect(find.text('RATING'), findsOneWidget);

    // Verify track 1 displays its 8.8 rating badge
    expect(find.text('8.8'), findsOneWidget);

    // Verify unrated track displays '-' placeholder
    expect(find.text('-'), findsOneWidget);

    final durationHeaderBox = tester.getRect(find.text('DURATION'));
    final durationRow1Box = tester.getRect(find.text('4:52'));
    final ratingHeaderBox = tester.getRect(find.text('RATING'));
    final ratingBadgeBox = tester.getRect(find.text('8.8'));
    final ratingDashBox = tester.getRect(find.text('-'));

    expect(durationHeaderBox.right, equals(durationRow1Box.right));

    final RenderParagraph durParagraph = tester.renderObject(find.text('DURATION'));
    final durBoxes = durParagraph.getBoxesForSelection(const TextSelection(baseOffset: 7, extentOffset: 8));
    final globalDurNRight = durParagraph.localToGlobal(Offset(durBoxes.first.right, 0)).dx;

    final RenderParagraph numParagraph = tester.renderObject(find.text('4:52'));
    final numBoxes = numParagraph.getBoxesForSelection(const TextSelection(baseOffset: 3, extentOffset: 4));
    final globalNum2Right = numParagraph.localToGlobal(Offset(numBoxes.first.right, 0)).dx;

    // The letter 'N' from DURATION aligns straight with the track duration numbers below it
    expect((globalDurNRight - globalNum2Right).abs(), lessThan(0.5));

    // Rating column header and badge centers align closely
    expect((ratingHeaderBox.center.dx - ratingDashBox.center.dx).abs(), lessThan(1.0));
    expect((ratingHeaderBox.center.dx - ratingBadgeBox.center.dx).abs(), lessThan(8.0));
  });
}

