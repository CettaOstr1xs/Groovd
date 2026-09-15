import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/spotify_config.dart';
import '../data/models/music_item.dart';
import '../data/services/spotify_api_service.dart';
import '../data/services/spotify_repository.dart';
import 'settings_provider.dart';

/// Singleton SpotifyApiService initialized with default config credentials
final spotifyApiServiceProvider = Provider<SpotifyApiService>((ref) {
  return SpotifyApiService(
    clientId: SpotifyConfig.clientId.trim().isNotEmpty ? SpotifyConfig.clientId.trim() : null,
    clientSecret: SpotifyConfig.clientSecret.trim().isNotEmpty ? SpotifyConfig.clientSecret.trim() : null,
  );
});

/// Spotify Repository provider
final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  final api = ref.watch(spotifyApiServiceProvider);
  // Reactively track settings changes
  ref.watch(spotifySettingsProvider);
  return SpotifyRepository(apiService: api);
});

/// Trending Albums on Groovd
final trendingAlbumsProvider = FutureProvider<List<MusicItem>>((ref) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getTrendingAlbums();
});

/// Hot Tracks on Groovd
final hotTracksProvider = FutureProvider<List<MusicItem>>((ref) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getHotTracks();
});

/// Search Query Notifier
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String newQuery) => state = newQuery;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Search Filter Type Notifier (null for ALL, MusicType.album, MusicType.song)
class SearchFilterNotifier extends Notifier<MusicType?> {
  @override
  MusicType? build() => null;

  void updateFilter(MusicType? newFilter) => state = newFilter;
}

final searchFilterProvider = NotifierProvider<SearchFilterNotifier, MusicType?>(SearchFilterNotifier.new);

/// Search Results Provider
final searchResultsProvider = FutureProvider<List<MusicItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final filter = ref.watch(searchFilterProvider);
  final repo = ref.watch(spotifyRepositoryProvider);

  if (query.trim().isEmpty) {
    final albums = await repo.getTrendingAlbums();
    final tracks = await repo.getHotTracks();
    final combined = [...albums, ...tracks];
    if (filter == null) return combined;
    return combined.where((item) => item.type == filter).toList();
  }

  return repo.search(query, type: filter);
});

/// Query parameter for music detail lookup
class ItemQuery {
  final String id;
  final MusicType? type;

  const ItemQuery({required this.id, this.type});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemQuery &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ (type?.hashCode ?? 0);
}

/// Music Item Detail Provider by ItemQuery
final musicItemDetailProvider = FutureProvider.family<MusicItem?, ItemQuery>((ref, query) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getItemById(query.id, type: query.type);
});
