import '../models/music_item.dart';
import 'spotify_api_service.dart';
import 'spotify_mock_data.dart';

class SpotifyRepository {
  final SpotifyApiService apiService;

  SpotifyRepository({required this.apiService});

  bool get isLiveMode => apiService.isConfigured;

  Future<List<MusicItem>> getTrendingAlbums() async {
    if (isLiveMode) {
      final releases = await apiService.getNewReleases(limit: 10);
      if (releases.isNotEmpty) return releases;
      final searched = await apiService.search('tag:new', type: 'album', limit: 10);
      if (searched.isNotEmpty) return searched;
    }
    return SpotifyMockData.trendingAlbums;
  }

  Future<List<MusicItem>> getHotTracks() async {
    if (isLiveMode) {
      final searchResults = await apiService.search('top hits 2024', type: 'track', limit: 10);
      if (searchResults.isNotEmpty) return searchResults;
    }
    return SpotifyMockData.hotTracks;
  }

  Future<List<MusicItem>> search(String query, {MusicType? type}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      String typeParam = 'album,track';
      if (type == MusicType.album) typeParam = 'album';
      if (type == MusicType.song) typeParam = 'track';

      final results = await apiService.search(cleanQuery, type: typeParam, limit: 10);
      if (results.isNotEmpty) return results;
    }

    // Mock search fallback
    final q = cleanQuery.toLowerCase();
    return SpotifyMockData.allItems.where((item) {
      final matchesQuery = item.name.toLowerCase().contains(q) ||
          item.artist.toLowerCase().contains(q) ||
          item.genres.any((g) => g.toLowerCase().contains(q));
      if (type == null) return matchesQuery;
      return matchesQuery && item.type == type;
    }).toList();
  }

  Future<MusicItem?> getItemById(String id, {MusicType? type}) async {
    // Check mock items first
    try {
      final mock = SpotifyMockData.allItems.firstWhere((item) => item.id == id);
      return mock;
    } catch (_) {}

    if (isLiveMode) {
      if (type == MusicType.song) {
        return await apiService.getTrack(id);
      } else {
        final album = await apiService.getAlbum(id);
        if (album != null) return album;
        return await apiService.getTrack(id);
      }
    }

    return null;
  }
}
