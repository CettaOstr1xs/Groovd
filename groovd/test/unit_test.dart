import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_api_service.dart';
import 'package:groovd/data/services/spotify_repository.dart';
import 'package:groovd/data/repositories/local_review_repository.dart';

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
}
