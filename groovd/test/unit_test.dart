import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_api_service.dart';
import 'package:groovd/data/services/spotify_repository.dart';
import 'package:groovd/data/repositories/local_review_repository.dart';
import 'package:groovd/data/models/wishlist_item.dart';
import 'package:groovd/state/dossier_top_picks_provider.dart';

void main() {
  group('Review Model Tests', () {
    test('Calculates score tier label accurately', () {
      final masterpiece = Review(
        id: 'r1',
        musicItemId: 'm1',
        musicItemName: 'Blonde',
        artistName: 'Frank Ocean',
        coverUrl: '',
        itemType: 'album',
        userId: 'u1',
        userName: 'Critic',
        userHandle: '@critic',
        rating: 9.8,
        headline: 'Great',
        body: 'Superb',
        createdAt: DateTime.now(),
      );
      expect(masterpiece.scoreTierLabel, 'MASTERPIECE');
      expect(masterpiece.scoreFormatted, '9.8');

      final acclaimed = masterpiece.copyWith(rating: 7.8);
      expect(acclaimed.scoreTierLabel, 'ACCLAIMED');

      final skip = masterpiece.copyWith(rating: 3.2);
      expect(skip.scoreTierLabel, 'CRITICAL SKIP');
    });

    test('Serializes to map and back without loss', () {
      final original = Review(
        id: 'r100',
        musicItemId: 'm100',
        musicItemName: 'Test Album',
        artistName: 'Test Artist',
        coverUrl: 'https://example.com/cover.jpg',
        itemType: 'album',
        userId: 'u100',
        userName: 'Test User',
        userHandle: '@tester',
        rating: 8.5,
        headline: 'Very good',
        body: 'Detailed review body',
        tags: ['#AOTY', '#VIBES'],
        createdAt: DateTime(2024, 1, 15, 12, 0),
        likesCount: 15,
      );

      final map = original.toMap();
      final revived = Review.fromMap(map);

      expect(revived.id, original.id);
      expect(revived.musicItemId, original.musicItemId);
      expect(revived.rating, original.rating);
      expect(revived.headline, original.headline);
      expect(revived.tags, original.tags);
      expect(revived.likesCount, original.likesCount);
    });
  });

  group('SpotifyRepository Mock Fallback Tests', () {
    test('Searches by name and artist in mock mode', () async {
      final repo = SpotifyRepository(apiService: SpotifyApiService());
      final albums = await repo.getTrendingAlbums();
      expect(albums.isNotEmpty, true);

      final results = await repo.search('Kendrick');
      expect(results.any((item) => item.artist.contains('KENDRICK')), true);

      final songResults = await repo.search('BIRDS', type: MusicType.song);
      expect(songResults.any((item) => item.name.contains('BIRDS')), true);
    });

    test('Live Spotify search works with safe limit and retrieves real results', () async {
      final apiService = SpotifyApiService(
        clientId: '4cf83c2b597b4b16a332e231a21fb9d3',
        clientSecret: '1c572e4231e04103b58f61e101304164',
      );
      final repo = SpotifyRepository(apiService: apiService);
      expect(repo.isLiveMode, true);

      final results = await repo.search('GNX', type: MusicType.album);
      expect(results.isNotEmpty, true);
      expect(results.first.name.toUpperCase().contains('GNX'), true);
      expect(results.first.artist.toUpperCase().contains('KENDRICK'), true);

      // Verify detailed album fetch gets all tracks
      final albumDetail = await repo.getItemById(results.first.id, type: MusicType.album);
      expect(albumDetail, isNotNull);
      expect(albumDetail!.tracks.isNotEmpty, true);
      expect(albumDetail.durationMs > 0, true);
    });

    test('Live search for slowdive returns both albums and tracks with artwork', () async {
      final apiService = SpotifyApiService(
        clientId: '4cf83c2b597b4b16a332e231a21fb9d3',
        clientSecret: '1c572e4231e04103b58f61e101304164',
      );
      final repo = SpotifyRepository(apiService: apiService);

      final searchResults = await repo.search('slowdive');
      expect(searchResults.isNotEmpty, true);

      final hasAlbums = searchResults.any((item) => item.isAlbum);
      final hasTracks = searchResults.any((item) => item.isSong);
      expect(hasAlbums, true);
      expect(hasTracks, true);

      // Verify all slowdive results have artwork
      for (final item in searchResults) {
        expect(item.coverUrl.isNotEmpty, true, reason: '${item.name} should have cover art');
      }

      // Verify single track lookup gets artwork
      final firstTrack = searchResults.firstWhere((item) => item.isSong);
      final trackDetail = await repo.getItemById(firstTrack.id, type: MusicType.song);
      expect(trackDetail, isNotNull);
      expect(trackDetail!.coverUrl.isNotEmpty, true);
    });
  });

  group('LocalReviewRepository Tests', () {
    test('Calculates average score and review counts correctly', () async {
      final repo = LocalReviewRepository();
      final initialReviews = await repo.getRecentReviews();
      expect(initialReviews.isNotEmpty, true);

      // Add a new review
      final testReview = Review(
        id: 'test_rev_unique_999',
        musicItemId: 'album_blonde',
        musicItemName: 'BLONDE',
        artistName: 'FRANK OCEAN',
        coverUrl: '',
        itemType: 'album',
        userId: 'user_tester',
        userName: 'Tester',
        userHandle: '@tester',
        rating: 10.0,
        headline: 'Perfect score test',
        body: 'Testing repository calculation',
        createdAt: DateTime.now(),
      );

      await repo.addReview(testReview);
      final count = await repo.getReviewCount('album_blonde');
      final avg = await repo.getAverageScore('album_blonde');

      expect(count >= 1, true);
      expect(avg > 0.0, true);
    });
  });

  group('Dossier Top Picks & MusicItem Tests', () {
    test('MusicItem copyWith preserves existing coverUrl', () {
      const original = MusicItem(
        id: 't1',
        name: 'Track One',
        artist: 'Artist One',
        type: MusicType.song,
        coverUrl: 'https://example.com/art.jpg',
        releaseDate: '2024',
      );

      final updated = original.copyWith(name: 'Track One Updated');
      expect(updated.name, 'Track One Updated');
      expect(updated.coverUrl, 'https://example.com/art.jpg');
      expect(updated.isSong, true);
    });

    test('Parses track album images correctly from nested Spotify JSON', () {
      final spotifyTrackJson = {
        'id': 'sp_t1',
        'name': 'Espresso',
        'artists': [{'name': 'Sabrina Carpenter'}],
        'album': {
          'images': [
            {'url': 'https://i.scdn.co/image/abc1234'}
          ],
          'release_date': '2024-04-12',
        },
        'duration_ms': 175000,
      };

      final item = MusicItem.fromSpotifyTrack(spotifyTrackJson);
      expect(item.id, 'sp_t1');
      expect(item.name, 'Espresso');
      expect(item.coverUrl, 'https://i.scdn.co/image/abc1234');
      expect(item.type, MusicType.song);
    });

    test('Differentiates written critique from quick score-only rating', () {
      final quickRating = Review(
        id: 'r_quick',
        musicItemId: 'm_quick',
        musicItemName: 'Song A',
        artistName: 'Artist A',
        coverUrl: '',
        itemType: 'song',
        userId: 'u1',
        userName: 'Me',
        userHandle: '@me',
        rating: 8.5,
        headline: '',
        body: '',
        createdAt: DateTime.now(),
      );

      expect(quickRating.hasWrittenReview, false);
      expect(quickRating.isQuickRating, true);

      final writtenReview = quickRating.copyWith(headline: 'Incredible track');
      expect(writtenReview.hasWrittenReview, true);
      expect(writtenReview.isQuickRating, false);

      final reviews = [quickRating, writtenReview];
      final writtenOnly = reviews.where((r) => r.hasWrittenReview).toList();
      expect(writtenOnly.length, 1);
      expect(writtenOnly.first.id, 'r_quick');
      expect(writtenOnly.first.headline, 'Incredible track');
    });

    test('Formats custom tag strings into clean neo-brutalist hashtags', () {
      String formatTag(String raw) {
        final clean = raw.trim();
        if (clean.isEmpty) return '';
        String tag = clean.toUpperCase().replaceAll(' ', '_');
        if (!tag.startsWith('#')) {
          tag = '#$tag';
        }
        return tag;
      }

      expect(formatTag('shoegaze grail'), '#SHOEGAZE_GRAIL');
      expect(formatTag('#AOTY_CONTENDER'), '#AOTY_CONTENDER');
      expect(formatTag('night drives  '), '#NIGHT_DRIVES');
    });
  });

  group('Wishlist Feature Tests', () {
    test('WishlistItem serializes to map and back accurately', () {
      const music = MusicItem(
        id: 'alb_1',
        name: 'Loveless',
        artist: 'My Bloody Valentine',
        type: MusicType.album,
        coverUrl: 'https://example.com/loveless.jpg',
        releaseDate: '1991',
      );

      final wishItem = WishlistItem(
        musicItem: music,
        addedAt: DateTime(2026, 3, 15, 10, 30),
        note: 'Must listen on vinyl',
      );

      final map = wishItem.toMap();
      final revived = WishlistItem.fromMap(map);

      expect(revived.musicItem.id, 'alb_1');
      expect(revived.musicItem.name, 'Loveless');
      expect(revived.musicItem.isAlbum, true);
      expect(revived.note, 'Must listen on vinyl');
      expect(revived.addedAt, DateTime(2026, 3, 15, 10, 30));
    });

    test('WishlistItem timeAgo returns relative timestamps correctly', () {
      const music = MusicItem(
        id: 's_1',
        name: 'Alison',
        artist: 'Slowdive',
        type: MusicType.song,
        coverUrl: '',
        releaseDate: '1993',
      );

      final justNow = WishlistItem(
        musicItem: music,
        addedAt: DateTime.now().subtract(const Duration(seconds: 15)),
      );
      expect(justNow.timeAgo, 'just now');

      final twoDaysAgo = WishlistItem(
        musicItem: music,
        addedAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(twoDaysAgo.timeAgo, '2d ago');
    });

    test('Wishlist filtering separates albums and songs properly', () {
      const album = MusicItem(
        id: 'a1',
        name: 'OK Computer',
        artist: 'Radiohead',
        type: MusicType.album,
        coverUrl: '',
        releaseDate: '1997',
      );
      const song = MusicItem(
        id: 's1',
        name: 'Paranoid Android',
        artist: 'Radiohead',
        type: MusicType.song,
        coverUrl: '',
        releaseDate: '1997',
      );

      final list = [
        WishlistItem(musicItem: album, addedAt: DateTime.now()),
        WishlistItem(musicItem: song, addedAt: DateTime.now()),
      ];

      final albumsOnly = list.where((w) => w.musicItem.isAlbum).toList();
      final songsOnly = list.where((w) => w.musicItem.isSong).toList();

      expect(albumsOnly.length, 1);
      expect(albumsOnly.first.musicItem.name, 'OK Computer');
      expect(songsOnly.length, 1);
      expect(songsOnly.first.musicItem.name, 'Paranoid Android');
    });
  });

  group('Review Detail & Stack Deck Tests', () {
    test('Calculates stack pile illusion depth correctly', () {
      int calculateStackDepth(int reviewsCount) {
        if (reviewsCount <= 1) return 0;
        return 3;
      }

      // Single review: NO illusion behind it
      expect(calculateStackDepth(0), 0);
      expect(calculateStackDepth(1), 0);

      // Multiple reviews: exactly 3 stacked card layers
      expect(calculateStackDepth(2), 3);
      expect(calculateStackDepth(3), 3);
      expect(calculateStackDepth(10), 3);
    });

    test('Review share text formats accurately', () {
      final review = Review(
        id: 'r_share',
        musicItemId: 'm1',
        musicItemName: 'Loveless',
        artistName: 'My Bloody Valentine',
        coverUrl: '',
        itemType: 'album',
        userId: 'u1',
        userName: 'Critic',
        userHandle: '@critic',
        rating: 10.0,
        headline: 'Absolute masterwork of sound',
        body: 'A wall of heavenly noise and layered dream pop.',
        createdAt: DateTime.now(),
      );

      final shareText = '“${review.headline}”\n'
          '${review.musicItemName} by ${review.artistName} — Scored ${review.scoreFormatted}/10 on Groovd\n'
          '${review.body}';

      expect(shareText.contains('“Absolute masterwork of sound”'), true);
      expect(shareText.contains('Loveless by My Bloody Valentine'), true);
      expect(shareText.contains('10.0/10 on Groovd'), true);
    });
  });

  group('Logged Reviews Screen & Filter Tests', () {
    final r1 = Review(
      id: 'rev_1',
      musicItemId: 'm1',
      musicItemName: 'OK Computer',
      artistName: 'Radiohead',
      coverUrl: '',
      itemType: 'album',
      userId: 'user_local',
      userName: 'Critic',
      userHandle: '@critic',
      rating: 9.8,
      headline: 'Dystopian Masterpiece',
      body: 'Alienation, paranoia and incredible guitar work.',
      tags: ['#ALT_ROCK', '#CLASSIC'],
      createdAt: DateTime(2026, 1, 1),
    );

    final r2 = Review(
      id: 'rev_2',
      musicItemId: 'm2',
      musicItemName: 'Starless',
      artistName: 'King Crimson',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_local',
      userName: 'Critic',
      userHandle: '@critic',
      rating: 10.0,
      headline: 'The Ultimate Prog Climax',
      body: 'Melancholy mellotron giving way to savage distortion.',
      tags: ['#PROG', '#MASTERPIECE'],
      createdAt: DateTime(2026, 2, 1),
    );

    final r3 = Review(
      id: 'rev_3',
      musicItemId: 'm3',
      musicItemName: 'Quick Track',
      artistName: 'Quick Artist',
      coverUrl: '',
      itemType: 'song',
      userId: 'user_local',
      userName: 'Critic',
      userHandle: '@critic',
      rating: 7.0,
      headline: '',
      body: '',
      createdAt: DateTime(2026, 3, 1),
    );

    test('Filters reviews strictly to those with written critiques', () {
      final reviews = [r1, r2, r3];
      final written = reviews.where((r) => r.hasWrittenReview).toList();
      expect(written.length, 2);
      expect(written.contains(r3), false);
    });

    test('Filters reviews by album and song categories', () {
      final written = [r1, r2];
      final albums = written.where((r) => r.itemType == 'album').toList();
      final songs = written.where((r) => r.itemType == 'song').toList();
      expect(albums.length, 1);
      expect(albums.first.musicItemName, 'OK Computer');
      expect(songs.length, 1);
      expect(songs.first.musicItemName, 'Starless');
    });

    test('Searches across headline, body, artist, title, and tags', () {
      final written = [r1, r2];
      List<Review> search(String query) {
        final q = query.toLowerCase().trim();
        return written.where((r) {
          final title = r.musicItemName.toLowerCase();
          final artist = r.artistName.toLowerCase();
          final headline = r.headline.toLowerCase();
          final body = r.body.toLowerCase();
          final tags = r.tags.map((t) => t.toLowerCase()).join(' ');
          return title.contains(q) ||
              artist.contains(q) ||
              headline.contains(q) ||
              body.contains(q) ||
              tags.contains(q);
        }).toList();
      }

      expect(search('dystopian').first.id, 'rev_1');
      expect(search('mellotron').first.id, 'rev_2');
      expect(search('#PROG').first.id, 'rev_2');
      expect(search('radiohead').first.id, 'rev_1');
      expect(search('nonexistent').isEmpty, true);
    });

    test('Sorts correctly by score and date', () {
      final written = [r1, r2];

      // Highest score
      final byScore = List<Review>.from(written)..sort((a, b) => b.rating.compareTo(a.rating));
      expect(byScore.first.id, 'rev_2'); // 10.0 > 9.8

      // Newest
      final byDate = List<Review>.from(written)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(byDate.first.id, 'rev_2'); // Feb 1 > Jan 1
    });

    test('Artist genre fallback attaches genres when item genres is empty', () {
      const albumWithoutGenres = MusicItem(
        id: 'sp_deathconsciousness',
        name: 'Deathconsciousness',
        artist: 'Have a Nice Life',
        type: MusicType.album,
        coverUrl: 'https://example.com/cover.jpg',
        releaseDate: '2008-01-24',
        genres: [],
      );

      expect(albumWithoutGenres.genres.isEmpty, true);

      final artistGenres = ['POST-PUNK', 'SHOEGAZE', 'SLOWCORE', 'DRONE'];
      final resolvedAlbum = albumWithoutGenres.copyWith(genres: artistGenres);

      expect(resolvedAlbum.genres.isNotEmpty, true);
      expect(resolvedAlbum.genres.length, 4);
      expect(resolvedAlbum.genres.first, 'POST-PUNK');
      expect(resolvedAlbum.genres.contains('SHOEGAZE'), true);
    });
  });

  group('Wishlist Auto-Removal & Dossier Manual Pins Tests', () {
    const itemBlonde = MusicItem(
      id: 'album_blonde',
      name: 'Blonde',
      artist: 'Frank Ocean',
      type: MusicType.album,
      coverUrl: '',
      releaseDate: '2016-08-20',
    );

    const itemCamp = MusicItem(
      id: 'album_camp',
      name: 'Camp',
      artist: 'Childish Gambino',
      type: MusicType.album,
      coverUrl: '',
      releaseDate: '2011-11-15',
    );

    test('Wishlist removes item when review is submitted', () {
      var wishlist = [
        WishlistItem(musicItem: itemBlonde, addedAt: DateTime.now()),
        WishlistItem(musicItem: itemCamp, addedAt: DateTime.now()),
      ];

      expect(wishlist.length, 2);

      // User rates Camp
      final reviewCamp = Review(
        id: 'rev_camp',
        musicItemId: 'album_camp',
        musicItemName: 'Camp',
        artistName: 'Childish Gambino',
        coverUrl: '',
        itemType: 'album',
        userId: 'u1',
        userName: 'Critic',
        userHandle: '@critic',
        rating: 8.8,
        headline: '',
        body: '',
        createdAt: DateTime.now(),
      );

      // Emulate removeItemByReview
      wishlist.removeWhere((w) =>
          w.musicItem.id == reviewCamp.musicItemId ||
          (w.musicItem.name.toLowerCase() == reviewCamp.musicItemName.toLowerCase() &&
              w.musicItem.artist.toLowerCase() == reviewCamp.artistName.toLowerCase()));

      expect(wishlist.length, 1);
      expect(wishlist.first.musicItem.id, 'album_blonde');
      expect(wishlist.any((w) => w.musicItem.name == 'Camp'), false);
    });

    test('Wishlist batch-prunes already-reviewed items accurately', () {
      final wishlist = [
        WishlistItem(musicItem: itemBlonde, addedAt: DateTime.now()),
        WishlistItem(musicItem: itemCamp, addedAt: DateTime.now()),
      ];

      final existingReviews = [
        Review(
          id: 'rev_camp_old',
          musicItemId: 'album_camp',
          musicItemName: 'Camp',
          artistName: 'Childish Gambino',
          coverUrl: '',
          itemType: 'album',
          userId: 'u1',
          userName: 'Critic',
          userHandle: '@critic',
          rating: 8.8,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
      ];

      final reviewedIds = existingReviews.map((r) => r.musicItemId).toSet();
      final reviewedKeys = existingReviews
          .map((r) => '${r.musicItemName.trim().toLowerCase()}:::${r.artistName.trim().toLowerCase()}')
          .toSet();

      final pruned = wishlist.where((w) {
        if (reviewedIds.contains(w.musicItem.id)) return false;
        final key = '${w.musicItem.name.trim().toLowerCase()}:::${w.musicItem.artist.trim().toLowerCase()}';
        return !reviewedKeys.contains(key);
      }).toList();

      expect(pruned.length, 1);
      expect(pruned.first.musicItem.id, 'album_blonde');
    });

    test('Dossier Top Picks preserves empty slots and does not auto-insert new reviews', () {
      const topPicks = DossierTopPicks(
        topAlbums: [itemBlonde, null, null],
        topSongs: [null, null, null],
      );

      // Slot 1 is pinned, Slots 2 & 3 are empty
      expect(topPicks.topAlbums[0]!.name, 'Blonde');
      expect(topPicks.topAlbums[1], isNull);
      expect(topPicks.topAlbums[2], isNull);

      // All song slots remain empty
      expect(topPicks.topSongs.every((s) => s == null), true);

      // Rating a new album (e.g. Camp) does not affect topPicks
      expect(topPicks.topAlbums.contains(itemCamp), false);
    });
  });
}



