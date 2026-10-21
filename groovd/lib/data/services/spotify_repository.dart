import '../models/artist.dart';
import '../models/music_item.dart';
import 'deezer_api_service.dart';
import 'genre_tag_service.dart';
import 'spotify_api_service.dart';
import 'spotify_mock_data.dart';
import 'wikipedia_api_service.dart';

/// Circuit breaker for music catalog data providers (Deezer, Spotify).
/// Automatically tracks consecutive failures and temporarily degrades an outage-affected
/// provider so requests can immediately fail over to the active provider without latency.
class ProviderCircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration cooldownDuration;

  int _consecutiveFailures = 0;
  DateTime? _degradedUntil;

  ProviderCircuitBreaker({
    required this.name,
    this.failureThreshold = 3,
    this.cooldownDuration = const Duration(minutes: 5),
  });

  bool get isAvailable {
    if (_degradedUntil == null) return true;
    if (DateTime.now().isAfter(_degradedUntil!)) {
      // Cooldown expired; allow requests again (half-open state)
      _degradedUntil = null;
      _consecutiveFailures = 0;
      return true;
    }
    return false;
  }

  void recordSuccess() {
    _consecutiveFailures = 0;
    _degradedUntil = null;
  }

  void recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= failureThreshold) {
      _degradedUntil = DateTime.now().add(cooldownDuration);
    }
  }

  void tripManually([Duration? duration]) {
    _degradedUntil = DateTime.now().add(duration ?? cooldownDuration);
  }

  void reset() {
    _degradedUntil = null;
    _consecutiveFailures = 0;
  }
}

/// Unified Hybrid Music Repository combining Deezer API and Spotify Web API.
///
/// Features:
/// - Aggregated live music data: Merges Deezer and Spotify results.
/// - Active Failover: If Deezer or Spotify is degraded or offline, the other is seamlessly used.
/// - Rich Cross-Catalog Resolution: Retains Deezer 30s audio previews while utilizing Spotify's
///   exhaustive catalog (e.g. albums like Tokyo Shoegazer's "Moonworld Playground").
/// - Granular Community Tags: Enriches albums, tracks, and artists with Last.fm & MusicBrainz genres.
class SpotifyRepository {
  final SpotifyApiService? apiService;
  final DeezerApiService deezerService;
  final WikipediaApiService wikipediaService;
  final GenreTagService tagService;
  final bool enableLiveCatalog;

  final ProviderCircuitBreaker deezerBreaker = ProviderCircuitBreaker(name: 'Deezer');
  final ProviderCircuitBreaker spotifyBreaker = ProviderCircuitBreaker(name: 'Spotify');

  SpotifyRepository({
    this.apiService,
    DeezerApiService? deezerService,
    WikipediaApiService? wikipediaService,
    GenreTagService? tagService,
    bool? enableLiveCatalog,
  })  : deezerService = deezerService ?? DeezerApiService(),
        wikipediaService = wikipediaService ?? WikipediaApiService(),
        tagService = tagService ?? GenreTagService(),
        enableLiveCatalog = enableLiveCatalog ??
            (apiService == null || apiService.isConfigured || deezerService != null);

  bool get isLiveMode => enableLiveCatalog;

  bool get isDeezerActive => isLiveMode && deezerBreaker.isAvailable;
  bool get isSpotifyActive =>
      isLiveMode &&
      apiService != null &&
      apiService!.isConfigured &&
      spotifyBreaker.isAvailable;

  /// Resilient Deezer API execution with error tracking
  Future<T?> _safeDeezer<T>(
    Future<T?> Function() call, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!isDeezerActive) return null;
    try {
      final res = await call().timeout(timeout);
      deezerBreaker.recordSuccess();
      return res;
    } catch (_) {
      deezerBreaker.recordFailure();
      return null;
    }
  }

  /// Resilient Spotify API execution with error tracking
  Future<T?> _safeSpotify<T>(
    Future<T?> Function() call, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!isSpotifyActive) return null;
    try {
      final res = await call().timeout(timeout);
      spotifyBreaker.recordSuccess();
      return res;
    } catch (_) {
      spotifyBreaker.recordFailure();
      return null;
    }
  }

  Future<List<MusicItem>> getTrendingAlbums() async {
    if (isLiveMode) {
      // 1. Try Deezer
      final releases = await _safeDeezer(() => deezerService.getTrendingAlbums(limit: 10));
      if (releases != null && releases.isNotEmpty) return releases;

      final searched = await _safeDeezer(() => deezerService.searchAlbums('year:2024', limit: 10));
      if (searched != null && searched.isNotEmpty) return searched;

      // 2. Try Spotify if Deezer is degraded or returned empty
      final spotifyReleases = await _safeSpotify(() => apiService!.getNewReleases(limit: 10));
      if (spotifyReleases != null && spotifyReleases.isNotEmpty) return spotifyReleases;
    }
    return SpotifyMockData.trendingAlbums;
  }

  Future<List<MusicItem>> getHotTracks() async {
    if (isLiveMode) {
      // 1. Try Deezer
      final hotTracks = await _safeDeezer(() => deezerService.getHotTracks(limit: 10));
      if (hotTracks != null && hotTracks.isNotEmpty) return hotTracks;

      // 2. Try Spotify if Deezer is degraded
      final spotifyTracks = await _safeSpotify(() => apiService!.search('tag:new', type: 'track', limit: 10));
      if (spotifyTracks != null && spotifyTracks.isNotEmpty) return spotifyTracks;
    }
    return [];
  }

  Future<List<MusicItem>> search(String query, {MusicType? type}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      String deezerType = 'all';
      if (type == MusicType.album) deezerType = 'album';
      if (type == MusicType.song) deezerType = 'track';

      String spotifyType = 'album,track';
      if (type == MusicType.album) spotifyType = 'album';
      if (type == MusicType.song) spotifyType = 'track';

      // 1. Concurrently search active providers
      final futures = <Future<List<MusicItem>>>[];
      if (isDeezerActive) {
        futures.add(_safeDeezer(() => deezerService.search(cleanQuery, type: deezerType, limit: 15))
            .then((v) => v ?? <MusicItem>[]));
      }
      if (isSpotifyActive) {
        futures.add(_safeSpotify(() => apiService!.search(cleanQuery, type: spotifyType, limit: 10))
            .then((v) => v ?? <MusicItem>[]));
      }

      final searchResultsLists = await Future.wait(futures);
      final directResults = <MusicItem>[];
      for (final list in searchResultsLists) {
        directResults.addAll(list);
      }

      // 2. Resilient Popular Artist Releases Resolution
      // Check if the query matches a prominent or foreign/non-Latin artist (e.g. Tokyo Shoegazer / Kino)
      try {
        final matchingArtists = await searchArtists(cleanQuery, limit: 3);
        if (matchingArtists.isNotEmpty) {
          final topArtist = matchingArtists.first;
          final cleanLower = cleanQuery.toLowerCase();
          final artistNameLower = topArtist.name.toLowerCase();
          final translits = DeezerApiService.getTransliterations(cleanQuery);

          final hasTranslitMatch = translits.any((t) => artistNameLower == t.toLowerCase());
          final isEquivalent = (MusicItem.areArtistsEquivalent(topArtist.name, cleanQuery) ||
                  artistNameLower == cleanLower) &&
              (topArtist.followers >= 1000 || hasTranslitMatch);

          final isStrongArtistMatch = hasTranslitMatch ||
              isEquivalent ||
              (topArtist.followers >= 5000 &&
                  (artistNameLower.contains(cleanLower) || cleanLower.contains(artistNameLower))) ||
              topArtist.followers >= 50000;

          if (isStrongArtistMatch) {
            final artistItems = <MusicItem>[];
            if (type == MusicType.album) {
              final albums = await getArtistDiscography(topArtist.id, artistName: topArtist.name);
              artistItems.addAll(albums);
            } else if (type == MusicType.song) {
              final tracks = await getArtistTopTracks(topArtist.id, artistName: topArtist.name);
              artistItems.addAll(tracks);
            } else {
              // 'all': fetch their iconic albums and top tracks
              final albums = await getArtistDiscography(topArtist.id, artistName: topArtist.name);
              final tracks = await getArtistTopTracks(topArtist.id, artistName: topArtist.name);
              artistItems.addAll(albums.take(5));
              artistItems.addAll(tracks.take(5));
            }

            final combined = _mergeAndRankMusicItems(
              items: [...directResults, ...artistItems],
              query: cleanQuery,
            );
            if (combined.isNotEmpty) return combined;
          }
        }
      } catch (_) {}

      if (directResults.isNotEmpty) {
        return _mergeAndRankMusicItems(items: directResults, query: cleanQuery);
      }
    }

    // Mock search fallback
    final q = cleanQuery.toLowerCase();
    final translits = DeezerApiService.getTransliterations(cleanQuery);
    final terms = [q, ...translits.map((t) => t.toLowerCase())];

    return SpotifyMockData.allItems.where((item) {
      final nameLower = item.name.toLowerCase();
      final artistLower = item.artist.toLowerCase();
      final matchesQuery = terms.any((term) =>
          nameLower.contains(term) ||
          artistLower.contains(term) ||
          item.genres.any((g) => g.toLowerCase().contains(term)));
      if (type == null) return matchesQuery;
      return matchesQuery && item.type == type;
    }).toList();
  }

  /// Merges, deduplicates, and ranks items from multiple providers.
  /// Substring and exact title matches are prioritized at the top of results.
  List<MusicItem> _mergeAndRankMusicItems({
    required List<MusicItem> items,
    required String query,
  }) {
    final merged = <MusicItem>[];
    final cleanQuery = query.trim().toLowerCase();

    for (final item in items) {
      final existingIndex = merged.indexWhere((m) => m.isSameWork(item) || m.id == item.id);
      if (existingIndex == -1) {
        merged.add(item);
      } else {
        // Merge attributes to get the best of both
        final existing = merged[existingIndex];
        final preview = (existing.previewUrl != null && existing.previewUrl!.isNotEmpty)
            ? existing.previewUrl
            : item.previewUrl;
        final externalUrl = existing.externalSpotifyUrl.isNotEmpty
            ? existing.externalSpotifyUrl
            : item.externalSpotifyUrl;
        final tracks = existing.tracks.isNotEmpty ? existing.tracks : item.tracks;
        final cover = existing.coverUrl.isNotEmpty ? existing.coverUrl : item.coverUrl;
        final pop = existing.popularity > item.popularity ? existing.popularity : item.popularity;

        merged[existingIndex] = existing.copyWith(
          previewUrl: preview,
          externalSpotifyUrl: externalUrl,
          tracks: tracks,
          coverUrl: cover,
          popularity: pop,
        );
      }
    }

    // Rank results: exact/substring title match first, then artist match, then others
    merged.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();

      final aExact = aName == cleanQuery;
      final bExact = bName == cleanQuery;
      if (aExact && !bExact) return -1;
      if (!aExact && bExact) return 1;

      final aContains = aName.contains(cleanQuery) || cleanQuery.contains(aName);
      final bContains = bName.contains(cleanQuery) || cleanQuery.contains(bName);
      if (aContains && !bContains) return -1;
      if (!aContains && bContains) return 1;

      final aArtist = a.artist.toLowerCase();
      final bArtist = b.artist.toLowerCase();
      final aArtistMatch = aArtist.contains(cleanQuery) || cleanQuery.contains(aArtist);
      final bArtistMatch = bArtist.contains(cleanQuery) || cleanQuery.contains(bArtist);
      if (aArtistMatch && !bArtistMatch) return -1;
      if (!aArtistMatch && bArtistMatch) return 1;

      return 0;
    });

    return merged;
  }

  /// Enriches music item with rich, granular Last.fm & MusicBrainz genre tags and verified original release date.
  Future<MusicItem> _enrichItemWithTags(MusicItem item) async {
    try {
      final tags = (item.genres.isEmpty || item.genres.length <= 1)
          ? await tagService.getTags(
              artist: item.artist,
              title: item.name,
              isAlbum: item.isAlbum || item.isEp,
            )
          : item.genres;

      String updatedDate = item.releaseDate;
      final cachedOriginalDate = tagService.getCachedReleaseDate(item.artist, item.name);
      if (cachedOriginalDate != null && cachedOriginalDate.isNotEmpty) {
        if (updatedDate.isEmpty ||
            (cachedOriginalDate.length > updatedDate.length && cachedOriginalDate.startsWith(updatedDate)) ||
            (cachedOriginalDate.compareTo(updatedDate) < 0 && cachedOriginalDate.length >= 4)) {
          updatedDate = cachedOriginalDate;
        }
      }

      if (tags.isNotEmpty || updatedDate != item.releaseDate) {
        return item.copyWith(
          genres: tags.isNotEmpty ? tags : item.genres,
          releaseDate: updatedDate,
        );
      }
    } catch (_) {}
    return item;
  }

  /// Enriches artist with rich Last.fm & MusicBrainz community sub-genres.
  Future<Artist> _enrichArtistWithTags(Artist artist) async {
    if (artist.genres.isEmpty || artist.genres.length <= 1) {
      try {
        final tags = await tagService.getArtistTags(artist.name);
        if (tags.isNotEmpty) {
          return artist.copyWith(genres: tags);
        }
      } catch (_) {}
    }
    return artist;
  }

  Future<MusicItem?> getItemById(
    String id, {
    MusicType? type,
    String? name,
    String? artist,
  }) async {
    final item = await _getItemByIdRaw(id, type: type, name: name, artist: artist);
    if (item == null) return null;
    return _enrichItemWithTags(item);
  }

  Future<MusicItem?> _getItemByIdRaw(
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
      final isSpotifyId = !isNumeric && cleanId.length >= 15 && !cleanId.startsWith('mock_');

      // 1. If it's a Spotify ID (22 chars base62)
      if (isSpotifyId) {
        MusicItem? spotifyItem;
        if (type == MusicType.song || id.startsWith('track_')) {
          spotifyItem = await _safeSpotify(() => apiService!.getTrack(cleanId));
        } else {
          spotifyItem = await _safeSpotify(() => apiService!.getAlbum(cleanId));
          if (spotifyItem == null || spotifyItem.tracks.isEmpty) {
            spotifyItem = await _safeSpotify(() => apiService!.getTrack(cleanId)) ?? spotifyItem;
          }
        }

        if (spotifyItem != null) {
          // If Spotify item lacks audio preview, check Deezer opportunistically
          if ((spotifyItem.previewUrl == null || spotifyItem.previewUrl!.isEmpty) && isDeezerActive) {
            try {
              final deezerMatches = await _safeDeezer(() => deezerService.searchTracks('${spotifyItem!.name} ${spotifyItem.artist}', limit: 3));
              if (deezerMatches != null && deezerMatches.isNotEmpty) {
                final matched = deezerMatches.firstWhere(
                  (m) => MusicItem.areTitlesEquivalent(m.name, spotifyItem!.name),
                  orElse: () => deezerMatches.first,
                );
                if (matched.previewUrl != null && matched.previewUrl!.isNotEmpty) {
                  spotifyItem = spotifyItem.copyWith(previewUrl: matched.previewUrl);
                }
              }
            } catch (_) {}
          }
          return spotifyItem;
        }

        // If Spotify failed or is degraded, fallback to Deezer by name & artist
        if (name != null && name.trim().isNotEmpty && isDeezerActive) {
          final deezerFallback = await _lookupByTitleAndArtistDeezer(name: name, artist: artist, type: type, id: id);
          if (deezerFallback != null) return deezerFallback;
        }
      }

      // 2. Direct Deezer ID lookup (only possible if ID is numeric)
      if (isNumeric) {
        MusicItem? deezerItem;
        if (isDeezerActive) {
          if (id.startsWith('track_')) {
            deezerItem = await _safeDeezer(() => deezerService.getTrack(cleanId));
            deezerItem ??= await _safeDeezer(() => deezerService.getAlbum(cleanId));
          } else if (id.startsWith('album_') || type == MusicType.album || type == MusicType.ep) {
            deezerItem = await _safeDeezer(() => deezerService.getAlbum(cleanId));
            if (deezerItem == null || deezerItem.tracks.isEmpty) {
              deezerItem = await _safeDeezer(() => deezerService.getTrack(cleanId)) ?? deezerItem;
            }
          } else if (type == MusicType.song) {
            deezerItem = await _safeDeezer(() => deezerService.getTrack(cleanId));
            deezerItem ??= await _safeDeezer(() => deezerService.getAlbum(cleanId));
          } else {
            deezerItem = await _safeDeezer(() => deezerService.getAlbum(cleanId));
            if (deezerItem == null || deezerItem.tracks.isEmpty) {
              deezerItem = await _safeDeezer(() => deezerService.getTrack(cleanId)) ?? deezerItem;
            }
          }
        }

        if (deezerItem != null) return deezerItem;

        // If Deezer failed or is degraded, fallback to Spotify by name & artist
        if (name != null && name.trim().isNotEmpty && isSpotifyActive) {
          final spotifyFallback = await _lookupByTitleAndArtistSpotify(name: name, artist: artist, type: type);
          if (spotifyFallback != null) return spotifyFallback;
        }
      }

      // 3. Resilient Fallback: Search by name and artist if direct ID failed
      if (name != null && name.trim().isNotEmpty) {
        if (isDeezerActive) {
          final d = await _lookupByTitleAndArtistDeezer(name: name, artist: artist, type: type, id: id);
          if (d != null) return d;
        }
        if (isSpotifyActive) {
          final s = await _lookupByTitleAndArtistSpotify(name: name, artist: artist, type: type);
          if (s != null) return s;
        }
      }
    }

    return null;
  }

  Future<MusicItem?> _lookupByTitleAndArtistDeezer({
    required String name,
    String? artist,
    MusicType? type,
    String? id,
  }) async {
    final cleanName = name.trim();
    final cleanArtist = (artist ?? '').trim();
    final query = cleanArtist.isNotEmpty ? '$cleanName $cleanArtist' : cleanName;

    if (type == MusicType.album || type == MusicType.ep || (id != null && id.startsWith('album_'))) {
      final albums = await _safeDeezer(() => deezerService.searchAlbums(query, limit: 5));
      if (albums != null && albums.isNotEmpty) {
        final matched = albums.firstWhere(
          (a) => MusicItem.areTitlesEquivalent(a.name, cleanName),
          orElse: () => albums.first,
        );
        final fullAlbum = await _safeDeezer(() => deezerService.getAlbum(matched.id));
        return fullAlbum ?? matched;
      }
    } else if (type == MusicType.song || (id != null && id.startsWith('track_'))) {
      final tracks = await _safeDeezer(() => deezerService.searchTracks(query, limit: 5));
      if (tracks != null && tracks.isNotEmpty) {
        final matched = tracks.firstWhere(
          (t) => MusicItem.areTitlesEquivalent(t.name, cleanName),
          orElse: () => tracks.first,
        );
        final fullTrack = await _safeDeezer(() => deezerService.getTrack(matched.id));
        return fullTrack ?? matched;
      }
    } else {
      final combined = await _safeDeezer(() => deezerService.search(query, limit: 5));
      if (combined != null && combined.isNotEmpty) {
        final first = combined.first;
        if (first.type == MusicType.album || first.type == MusicType.ep) {
          final fullAlbum = await _safeDeezer(() => deezerService.getAlbum(first.id));
          return fullAlbum ?? first;
        } else {
          final fullTrack = await _safeDeezer(() => deezerService.getTrack(first.id));
          return fullTrack ?? first;
        }
      }
    }
    return null;
  }

  Future<MusicItem?> _lookupByTitleAndArtistSpotify({
    required String name,
    String? artist,
    MusicType? type,
  }) async {
    final cleanName = name.trim();
    final cleanArtist = (artist ?? '').trim();
    final query = cleanArtist.isNotEmpty ? '$cleanName $cleanArtist' : cleanName;
    final spotifyType = type == MusicType.album ? 'album' : (type == MusicType.song ? 'track' : 'album,track');

    final items = await _safeSpotify(() => apiService!.search(query, type: spotifyType, limit: 5));
    if (items != null && items.isNotEmpty) {
      final matched = items.firstWhere(
        (m) => MusicItem.areTitlesEquivalent(m.name, cleanName),
        orElse: () => items.first,
      );
      if (matched.type == MusicType.album || matched.type == MusicType.ep) {
        final full = await _safeSpotify(() => apiService!.getAlbum(matched.id));
        return full ?? matched;
      } else {
        final full = await _safeSpotify(() => apiService!.getTrack(matched.id));
        return full ?? matched;
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
      final futures = <Future<List<MusicItem>>>[];
      if (isDeezerActive) {
        futures.add(_safeDeezer(() => deezerService.searchAlbums(primaryArtist, limit: 10))
            .then((v) => v ?? <MusicItem>[]));
      }
      if (isSpotifyActive) {
        futures.add(_safeSpotify(() => apiService!.search('artist:"$primaryArtist"', type: 'album', limit: 10))
            .then((v) => v ?? <MusicItem>[]));
      }

      final results = await Future.wait(futures);
      final allItems = <MusicItem>[];
      for (final r in results) {
        allItems.addAll(r);
      }

      if (allItems.isNotEmpty) {
        final filtered = <MusicItem>[];
        final seenIds = <String>{};
        if (currentItemId != null) seenIds.add(currentItemId);

        for (final item in allItems) {
          if (seenIds.contains(item.id)) continue;
          final itemArtistLower = item.artist.toLowerCase();
          if (itemArtistLower.contains(primaryLower) || primaryLower.contains(itemArtistLower)) {
            final alreadyPresent = filtered.any((f) => f.isSameWork(item));
            if (!alreadyPresent) {
              seenIds.add(item.id);
              filtered.add(item);
            }
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

  /// Retrieves an artist by Deezer ID, Spotify ID, or name, enriched with Wikipedia biographical summary.
  Future<Artist?> getArtist(String artistIdOrName) async {
    final clean = artistIdOrName.trim();
    if (clean.isEmpty) return null;
    final lower = clean.toLowerCase();

    // Check mock data first if it's a known mock ID
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      final isNumeric = RegExp(r'^\d+$').hasMatch(clean);
      final isSpotifyId = !isNumeric && clean.length >= 15 && !clean.startsWith('artist_') && !clean.contains(' ');

      Artist? resolvedArtist;

      // 1. Try by direct Spotify ID if applicable
      if (isSpotifyId && isSpotifyActive) {
        final spotifyJson = await _safeSpotify(() => apiService!.getArtist(clean));
        if (spotifyJson != null) {
          resolvedArtist = Artist.fromSpotifyJson(spotifyJson);
        }
      }

      // 2. Try by direct Deezer ID if applicable
      if (resolvedArtist == null && isNumeric && isDeezerActive) {
        final deezerJson = await _safeDeezer(() => deezerService.getArtist(clean));
        if (deezerJson != null) {
          resolvedArtist = Artist.fromDeezerJson(deezerJson);
        }
      }

      // 3. Search by name across both Deezer & Spotify
      if (resolvedArtist == null) {
        String nameToSearch = clean;
        if (mockById != null) {
          nameToSearch = mockById.name;
        } else if (clean.startsWith('artist_')) {
          nameToSearch = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
        }

        final futures = <Future<dynamic>>[];
        if (isDeezerActive) {
          futures.add(_safeDeezer(() => deezerService.searchArtist(nameToSearch)));
        } else {
          futures.add(Future.value(null));
        }

        if (isSpotifyActive) {
          futures.add(_safeSpotify(() => apiService!.searchArtist(nameToSearch)));
        } else {
          futures.add(Future.value(null));
        }

        final res = await Future.wait(futures);
        final deezerData = res[0] as Map<String, dynamic>?;
        final spotifyData = res[1] as Map<String, dynamic>?;

        if (spotifyData != null) {
          resolvedArtist = Artist.fromSpotifyJson(spotifyData);
          if (deezerData != null && resolvedArtist.imageUrl.isEmpty) {
            final deezerImage = deezerData['picture_xl'] ?? deezerData['picture_big'] ?? deezerData['picture'];
            if (deezerImage != null) {
              resolvedArtist = resolvedArtist.copyWith(imageUrl: deezerImage.toString());
            }
          }
        } else if (deezerData != null) {
          if (deezerData['id'] != null) {
            final fullProfile = await _safeDeezer(() => deezerService.getArtist(deezerData['id'].toString()));
            resolvedArtist = Artist.fromDeezerJson(fullProfile ?? deezerData);
          } else {
            resolvedArtist = Artist.fromDeezerJson(deezerData);
          }
        }
      }

      if (resolvedArtist != null) {
        // Fetch bio from Wikipedia
        try {
          final wiki = await wikipediaService.getArtistSummary(resolvedArtist.name);
          if (wiki != null) {
            resolvedArtist = resolvedArtist.copyWith(
              bio: wiki.extract,
              shortDescription: wiki.description,
            );
          }
        } catch (_) {}
        return _enrichArtistWithTags(resolvedArtist!);
      }
    }

    if (mockById != null) {
      return _enrichArtistWithTags(mockById);
    }

    // Generic fallback: check if any items in mock data match this artist
    final matchingItems = SpotifyMockData.allItems
        .where((i) => i.artist.toLowerCase().contains(lower))
        .toList();
    if (matchingItems.isNotEmpty) {
      final first = matchingItems.first;
      final genres = matchingItems.expand((i) => i.genres).toSet().toList();
      return _enrichArtistWithTags(
        Artist(
          id: 'artist_${first.artist.toLowerCase().replaceAll(' ', '_')}',
          name: first.artist.toUpperCase(),
          imageUrl: first.coverUrl,
          genres: genres.take(4).toList(),
          followers: 1200000,
          popularity: 75,
          bio: '${first.artist} is a renowned musical artist with acclaimed works archived in Groovd.',
          shortDescription: 'Musical artist',
        ),
      );
    }

    return null;
  }

  /// Search catalog for artists matching the query across both providers.
  Future<List<Artist>> searchArtists(String query, {int limit = 10}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    if (isLiveMode) {
      final futures = <Future<List<Artist>>>[];

      if (isDeezerActive) {
        futures.add(_safeDeezer(() => deezerService.searchArtists(cleanQuery, limit: limit))
            .then((v) => v ?? <Artist>[]));
      }
      if (isSpotifyActive) {
        futures.add(_safeSpotify(() => apiService!.searchArtists(cleanQuery, limit: limit))
            .then((list) => list?.map((m) => Artist.fromSpotifyJson(m)).toList() ?? <Artist>[]));
      }

      final resultsLists = await Future.wait(futures);
      final collected = <Artist>[];
      for (final l in resultsLists) {
        collected.addAll(l);
      }

      if (collected.isNotEmpty) {
        final mergedArtists = <Artist>[];
        for (final a in collected) {
          final existingIndex = mergedArtists.indexWhere((m) => MusicItem.areArtistsEquivalent(m.name, a.name));
          if (existingIndex == -1) {
            mergedArtists.add(a);
          } else {
            final existing = mergedArtists[existingIndex];
            final img = existing.imageUrl.isNotEmpty ? existing.imageUrl : a.imageUrl;
            final followers = existing.followers > a.followers ? existing.followers : a.followers;
            final spotUrl = existing.spotifyUrl.isNotEmpty ? existing.spotifyUrl : a.spotifyUrl;
            final genres = existing.genres.isNotEmpty ? existing.genres : a.genres;
            mergedArtists[existingIndex] = existing.copyWith(
              imageUrl: img,
              followers: followers,
              spotifyUrl: spotUrl,
              genres: genres,
            );
          }
        }
        return mergedArtists.take(limit).toList();
      }
    }

    // Mock search fallback
    final q = cleanQuery.toLowerCase();
    final translits = DeezerApiService.getTransliterations(cleanQuery);
    final terms = [q, ...translits.map((t) => t.toLowerCase())];
    final results = <Artist>[];
    final seenNames = <String>{};

    for (final a in SpotifyMockData.mockArtists) {
      final aLower = a.name.toLowerCase();
      if (terms.any((term) => aLower.contains(term))) {
        seenNames.add(aLower);
        results.add(a);
      }
    }

    for (final item in SpotifyMockData.allItems) {
      final nameLower = item.artist.toLowerCase();
      if (terms.any((term) => nameLower.contains(term)) && !seenNames.contains(nameLower)) {
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

  /// Retrieves the artist's top tracks combining Deezer & Spotify.
  Future<List<MusicItem>> getArtistTopTracks(String artistIdOrName, {String? artistName}) async {
    final clean = artistIdOrName.trim();
    if (clean.isEmpty) return [];

    final lower = clean.toLowerCase();
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      String queryName = artistName ?? clean;
      if (mockById != null) {
        queryName = mockById.name;
      } else if (clean.startsWith('artist_')) {
        queryName = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
      }

      final futures = <Future<List<MusicItem>>>[];

      // 1. Deezer Top Tracks
      if (isDeezerActive) {
        futures.add(() async {
          String? deezerId = RegExp(r'^\d+$').hasMatch(clean) ? clean : null;
          if (deezerId == null) {
            final s = await _safeDeezer(() => deezerService.searchArtist(queryName));
            deezerId = s?['id']?.toString();
          }
          if (deezerId != null && deezerId.isNotEmpty) {
            final tracks = await _safeDeezer(() => deezerService.getArtistTopTracks(deezerId!, limit: 10));
            if (tracks != null && tracks.isNotEmpty) return tracks;
          }
          final searchedTracks = await _safeDeezer(() => deezerService.searchTracks(queryName, limit: 10));
          return searchedTracks ?? <MusicItem>[];
        }());
      }

      // 2. Spotify Top Tracks
      if (isSpotifyActive) {
        futures.add(() async {
          String? spotifyId = (!RegExp(r'^\d+$').hasMatch(clean) && clean.length >= 15 && !clean.contains(' ')) ? clean : null;
          if (spotifyId == null) {
            final s = await _safeSpotify(() => apiService!.searchArtist(queryName));
            spotifyId = s?['id']?.toString();
          }
          if (spotifyId != null && spotifyId.isNotEmpty) {
            final tracks = await _safeSpotify(() => apiService!.getArtistTopTracks(spotifyId!, artistName: queryName));
            if (tracks != null && tracks.isNotEmpty) return tracks;
          }
          final searchedTracks = await _safeSpotify(() => apiService!.search(queryName, type: 'track', limit: 10));
          return searchedTracks ?? <MusicItem>[];
        }());
      }

      final results = await Future.wait(futures);
      final allTracks = <MusicItem>[];
      for (final r in results) {
        allTracks.addAll(r);
      }

      if (allTracks.isNotEmpty) {
        final merged = <MusicItem>[];
        for (final t in allTracks) {
          final idx = merged.indexWhere((m) => MusicItem.areTitlesEquivalent(m.name, t.name));
          if (idx == -1) {
            merged.add(t);
          } else {
            // Keep Deezer preview if present
            if ((merged[idx].previewUrl == null || merged[idx].previewUrl!.isEmpty) && t.previewUrl != null && t.previewUrl!.isNotEmpty) {
              merged[idx] = merged[idx].copyWith(previewUrl: t.previewUrl);
            }
          }
        }
        return merged.take(10).toList();
      }
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

  /// Retrieves the artist's complete discography combining Deezer and Spotify catalogs.
  Future<List<MusicItem>> getArtistDiscography(String artistIdOrName, {String? artistName}) async {
    final clean = artistIdOrName.trim();
    final lower = clean.toLowerCase();
    final mockById = SpotifyMockData.mockArtists
        .where((a) => a.id == clean || a.name.toLowerCase() == lower)
        .firstOrNull;

    if (isLiveMode) {
      String queryName = artistName ?? clean;
      if (mockById != null) {
        queryName = mockById.name;
      } else if (clean.startsWith('artist_')) {
        queryName = clean.replaceFirst('artist_', '').replaceAll('_', ' ');
      }

      final futures = <Future<List<MusicItem>>>[];

      // 1. Deezer Albums
      if (isDeezerActive) {
        futures.add(() async {
          String? deezerId = RegExp(r'^\d+$').hasMatch(clean) ? clean : null;
          if (deezerId == null) {
            final s = await _safeDeezer(() => deezerService.searchArtist(queryName));
            deezerId = s?['id']?.toString();
          }
          if (deezerId != null && deezerId.isNotEmpty) {
            final albums = await _safeDeezer(() => deezerService.getArtistAlbums(deezerId!, limit: 25));
            if (albums != null && albums.isNotEmpty) return albums;
          }
          final searched = await _safeDeezer(() => deezerService.searchAlbums(queryName, limit: 15));
          return searched ?? <MusicItem>[];
        }());
      }

      // 2. Spotify Albums
      if (isSpotifyActive) {
        futures.add(() async {
          String? spotifyId = (!RegExp(r'^\d+$').hasMatch(clean) && clean.length >= 15 && !clean.contains(' ')) ? clean : null;
          if (spotifyId == null) {
            final s = await _safeSpotify(() => apiService!.searchArtist(queryName));
            spotifyId = s?['id']?.toString();
          }
          if (spotifyId != null && spotifyId.isNotEmpty) {
            final albums = await _safeSpotify(() => apiService!.getArtistAlbums(spotifyId!, limit: 25, includeGroups: 'album,single'));
            if (albums != null && albums.isNotEmpty) return albums;
          }
          final searched = await _safeSpotify(() => apiService!.search(queryName, type: 'album', limit: 15));
          return searched ?? <MusicItem>[];
        }());
      }

      final results = await Future.wait(futures);
      final allAlbums = <MusicItem>[];
      for (final r in results) {
        allAlbums.addAll(r);
      }

      if (allAlbums.isNotEmpty) {
        final merged = <MusicItem>[];
        for (final alb in allAlbums) {
          final idx = merged.indexWhere((m) => m.isSameWork(alb) || MusicItem.areTitlesEquivalent(m.name, alb.name));
          if (idx == -1) {
            merged.add(alb);
          } else {
            final existing = merged[idx];
            final preview = (existing.previewUrl != null && existing.previewUrl!.isNotEmpty)
                ? existing.previewUrl
                : alb.previewUrl;
            final externalUrl = existing.externalSpotifyUrl.isNotEmpty
                ? existing.externalSpotifyUrl
                : alb.externalSpotifyUrl;
            final tracks = existing.tracks.isNotEmpty ? existing.tracks : alb.tracks;
            final cover = existing.coverUrl.isNotEmpty ? existing.coverUrl : alb.coverUrl;
            merged[idx] = existing.copyWith(
              previewUrl: preview,
              externalSpotifyUrl: externalUrl,
              tracks: tracks,
              coverUrl: cover,
            );
          }
        }

        // Sort by release date descending
        merged.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        return merged;
      }
    }

    // Mock fallback
    return SpotifyMockData.allItems
        .where((i) =>
            i.artist.toLowerCase().contains(lower) || lower.contains(i.artist.toLowerCase()))
        .toList();
  }
}
