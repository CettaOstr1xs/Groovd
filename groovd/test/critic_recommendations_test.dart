import 'package:flutter_test/flutter_test.dart';
import 'package:groovd/data/models/critic_recommendation_item.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/models/wishlist_item.dart';
import 'package:groovd/data/services/critic_chat_service.dart';
import 'package:groovd/data/services/critic_recommendations_service.dart';
import 'package:groovd/data/services/deezer_api_service.dart';
import 'package:groovd/data/services/spotify_api_service.dart';
import 'package:groovd/data/services/spotify_repository.dart';
import 'package:groovd/state/critic_recommendations_provider.dart';

void main() {
  group('CriticRecommendationItem Model Tests', () {
    test('serializes to map and back without loss', () {
      final now = DateTime(2026, 11, 17, 12, 0);
      final item = MusicItem(
        id: 'alb_ok_computer',
        name: 'OK Computer',
        artist: 'Radiohead',
        coverUrl: 'https://example.com/okc.jpg',
        releaseDate: '1997',
        type: MusicType.album,
      );

      final rec = CriticRecommendationItem(
        item: item,
        reasoning: 'Essential dystopian art rock matching your love for dense soundscapes.',
        vibeTag: '#ART_ROCK_MASTERPIECE',
        generatedAt: now,
      );

      final map = rec.toJson();
      expect(map['reasoning'], 'Essential dystopian art rock matching your love for dense soundscapes.');
      expect(map['vibeTag'], '#ART_ROCK_MASTERPIECE');
      expect(map['generatedAt'], now.toIso8601String());
      expect(map['item']['name'], 'OK Computer');

      final reconstructed = CriticRecommendationItem.fromJson(map);
      expect(reconstructed.item.name, 'OK Computer');
      expect(reconstructed.item.artist, 'Radiohead');
      expect(reconstructed.reasoning, rec.reasoning);
      expect(reconstructed.vibeTag, rec.vibeTag);
      expect(reconstructed.generatedAt, now);
    });

    test('copyWith properly duplicates or overrides fields', () {
      final rec = CriticRecommendationItem(
        item: const MusicItem(
          id: '1',
          name: 'Loveless',
          artist: 'My Bloody Valentine',
          coverUrl: '',
          releaseDate: '1991',
          type: MusicType.album,
        ),
        reasoning: 'Gaze essential.',
        vibeTag: '#SHOEGAZE',
        generatedAt: DateTime(2026, 11, 1),
      );

      final updated = rec.copyWith(
        vibeTag: '#WALL_OF_SOUND',
      );

      expect(updated.vibeTag, '#WALL_OF_SOUND');
      expect(updated.reasoning, 'Gaze essential.');
      expect(updated.item.name, 'Loveless');
    });
  });

  group('Critic Taste Grounding for Recommendations Tests', () {
    test('buildRecommendationGroundingPrompt excludes already reviewed and wantlist albums', () {
      final reviews = [
        Review(
          id: 'rev_1',
          musicItemId: 'alb_1',
          musicItemName: 'Loveless',
          artistName: 'My Bloody Valentine',
          coverUrl: '',
          itemType: 'album',
          userId: 'user_1',
          userName: 'Critic',
          userHandle: '@critic',
          rating: 9.8,
          headline: 'Peak shoegaze',
          body: '',
          tags: ['#SHOEGAZE', '#ESSENTIAL'],
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'rev_2',
          musicItemId: 'alb_2',
          musicItemName: 'In Rainbows',
          artistName: 'Radiohead',
          coverUrl: '',
          itemType: 'album',
          userId: 'user_1',
          userName: 'Critic',
          userHandle: '@critic',
          rating: 9.5,
          headline: 'Warm perfection',
          body: '',
          tags: ['#ART_ROCK'],
          createdAt: DateTime.now(),
        ),
      ];

      final topAlbums = [
        const MusicItem(
          id: 'top_1',
          name: 'Souvlaki',
          artist: 'Slowdive',
          coverUrl: '',
          releaseDate: '1993',
          type: MusicType.album,
        ),
      ];

      final wishlist = [
        WishlistItem(
          musicItem: const MusicItem(
            id: 'wish_alb_1',
            name: 'Dummy',
            artist: 'Portishead',
            coverUrl: '',
            releaseDate: '1994',
            type: MusicType.album,
          ),
          addedAt: DateTime.now(),
        ),
      ];

      final prompt = CriticChatService.buildRecommendationGroundingPrompt(
        reviews: reviews,
        topAlbums: topAlbums,
        wishlist: wishlist,
      );

      expect(prompt, contains('Loveless'));
      expect(prompt, contains('Radiohead'));
      expect(prompt, contains('Souvlaki'));
      expect(prompt, contains('Dummy'));
      expect(prompt, contains('DO NOT recommend'));
      expect(prompt, contains('JSON'));
      expect(prompt, contains('7-8 exceptional, relevant albums'));
      expect(prompt, contains('STRICTLY NO individual tracks, songs, or standalone singles.'));
    });

    test('Cold-start rated album counter filters out song reviews', () {
      final reviews = [
        Review(
          id: 'rev_1',
          musicItemId: 'alb_1',
          musicItemName: 'Album 1',
          artistName: 'Artist 1',
          coverUrl: '',
          itemType: 'album',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 8.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'rev_2',
          musicItemId: 'alb_2',
          musicItemName: 'Album 2',
          artistName: 'Artist 2',
          coverUrl: '',
          itemType: 'album',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 8.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'rev_3',
          musicItemId: 'ep_1',
          musicItemName: 'EP 1',
          artistName: 'Artist 3',
          coverUrl: '',
          itemType: 'ep',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 8.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
        Review(
          id: 'rev_4',
          musicItemId: 'song_1',
          musicItemName: 'Song 1',
          artistName: 'Artist 4',
          coverUrl: '',
          itemType: 'song',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 9.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
      ];

      final eligibleCount = reviews.where((r) => r.itemType == 'album' || r.itemType == 'ep').length;
      expect(eligibleCount, 3);
    });
  });

  group('CriticRecommendationsService Tests', () {
    test('parseGeminiResponse parses raw JSON array and strips markdown code fences', () {
      final service = CriticRecommendationsService(
        spotifyRepository: SpotifyRepository(
          apiService: SpotifyApiService(),
          deezerService: DeezerApiService(),
        ),
      );

      const rawWithFences = '''
```json
[
  {
    "title": "Heaven or Las Vegas",
    "artist": "Cocteau Twins",
    "reasoning": "Ethereal dream pop perfection that defined the 4AD sound.",
    "vibe_tag": "#DREAM_POP_CANON"
  },
  {
    "title": "Spiderland",
    "artist": "Slint",
    "reasoning": "Tense post-rock cornerstone with dynamic spoken narratives.",
    "vibe_tag": "#POST_ROCK_CHILL"
  }
]
```
''';

      final parsed = service.parseGeminiResponse(rawWithFences);
      expect(parsed.length, 2);
      expect(parsed[0]['title'], 'Heaven or Las Vegas');
      expect(parsed[0]['artist'], 'Cocteau Twins');
      expect(parsed[0]['vibe_tag'], '#DREAM_POP_CANON');
      expect(parsed[1]['title'], 'Spiderland');
      expect(parsed[1]['artist'], 'Slint');
    });

    test('parseGeminiResponse handles malformed or non-JSON text gracefully', () {
      final service = CriticRecommendationsService(
        spotifyRepository: SpotifyRepository(
          apiService: SpotifyApiService(),
          deezerService: DeezerApiService(),
        ),
      );

      expect(service.parseGeminiResponse(''), isEmpty);
      expect(service.parseGeminiResponse('I am not returning JSON today'), isEmpty);
      expect(service.parseGeminiResponse('{"single_object": true}'), isEmpty);
    });

    test('deduplicates candidate items against reviews and wantlist', () {
      final service = CriticRecommendationsService(
        spotifyRepository: SpotifyRepository(
          apiService: SpotifyApiService(),
          deezerService: DeezerApiService(),
        ),
      );

      final reviews = [
        Review(
          id: 'r1',
          musicItemId: 'm1',
          musicItemName: 'Loveless',
          artistName: 'My Bloody Valentine',
          coverUrl: '',
          itemType: 'album',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 10.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
      ];

      final wishlist = [
        WishlistItem(
          musicItem: const MusicItem(
            id: 'w1',
            name: 'Dummy',
            artist: 'Portishead',
            coverUrl: '',
            releaseDate: '1994',
            type: MusicType.album,
          ),
          addedAt: DateTime.now(),
        ),
      ];

      // Loveless is reviewed, Dummy is in wantlist
      expect(service.isDuplicate(title: 'Loveless', artist: 'My Bloody Valentine', reviews: reviews, wishlist: wishlist), isTrue);
      expect(service.isDuplicate(title: 'Dummy', artist: 'Portishead', reviews: reviews, wishlist: wishlist), isTrue);
      expect(service.isDuplicate(title: 'Souvlaki', artist: 'Slowdive', reviews: reviews, wishlist: wishlist), isFalse);
    });

    test('filterReleasesOnly helper strictly keeps albums and EPs while dropping tracks', () {
      final items = [
        const MusicItem(id: '1', name: 'OK Computer', artist: 'Radiohead', coverUrl: '', releaseDate: '1997', type: MusicType.album),
        const MusicItem(id: '2', name: 'Creep', artist: 'Radiohead', coverUrl: '', releaseDate: '1992', type: MusicType.song),
        const MusicItem(id: '3', name: 'Airbag / How Am I Driving?', artist: 'Radiohead', coverUrl: '', releaseDate: '1998', type: MusicType.ep),
      ];

      final filtered = CriticRecommendationsService.filterReleasesOnly(items);
      expect(filtered.length, 2);
      expect(filtered.any((i) => i.id == '2'), isFalse);
      expect(filtered.any((i) => i.id == '1'), isTrue);
      expect(filtered.any((i) => i.id == '3'), isTrue);
    });
  });

  group('CriticRecommendationsNotifier State Tests', () {
    test('CriticRecommendationsState default values and copyWith', () {
      const state = CriticRecommendationsState();
      expect(state.items, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.hasSufficientRatings, isFalse);
      expect(state.errorMessage, isNull);

      final updated = state.copyWith(
        isLoading: true,
        hasSufficientRatings: true,
      );
      expect(updated.isLoading, isTrue);
      expect(updated.hasSufficientRatings, isTrue);
      expect(updated.items, isEmpty);
    });

    test('hasSufficientAlbums helper accurately gates at 5 album/EP reviews', () {
      final reviews4 = List.generate(
        4,
        (i) => Review(
          id: 'r_$i',
          musicItemId: 'm_$i',
          musicItemName: 'Album $i',
          artistName: 'Artist $i',
          coverUrl: '',
          itemType: 'album',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 8.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
      );

      expect(CriticRecommendationsNotifier.hasSufficientAlbums(reviews4), isFalse);

      final reviews5 = [
        ...reviews4,
        Review(
          id: 'r_ep',
          musicItemId: 'm_ep',
          musicItemName: 'EP 1',
          artistName: 'Artist EP',
          coverUrl: '',
          itemType: 'ep',
          userId: 'u',
          userName: 'c',
          userHandle: '@c',
          rating: 8.0,
          headline: '',
          body: '',
          createdAt: DateTime.now(),
        ),
      ];

      expect(CriticRecommendationsNotifier.hasSufficientAlbums(reviews5), isTrue);

      // Adding 10 song reviews to reviews4 must STILL be false
      final reviews4PlusSongs = [
        ...reviews4,
        ...List.generate(
          10,
          (i) => Review(
            id: 's_$i',
            musicItemId: 'sm_$i',
            musicItemName: 'Song $i',
            artistName: 'Artist $i',
            coverUrl: '',
            itemType: 'song',
            userId: 'u',
            userName: 'c',
            userHandle: '@c',
            rating: 9.0,
            headline: '',
            body: '',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      expect(CriticRecommendationsNotifier.hasSufficientAlbums(reviews4PlusSongs), isFalse);
    });
  });
}
