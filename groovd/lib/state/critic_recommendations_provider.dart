import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/critic_recommendation_item.dart';
import '../data/models/music_item.dart';
import '../data/models/review.dart';
import '../data/services/critic_recommendations_service.dart';
import 'dossier_top_picks_provider.dart';
import 'gemini_settings_provider.dart';
import 'music_providers.dart';
import 'review_providers.dart';
import 'wishlist_provider.dart';

/// State of the AI Critic Album Recommendations.
class CriticRecommendationsState {
  final List<CriticRecommendationItem> items;
  final bool isLoading;
  final bool hasSufficientRatings;
  final String? errorMessage;
  final DateTime? lastFetchedAt;

  const CriticRecommendationsState({
    this.items = const [],
    this.isLoading = false,
    this.hasSufficientRatings = false,
    this.errorMessage,
    this.lastFetchedAt,
  });

  CriticRecommendationsState copyWith({
    List<CriticRecommendationItem>? items,
    bool? isLoading,
    bool? hasSufficientRatings,
    String? errorMessage,
    DateTime? lastFetchedAt,
  }) {
    return CriticRecommendationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasSufficientRatings: hasSufficientRatings ?? this.hasSufficientRatings,
      errorMessage: errorMessage,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }
}

/// Singleton service provider for AI recommendations.
final criticRecommendationsServiceProvider = Provider<CriticRecommendationsService>((ref) {
  final repo = ref.watch(spotifyRepositoryProvider);
  final geminiSettings = ref.watch(geminiSettingsProvider);
  return CriticRecommendationsService(
    spotifyRepository: repo,
    apiKey: geminiSettings.apiKey,
  );
});

/// Riverpod Notifier managing recommendation lifecycle, caching, and cold-start gating.
class CriticRecommendationsNotifier extends Notifier<CriticRecommendationsState> {
  static const String _storageKey = 'groovd_ai_recommended_albums_v1';
  static const int minRequiredAlbums = 5;

  /// Helper to determine if user has rated at least 5 albums or EPs.
  static bool hasSufficientAlbums(List<Review> reviews) {
    return reviews.where((r) => r.itemType == 'album' || r.itemType == 'ep').length >= minRequiredAlbums;
  }

  List<Review> _getUserReviews() {
    final currentUserId = ref.read(currentUserIdProvider);
    final userReviews = ref.read(userReviewsProvider(currentUserId)).asData?.value ?? const [];
    final guestReviews = currentUserId != 'user_me'
        ? (ref.read(userReviewsProvider('user_me')).asData?.value ?? const [])
        : const <Review>[];
    return [...userReviews, ...guestReviews];
  }

  @override
  CriticRecommendationsState build() {
    ref.watch(currentUserIdProvider);

    // Defer loading cache / fetching to post-frame
    Future.microtask(() => _loadInitialRecommendations());

    return const CriticRecommendationsState(
      hasSufficientRatings: true,
      isLoading: true,
    );
  }

  Future<void> _loadInitialRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);

      if (rawList != null && rawList.isNotEmpty) {
        final cachedItems = <CriticRecommendationItem>[];
        for (final raw in rawList) {
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            cachedItems.add(CriticRecommendationItem.fromJson(json));
          } catch (_) {}
        }

        if (cachedItems.isNotEmpty) {
          state = state.copyWith(
            items: cachedItems,
            isLoading: false,
            hasSufficientRatings: true,
          );
          return;
        }
      }

      // If cache is empty and user has >= 5 rated albums, generate fresh
      await refreshRecommendations(forceReroll: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Refreshes recommendations from Gemini and updates persistence.
  Future<void> refreshRecommendations({bool forceReroll = false}) async {
    final reviews = _getUserReviews();

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final topPicks = ref.read(dossierTopPicksProvider);
      final topAlbums = topPicks.topAlbums.whereType<MusicItem>().toList();
      final wishlist = ref.read(wishlistProvider);
      final service = ref.read(criticRecommendationsServiceProvider);

      final freshRecommendations = await service.generateRecommendations(
        reviews: reviews,
        topAlbums: topAlbums,
        wishlist: wishlist,
      );

      if (freshRecommendations.isNotEmpty) {
        // Persist to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final rawList = freshRecommendations
            .map((rec) => jsonEncode(rec.toJson()))
            .toList();
        await prefs.setStringList(_storageKey, rawList);

        state = CriticRecommendationsState(
          items: freshRecommendations,
          isLoading: false,
          hasSufficientRatings: true,
          lastFetchedAt: DateTime.now(),
        );
      } else {
        // If service returns empty, keep old items if available
        state = state.copyWith(
          isLoading: false,
          errorMessage: state.items.isEmpty ? 'COULD NOT GENERATE PICKS' : null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'RECOMMENDATION RETRIEVAL ERROR',
      );
    }
  }

  /// Clears stored cache.
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      state = state.copyWith(items: []);
    } catch (_) {}
  }
}

/// Provider exposing the AI recommendations state.
final criticRecommendationsProvider =
    NotifierProvider<CriticRecommendationsNotifier, CriticRecommendationsState>(
  CriticRecommendationsNotifier.new,
);
