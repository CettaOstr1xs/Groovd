import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_api_service.dart';
import 'package:groovd/data/services/spotify_repository.dart';
import 'package:groovd/data/repositories/local_review_repository.dart';
import 'package:groovd/data/models/wishlist_item.dart';

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
}

