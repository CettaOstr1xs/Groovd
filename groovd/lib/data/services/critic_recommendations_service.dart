import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:groovd/core/constants/gemini_config.dart';
import '../models/critic_recommendation_item.dart';
import '../models/music_item.dart';
import '../models/review.dart';
import '../models/wishlist_item.dart';
import 'critic_chat_service.dart';
import 'spotify_repository.dart';

/// Service responsible for querying Gemini for album recommendations based on
/// user taste dossier and resolving matches into real catalog items.
class CriticRecommendationsService {
  final SpotifyRepository spotifyRepository;
  final String? apiKey;
  final GenerativeModel? customModel;

  CriticRecommendationsService({
    required this.spotifyRepository,
    this.apiKey,
    this.customModel,
  });

  /// Checks if a candidate release is already reviewed, pinned, or in the wantlist.
  bool isDuplicate({
    required String title,
    required String artist,
    List<Review> reviews = const [],
    List<WishlistItem> wishlist = const [],
    List<MusicItem> topAlbums = const [],
  }) {
    for (final r in reviews) {
      if (MusicItem.areTitlesEquivalent(title, r.musicItemName) &&
          MusicItem.areArtistsEquivalent(artist, r.artistName)) {
        return true;
      }
    }
    for (final w in wishlist) {
      if (MusicItem.areTitlesEquivalent(title, w.musicItem.name) &&
          MusicItem.areArtistsEquivalent(artist, w.musicItem.artist)) {
        return true;
      }
    }
    for (final a in topAlbums) {
      if (MusicItem.areTitlesEquivalent(title, a.name) &&
          MusicItem.areArtistsEquivalent(artist, a.artist)) {
        return true;
      }
    }
    return false;
  }

  /// Strictly filters a list of music items to releases only (albums and EPs),
  /// discarding standalone tracks and singles.
  static List<MusicItem> filterReleasesOnly(List<MusicItem> items) {
    return items.where((item) => item.isAlbum || item.isEp).toList();
  }

  /// Parses raw LLM response text into structured recommendation candidate maps.
  List<Map<String, String>> parseGeminiResponse(String rawResponse) {
    if (rawResponse.trim().isEmpty) return [];

    String cleaned = rawResponse.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.first.startsWith('```')) {
        lines.removeAt(0);
      }
      if (lines.isNotEmpty && lines.last.trim() == '```') {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }

    final startIdx = cleaned.indexOf('[');
    final endIdx = cleaned.lastIndexOf(']');
    if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
      return [];
    }

    final jsonSubstring = cleaned.substring(startIdx, endIdx + 1);

    try {
      final decoded = jsonDecode(jsonSubstring);
      if (decoded is! List) return [];

      final results = <Map<String, String>>[];
      for (final entry in decoded) {
        if (entry is Map) {
          final title = entry['title']?.toString().trim() ?? '';
          final artist = entry['artist']?.toString().trim() ?? '';
          final reasoning = entry['reasoning']?.toString().trim() ?? '';
          final vibeTag = entry['vibe_tag']?.toString().trim() ??
              entry['vibeTag']?.toString().trim() ??
              '#CRITIC_PICK';

          if (title.isNotEmpty && artist.isNotEmpty) {
            results.add({
              'title': title,
              'artist': artist,
              'reasoning': reasoning,
              'vibe_tag': vibeTag.startsWith('#') ? vibeTag : '#$vibeTag',
            });
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Queries Gemini with taste grounding and resolves results against Spotify/Deezer.
  Future<List<CriticRecommendationItem>> generateRecommendations({
    required List<Review> reviews,
    List<MusicItem> topAlbums = const [],
    List<WishlistItem> wishlist = const [],
    int targetCount = 5,
  }) async {
    final activeKey = apiKey?.trim().isNotEmpty == true
        ? apiKey!.trim()
        : GeminiConfig.defaultKey.trim();

    if (activeKey.isEmpty) {
      return [];
    }

    final prompt = CriticChatService.buildRecommendationGroundingPrompt(
      reviews: reviews,
      topAlbums: topAlbums,
      wishlist: wishlist,
    );

    final model = customModel ??
        GenerativeModel(
          model: GeminiConfig.modelName,
          apiKey: activeKey,
        );

    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text ?? '';
    final parsedEntries = parseGeminiResponse(rawText);

    if (parsedEntries.isEmpty) {
      return [];
    }

    final candidateFutures = parsedEntries.map((entry) async {
      final title = entry['title']!;
      final artist = entry['artist']!;
      final reasoning = entry['reasoning']!;
      final vibeTag = entry['vibe_tag']!;

      if (isDuplicate(
        title: title,
        artist: artist,
        reviews: reviews,
        wishlist: wishlist,
        topAlbums: topAlbums,
      )) {
        return null;
      }

      try {
        final searchResults = await spotifyRepository.search('$title $artist', type: MusicType.album);
        final releaseResults = filterReleasesOnly(searchResults);
        if (releaseResults.isEmpty) return null;

        MusicItem? matchedItem;
        for (final res in releaseResults) {
          if (MusicItem.areTitlesEquivalent(title, res.name)) {
            matchedItem = res;
            break;
          }
        }
        matchedItem ??= releaseResults.first;

        if (matchedItem.isAlbum || matchedItem.isEp) {
          if (!isDuplicate(
            title: matchedItem.name,
            artist: matchedItem.artist,
            reviews: reviews,
            wishlist: wishlist,
            topAlbums: topAlbums,
          )) {
            return CriticRecommendationItem(
              item: matchedItem,
              reasoning: reasoning,
              vibeTag: vibeTag,
              generatedAt: DateTime.now(),
            );
          }
        }
      } catch (_) {
        // Skip unresolvable item
      }
      return null;
    });

    final resolved = await Future.wait(candidateFutures);
    final recommendations = <CriticRecommendationItem>[];

    for (final item in resolved) {
      if (item != null) {
        final isAlreadyInBatch = recommendations.any((r) =>
            r.item.id == item.item.id ||
            (MusicItem.areTitlesEquivalent(r.item.name, item.item.name) &&
             MusicItem.areArtistsEquivalent(r.item.artist, item.item.artist)));
        if (!isAlreadyInBatch) {
          recommendations.add(item);
          if (recommendations.length >= targetCount) {
            break;
          }
        }
      }
    }

    return recommendations;
  }
}
