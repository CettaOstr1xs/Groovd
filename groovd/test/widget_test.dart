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
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_mock_data.dart';
import 'package:groovd/data/models/artist.dart';
import 'package:groovd/presentation/screens/artist/artist_detail_screen.dart';
import 'package:groovd/presentation/screens/profile/all_rated_releases_screen.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/auth/login_screen.dart';
import 'package:groovd/presentation/screens/auth/register_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';
import 'package:groovd/state/artist_providers.dart';
import 'package:groovd/state/review_providers.dart';

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

  testWidgets('ReviewDetailScreen share button launches Instagram Story designer modal', (WidgetTester tester) async {
    final review = SpotifyMockData.seedReviews.first;

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

    // Verify Settings modal shows Critic Identity Card
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
          itemReviewsProvider('m_already_rated').overrideWith((ref) => Future.value([myReview])),
        ],
        child: MaterialApp(
          home: MusicDetailScreen(item: musicItem),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Verify the bottom action bar displays 'EDIT YOUR REVIEW [9.8]' instead of '+ LOG YOUR REVIEW'
    expect(find.text('EDIT YOUR REVIEW [9.8]'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
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
}


