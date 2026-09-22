import '../models/artist.dart';
import '../models/music_item.dart';
import 'spotify_api_service.dart';
import 'spotify_mock_data.dart';
import 'wikipedia_api_service.dart';

class SpotifyRepository {
  final SpotifyApiService apiService;
  final WikipediaApiService wikipediaService;

  SpotifyRepository({
    required this.apiService,
    WikipediaApiService? wikipediaService,
  }) : wikipediaService = wikipediaService ?? WikipediaApiService();

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

  /// Retrieves an artist by Spotify ID or name, enriched with Wikipedia biographical summary.
  Future<Artist?> getArtist(String artistIdOrName) async {
    final clean = artistIdOrName.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();

    // Check mock data first if it's a known mock ID
    final mockById = SpotifyMockData.mockArtists.where((a) => a.id == clean || a.name.toLowerCase() == lower).firstOrNull;

    if (isLiveMode) {
      Map<String, dynamic>? artistJson;
      // If it looks like a clean Spotify ID (alphanumeric, no spaces, length around 22)
      if (!clean.contains(' ') && !clean.startsWith('artist_')) {
        artistJson = await apiService.getArtist(clean);
      }

      // Search by artist name if not found by ID
      if (artistJson == null) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        artistJson = await apiService.searchArtist(nameToSearch);
      }

      if (artistJson != null) {
        var artist = Artist.fromSpotifyJson(artistJson);
        // Fetch bio from Wikipedia
        try {
          final wiki = await wikipediaService.getArtistSummary(artist.name);
          if (wiki != null) {
            artist = artist.copyWith(
              bio: wiki.extract,
              shortDescription: wiki.description,
            );
          }
        } catch (_) {}
        return artist;
      }
    }

    if (mockById != null) {
      return mockById;
    }

    // Generic fallback: check if any items in mock data match this artist
    final matchingItems = SpotifyMockData.allItems.where((i) => i.artist.toLowerCase().contains(lower)).toList();
    if (matchingItems.isNotEmpty) {
      final first = matchingItems.first;
      final genres = matchingItems.expand((i) => i.genres).toSet().toList();
      return Artist(
        id: 'artist_${first.artist.toLowerCase().replaceAll(' ', '_')}',
        name: first.artist.toUpperCase(),
        imageUrl: first.coverUrl,
        genres: genres.take(4).toList(),
        followers: 1200000,
        popularity: 75,
        bio: '${first.artist} is a renowned musical artist with acclaimed works archived in Groovd.',
        shortDescription: 'Musical artist',
      );
    }

    return null;
  }

  /// Search Spotify or catalog for artists matching the query
  Future<List<Artist>> searchArtists(String query, {int limit = 5}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      final artistsJson = await apiService.searchArtists(cleanQuery, limit: limit);
      if (artistsJson.isNotEmpty) {
        final list = <Artist>[];
        for (final json in artistsJson) {
          list.add(Artist.fromSpotifyJson(json));
        }
        return list;
      }
    }

    // Mock search fallback
    final q = cleanQuery.toLowerCase();
    final results = <Artist>[];
    final seenNames = <String>{};

    for (final a in SpotifyMockData.mockArtists) {
      if (a.name.toLowerCase().contains(q)) {
        seenNames.add(a.name.toLowerCase());
        results.add(a);
      }
    }

    for (final item in SpotifyMockData.allItems) {
      final nameLower = item.artist.toLowerCase();
      if (nameLower.contains(q) && !seenNames.contains(nameLower)) {
        seenNames.add(nameLower);
        results.add(
          Artist(
            id: 'artist_${item.artist.toLowerCase().replaceAll(' ', '_')}',
            name: item.artist.toUpperCase(),
            imageUrl: item.coverUrl,
            genres: item.genres,
            followers: 1200000,
            popularity: 75,
            bio: '${item.artist} is an archived artist on Groovd.',
            shortDescription: 'Musical artist',
          ),
        );
      }
    }

    return results.take(limit).toList();
  }

  /// Retrieves featured mock artists for initial display (empty in live catalog)
  Future<List<Artist>> getFeaturedArtists() async {
    return [];
  }

  /// Retrieves the artist's top tracks.
  Future<List<MusicItem>> getArtistTopTracks(String artistIdOrName) async {
    final clean = artistIdOrName.trim();
    if (clean.isEmpty) return [];

    final lower = clean.toLowerCase();
    final mockById = SpotifyMockData.mockArtists.where((a) => a.id == clean || a.name.toLowerCase() == lower).firstOrNull;

    if (isLiveMode) {
      String? resolvedId = clean;
      String queryName = clean;
      if (clean.contains(' ') || clean.startsWith('artist_')) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        queryName = nameToSearch;
        final searchResult = await apiService.searchArtist(nameToSearch);
        resolvedId = searchResult?['id'] as String?;
        if (searchResult?['name'] != null) {
          queryName = searchResult!['name'] as String;
        }
      } else {
        final artistData = await apiService.getArtist(clean);
        if (artistData?['name'] != null) {
          queryName = artistData!['name'] as String;
        }
      }

      if (resolvedId != null && resolvedId.isNotEmpty) {
        final tracks = await apiService.getArtistTopTracks(resolvedId, artistName: queryName);
        if (tracks.isNotEmpty) return tracks;
      }

      // Secondary search fallback directly
      final searchedTracks = await apiService.search('artist:"$queryName"', type: 'track', limit: 10);
      if (searchedTracks.isNotEmpty) return searchedTracks;
      final fallbackTracks = await apiService.search(queryName, type: 'track', limit: 10);
      if (fallbackTracks.isNotEmpty) return fallbackTracks;
    }

    // Mock fallback: return songs by this artist
    final mockSongs = SpotifyMockData.allItems
        .where((i) => i.isSong && (i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase())))
        .toList();
    if (mockSongs.isNotEmpty) return mockSongs;

    // If no tracks, return tracks from matching albums
    final mockAlbums = SpotifyMockData.allItems
        .where((i) => i.isAlbum && (i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase())))
        .toList();
    final extractedTracks = <MusicItem>[];
    for (final alb in mockAlbums) {
      for (final t in alb.tracks) {
        extractedTracks.add(
          MusicItem(
            id: t.id,
            name: t.name,
            artist: alb.artist,
            type: MusicType.song,
            coverUrl: alb.coverUrl,
            releaseDate: alb.releaseDate,
            genres: alb.genres,
            durationMs: t.durationMs,
            previewUrl: t.previewUrl,
          ),
        );
      }
    }
    return extractedTracks.take(10).toList();
  }

  /// Retrieves the artist's complete discography (albums and singles).
  Future<List<MusicItem>> getArtistDiscography(String artistIdOrName) async {
    final clean = artistIdOrName.trim();
    final lower = clean.toLowerCase();
    final mockById = SpotifyMockData.mockArtists.where((a) => a.id == clean || a.name.toLowerCase() == lower).firstOrNull;

    if (isLiveMode) {
      String? resolvedId = clean;
      String queryName = clean;
      if (clean.contains(' ') || clean.startsWith('artist_')) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        queryName = nameToSearch;
        final searchResult = await apiService.searchArtist(nameToSearch);
        resolvedId = searchResult?['id'] as String?;
        if (searchResult?['name'] != null) {
          queryName = searchResult!['name'] as String;
        }
      } else {
        final artistData = await apiService.getArtist(clean);
        if (artistData?['name'] != null) {
          queryName = artistData!['name'] as String;
        }
      }

      final results = <MusicItem>[];
      final seenIds = <String>{};
      final seenTitles = <String>{};

      if (resolvedId != null && resolvedId.isNotEmpty) {
        final albums = await apiService.getArtistAlbums(resolvedId, limit: 10);
        for (final a in albums) {
          final titleKey = '${a.name.toLowerCase().trim()}_${a.type}';
          if (!seenIds.contains(a.id) && !seenTitles.contains(titleKey)) {
            seenIds.add(a.id);
            seenTitles.add(titleKey);
            results.add(a);
          }
        }
      }

      // Supplement with search: this finds studio albums/singles that might be omitted due to market or developer mode restrictions
      final searched = await apiService.search('artist:"$queryName"', type: 'album', limit: 10);
      for (final a in searched) {
        final titleKey = '${a.name.toLowerCase().trim()}_${a.type}';
        if (!seenIds.contains(a.id) && !seenTitles.contains(titleKey)) {
          seenIds.add(a.id);
          seenTitles.add(titleKey);
          results.add(a);
        }
      }

      if (results.isEmpty) {
        final fallbackSearch = await apiService.search(queryName, type: 'album', limit: 10);
        for (final a in fallbackSearch) {
          final titleKey = '${a.name.toLowerCase().trim()}_${a.type}';
          if (!seenIds.contains(a.id) && !seenTitles.contains(titleKey)) {
            seenIds.add(a.id);
            seenTitles.add(titleKey);
            results.add(a);
          }
        }
      }

      if (results.isNotEmpty) return results;
    }

    // Mock fallback
    return SpotifyMockData.allItems
        .where((i) => i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase()))
        .toList();
  }
}

