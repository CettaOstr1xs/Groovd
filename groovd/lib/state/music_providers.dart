import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/music_item.dart';
import '../data/services/spotify_api_service.dart';
import '../data/services/spotify_repository.dart';

/// Singleton SpotifyApiService
final spotifyApiServiceProvider = Provider<SpotifyApiService>((ref) {
  return SpotifyApiService();
});

/// Spotify Repository provider
final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  final api = ref.watch(spotifyApiServiceProvider);
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

/// Music Item Detail Provider by ID
final musicItemDetailProvider = FutureProvider.family<MusicItem?, String>((ref, id) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.getItemById(id);
});
