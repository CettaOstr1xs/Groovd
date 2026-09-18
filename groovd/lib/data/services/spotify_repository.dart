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
      final searchResults = await apiService.search('year:2024', type: 'track', limit: 10);
      if (searchResults.isNotEmpty) {
        searchResults.sort((a, b) => b.popularity.compareTo(a.popularity));
        return searchResults;
      }
      final fallbackResults = await apiService.search('top hits', type: 'track', limit: 10);
      if (fallbackResults.isNotEmpty) {
        fallbackResults.sort((a, b) => b.popularity.compareTo(a.popularity));
        return fallbackResults;
      }
    }
    return [];
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
      if (type == MusicType.song || id.startsWith('track_')) {
        final track = await apiService.getTrack(id);
        if (track != null) return track;
      } else if (type == MusicType.album || id.startsWith('album_')) {
        final album = await apiService.getAlbum(id);
        if (album != null) return album;
      } else {
        final album = await apiService.getAlbum(id);
        if (album != null) return album;
        return await apiService.getTrack(id);
      }
    }

    return null;
  }

  /// Retrieves other albums and tracks by the specified artist, excluding the current item.
  Future<List<MusicItem>> getMoreByArtist(String artist, {String? currentItemId}) async {
    final cleanArtist = artist.trim();
    if (cleanArtist.isEmpty) return [];

    String primaryArtist = cleanArtist;
    if (!cleanArtist.toLowerCase().contains('the creator') && cleanArtist.contains(',')) {
      primaryArtist = cleanArtist.split(',').first.trim();
    }
    final primaryLower = primaryArtist.toLowerCase();

    if (isLiveMode) {
      List<MusicItem> results = await apiService.search('artist:"$primaryArtist"', type: 'album,track', limit: 10);
      if (results.isEmpty) {
        results = await apiService.search(primaryArtist, type: 'album,track', limit: 10);
      }

      if (results.isNotEmpty) {
        final filtered = <MusicItem>[];
        final seenIds = <String>{};
        if (currentItemId != null) seenIds.add(currentItemId);

        for (final item in results) {
          if (seenIds.contains(item.id)) continue;
          final itemArtistLower = item.artist.toLowerCase();
          if (itemArtistLower.contains(primaryLower) || primaryLower.contains(itemArtistLower)) {
            seenIds.add(item.id);
            filtered.add(item);
          }
        }

        if (filtered.isNotEmpty) return filtered;
      }
    }

    final filtered = <MusicItem>[];
    final seenIds = <String>{};
    if (currentItemId != null) seenIds.add(currentItemId);

    for (final item in SpotifyMockData.allItems) {
      if (seenIds.contains(item.id)) continue;
      final itemArtistLower = item.artist.toLowerCase();
      if (itemArtistLower.contains(primaryLower) || primaryLower.contains(itemArtistLower)) {
        seenIds.add(item.id);
        filtered.add(item);
      }
    }

    return filtered;
  }
}

