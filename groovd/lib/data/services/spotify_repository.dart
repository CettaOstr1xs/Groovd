import '../models/artist.dart';
import '../models/music_item.dart';
import 'deezer_api_service.dart';
import 'spotify_api_service.dart';
import 'spotify_mock_data.dart';
import 'wikipedia_api_service.dart';

class SpotifyRepository {
  final SpotifyApiService? apiService;
  final DeezerApiService deezerService;
  final WikipediaApiService wikipediaService;
  final bool enableLiveCatalog;

  SpotifyRepository({
    this.apiService,
    DeezerApiService? deezerService,
    WikipediaApiService? wikipediaService,
    bool? enableLiveCatalog,
  })  : deezerService = deezerService ?? DeezerApiService(),
        wikipediaService = wikipediaService ?? WikipediaApiService(),
        enableLiveCatalog = enableLiveCatalog ??
            (apiService == null || apiService.isConfigured || deezerService != null);

  bool get isLiveMode => enableLiveCatalog;

  Future<List<MusicItem>> getTrendingAlbums() async {
    if (isLiveMode) {
      final releases = await deezerService.getTrendingAlbums(limit: 10);
      if (releases.isNotEmpty) return releases;
      final searched = await deezerService.searchAlbums('year:2024', limit: 10);
      if (searched.isNotEmpty) return searched;
    }
    return SpotifyMockData.trendingAlbums;
  }

  Future<List<MusicItem>> getHotTracks() async {
    if (isLiveMode) {
      final hotTracks = await deezerService.getHotTracks(limit: 10);
      if (hotTracks.isNotEmpty) return hotTracks;
    }
    return [];
  }

  Future<List<MusicItem>> search(String query, {MusicType? type}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      String typeParam = 'all';
      if (type == MusicType.album) typeParam = 'album';
      if (type == MusicType.song) typeParam = 'track';

      final results = await deezerService.search(cleanQuery, type: typeParam, limit: 10);
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

  Future<MusicItem?> getItemById(
    String id, {
    MusicType? type,
    String? name,
    String? artist,
  }) async {
    // Check mock items first
    try {
      final mock = SpotifyMockData.allItems.firstWhere((item) => item.id == id);
      if (mock.tracks.isNotEmpty || mock.type == MusicType.song) {
        return mock;
      }
    } catch (_) {}

    if (isLiveMode) {
      final cleanId = id.replaceFirst('track_', '').replaceFirst('album_', '');
      final isNumeric = int.tryParse(cleanId) != null;

      // 1. Direct Deezer ID lookup (only possible if ID is numeric)
      if (isNumeric) {
        // Explicit track ID
        if (id.startsWith('track_')) {
          final track = await deezerService.getTrack(cleanId);
          if (track != null) return track;
          final album = await deezerService.getAlbum(cleanId);
          if (album != null) return album;
        }

        // Explicit album / EP ID or type
        if (id.startsWith('album_') || type == MusicType.album || type == MusicType.ep) {
          final album = await deezerService.getAlbum(cleanId);
          if (album != null && album.tracks.isNotEmpty) return album;
          final track = await deezerService.getTrack(cleanId);
          if (track != null) return track;
          if (album != null) return album;
        }

        // For song type: try track first, then fallback to album
        if (type == MusicType.song) {
          final track = await deezerService.getTrack(cleanId);
          if (track != null) return track;
          final album = await deezerService.getAlbum(cleanId);
          if (album != null) return album;
        }

        // Default: try album first (to get full album tracklists and metadata)
        final album = await deezerService.getAlbum(cleanId);
        if (album != null && album.tracks.isNotEmpty) return album;

        final track = await deezerService.getTrack(cleanId);
        if (track != null) return track;

        if (album != null) return album;
      }

      // 2. Resilient Fallback: Search by name and artist if direct ID failed
      // or if ID is an old Spotify 22-character ID or mock string ID
      if (name != null && name.trim().isNotEmpty) {
        final cleanName = name.trim();
        final cleanArtist = (artist ?? '').trim();
        final query = cleanArtist.isNotEmpty ? '$cleanName $cleanArtist' : cleanName;

        if (type == MusicType.album || type == MusicType.ep || id.startsWith('album_')) {
          final albums = await deezerService.searchAlbums(query, limit: 5);
          if (albums.isNotEmpty) {
            final matched = albums.firstWhere(
              (a) => a.name.toLowerCase() == cleanName.toLowerCase(),
              orElse: () => albums.first,
            );
            final fullAlbum = await deezerService.getAlbum(matched.id);
            if (fullAlbum != null) return fullAlbum;
            return matched;
          }
        } else if (type == MusicType.song || id.startsWith('track_')) {
          final tracks = await deezerService.searchTracks(query, limit: 5);
          if (tracks.isNotEmpty) {
            final matched = tracks.firstWhere(
              (t) => t.name.toLowerCase() == cleanName.toLowerCase(),
              orElse: () => tracks.first,
            );
            final fullTrack = await deezerService.getTrack(matched.id);
            if (fullTrack != null) return fullTrack;
            return matched;
          }
        } else {
          final combined = await deezerService.search(query, limit: 5);
          if (combined.isNotEmpty) {
            final first = combined.first;
            if (first.type == MusicType.album || first.type == MusicType.ep) {
              final fullAlbum = await deezerService.getAlbum(first.id);
              if (fullAlbum != null) return fullAlbum;
            } else {
              final fullTrack = await deezerService.getTrack(first.id);
              if (fullTrack != null) return fullTrack;
            }
            return first;
          }
        }
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
      final results = await deezerService.searchAlbums(primaryArtist, limit: 10);
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

  /// Retrieves an artist by Deezer ID or name, enriched with Wikipedia biographical summary.
  Future<Artist?> getArtist(String artistIdOrName) async {
    final clean = artistIdOrName.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();

    // Check mock data first if it's a known mock ID
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      Map<String, dynamic>? artistJson;
      // If numeric ID, query directly
      if (RegExp(r'^\d+$').hasMatch(clean)) {
        artistJson = await deezerService.getArtist(clean);
      }

      // Search by artist name if not found by ID
      if (artistJson == null) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        artistJson = await deezerService.searchArtist(nameToSearch);
        if (artistJson != null && artistJson['id'] != null) {
          final fullProfile = await deezerService.getArtist(artistJson['id'].toString());
          if (fullProfile != null) artistJson = fullProfile;
        }
      }

      if (artistJson != null) {
        var artist = Artist.fromDeezerJson(artistJson);
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
    final matchingItems = SpotifyMockData.allItems
        .where((i) => i.artist.toLowerCase().contains(lower))
        .toList();
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

  /// Search catalog for artists matching the query
  Future<List<Artist>> searchArtists(String query, {int limit = 5}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      final artists = await deezerService.searchArtists(cleanQuery, limit: limit);
      if (artists.isNotEmpty) return artists;
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
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      String? resolvedId = clean;
      String queryName = clean;
      if (!RegExp(r'^\d+$').hasMatch(clean)) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        queryName = nameToSearch;
        final searchResult = await deezerService.searchArtist(nameToSearch);
        resolvedId = searchResult?['id']?.toString();
      }

      if (resolvedId != null && resolvedId.isNotEmpty) {
        final tracks = await deezerService.getArtistTopTracks(resolvedId, limit: 10);
        if (tracks.isNotEmpty) return tracks;
      }

      // Secondary search fallback directly
      final searchedTracks = await deezerService.searchTracks(queryName, limit: 10);
      if (searchedTracks.isNotEmpty) return searchedTracks;
    }

    // Mock fallback: return songs by this artist
    final mockSongs = SpotifyMockData.allItems
        .where((i) =>
            i.isSong &&
            (i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase())))
        .toList();
    if (mockSongs.isNotEmpty) return mockSongs;

    // If no tracks, return tracks from matching albums
    final mockAlbums = SpotifyMockData.allItems
        .where((i) =>
            i.isAlbum &&
            (i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase())))
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
            previewUrl: null,
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
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      String? resolvedId = clean;
      String queryName = clean;
      if (!RegExp(r'^\d+$').hasMatch(clean)) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }
        queryName = nameToSearch;
        final searchResult = await deezerService.searchArtist(nameToSearch);
        resolvedId = searchResult?['id']?.toString();
      }

      if (resolvedId != null && resolvedId.isNotEmpty) {
        final albums = await deezerService.getArtistAlbums(resolvedId, limit: 25);
        if (albums.isNotEmpty) return albums;
      }

      // Supplement with search directly
      final searched = await deezerService.searchAlbums(queryName, limit: 15);
      if (searched.isNotEmpty) return searched;
    }

    // Mock fallback
    return SpotifyMockData.allItems
        .where((i) =>
            i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase()))
        .toList();
  }
}
