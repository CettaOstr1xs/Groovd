import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/lastfm_config.dart';

/// Service providing rich, granular genre tags for albums, tracks, and artists.
/// Enriches basic macro-genres with community tags from Last.fm, with an
/// automatic fallback to MusicBrainz's open encyclopedic genre taxonomy.
class GenreTagService {
  final http.Client _client;
  final String? lastFmApiKey;

  final Map<String, List<String>> _cache = {};
  final Map<String, String> _releaseDateCache = {};

  /// Retrieves cached original release date for an artist and title, if previously resolved.
  String? getCachedReleaseDate(String artist, String title) {
    return _releaseDateCache['${artist.trim().toLowerCase()}:::${title.trim().toLowerCase()}'];
  }

  // Non-genre community noise tags to filter out
  static const Set<String> _ignoredTags = {
    'albums i own',
    'owned',
    'i own this',
    'seen live',
    'favorites',
    'favourite',
    'favorite albums',
    'favourites',
    'my favorite albums',
    'vinyl',
    'vinyl collection',
    'cd',
    'cassette',
    'spotify',
    'check out',
    'beautiful',
    'masterpiece',
    'classic',
    'all time favorites',
    'all-time favorites',
    '10/10',
    '9/10',
    '8/10',
    'love',
    'awesome',
    'my vinyl collection',
    'buy',
    'wishlist',
    'political',
    'american',
    'british',
    'english',
    'french',
    'german',
    'japanese',
    'canadian',
    'australian',
    'swedish',
    'russian',
    'korean',
    'male vocalist',
    'female vocalist',
    'female vocalists',
    'male vocalists',
    'acoustic',
    'ballad',
    'melancholy',
    'chill',
    'relax',
    'party',
    'summer',
    'driving',
    'workout',
    'alienation',
    'anxious',
    'cynical',
    'sarcastic',
    'mental health',
    'longing',
    'pessimistic',
    'insecure',
    'anti-authoritarian',
    'anticonsumerism',
    'paranoia',
    'dystopian',
    'serious',
    'melancholic',
    'futuristic',
    'atmospheric',
    'dense',
    'falsetto',
    'sad',
    'existential',
    'depressive',
    'poetic',
    'lonely',
    'nihilistic',
    'passionate',
    'introspective',
    'cold',
    'offizielle charts',
    '5+ wochen',
    'uk',
    'britannique',
  };

  GenreTagService({
    http.Client? client,
    this.lastFmApiKey,
  }) : _client = client ?? http.Client();

  String _resolveApiKey() {
    if (lastFmApiKey != null && lastFmApiKey!.trim().isNotEmpty) {
      return lastFmApiKey!.trim();
    }
    const envKey = String.fromEnvironment('LASTFM_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }
    return LastFmConfig.apiKey.trim();
  }

  /// Retrieves granular genre tags for an album/release or song.
  Future<List<String>> getTags({
    required String artist,
    required String title,
    bool isAlbum = true,
  }) async {
    final cleanArtist = artist.trim();
    final cleanTitle = title.trim();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return const [];

    final cacheKey = '${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<String> tags = [];

    // 1. Try Last.fm if an API key is available
    final apiKey = _resolveApiKey();
    if (apiKey.isNotEmpty) {
      tags = await _fetchLastFmTags(
        artist: cleanArtist,
        title: cleanTitle,
        isAlbum: isAlbum,
        apiKey: apiKey,
      );
    }

    // 2. Query MusicBrainz open community taxonomy (free, no auth required)
    if (tags.isEmpty) {
      tags = await _fetchMusicBrainzTags(
        artist: cleanArtist,
        title: cleanTitle,
        isAlbum: isAlbum,
      );
    }

    // 3. Fallback to artist tags if specific release has no tags
    if (tags.isEmpty && cleanArtist.isNotEmpty) {
      tags = await getArtistTags(cleanArtist);
    }

    final cleanTags = _cleanAndDeduplicate(tags).take(5).toList();
    _cache[cacheKey] = cleanTags;
    return cleanTags;
  }

  /// Retrieves granular genre tags for an artist.
  Future<List<String>> getArtistTags(String artist) async {
    final clean = artist.trim();
    if (clean.isEmpty) return const [];

    final cacheKey = 'artist:::${clean.toLowerCase()}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    List<String> tags = [];

    final apiKey = _resolveApiKey();
    if (apiKey.isNotEmpty) {
      tags = await _fetchLastFmArtistTags(clean, apiKey: apiKey);
    }

    if (tags.isEmpty) {
      tags = await _fetchMusicBrainzArtistTags(clean);
    }

    final cleanTags = _cleanAndDeduplicate(tags).take(5).toList();
    _cache[cacheKey] = cleanTags;
    return cleanTags;
  }

  // --------------------------------------------------------------------------
  // Last.fm API Client
  // --------------------------------------------------------------------------

  Future<List<String>> _fetchLastFmTags({
    required String artist,
    required String title,
    required bool isAlbum,
    required String apiKey,
  }) async {
    try {
      final method = isAlbum ? 'album.gettoptags' : 'track.gettoptags';
      final paramName = isAlbum ? 'album' : 'track';

      final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
        'method': method,
        'artist': artist,
        paramName: title,
        'api_key': apiKey,
        'format': 'json',
        'autocorrect': '1',
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final topTags = data['toptags'] as Map<String, dynamic>?;
      if (topTags == null) return const [];

      final rawTag = topTags['tag'];
      return _parseLastFmTagList(rawTag);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _fetchLastFmArtistTags(String artist, {required String apiKey}) async {
    try {
      final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {
        'method': 'artist.gettoptags',
        'artist': artist,
        'api_key': apiKey,
        'format': 'json',
        'autocorrect': '1',
      });

      final response = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final topTags = data['toptags'] as Map<String, dynamic>?;
      if (topTags == null) return const [];

      final rawTag = topTags['tag'];
      return _parseLastFmTagList(rawTag);
    } catch (_) {
      return const [];
    }
  }

  List<String> _parseLastFmTagList(dynamic rawTag) {
    if (rawTag is List) {
      final items = List<Map<String, dynamic>>.from(
        rawTag.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = int.tryParse(a['count']?.toString() ?? '0') ?? 0;
        final countB = int.tryParse(b['count']?.toString() ?? '0') ?? 0;
        return countB.compareTo(countA);
      });
      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (rawTag is Map && rawTag['name'] != null) {
      return [rawTag['name'].toString()];
    }
    return const [];
  }

  // --------------------------------------------------------------------------
  // MusicBrainz API Client (Open & Free Fallback)
  // --------------------------------------------------------------------------

  Future<List<String>> _fetchMusicBrainzTags({
    required String artist,
    required String title,
    required bool isAlbum,
  }) async {
    try {
      // MusicBrainz release-group query for albums/EPs
      final cleanTitle = _sanitizeForQuery(title);
      final cleanArtist = _sanitizeForQuery(artist);
      final query = 'releasegroup:$cleanTitle AND artist:$cleanArtist';

      final uri = Uri.https('musicbrainz.org', '/ws/2/release-group', {
        'query': query,
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = data['release-groups'] as List?;
      if (groups == null || groups.isEmpty) return const [];

      final first = groups.first as Map<String, dynamic>;
      final firstReleaseDate = first['first-release-date'] as String?;
      if (firstReleaseDate != null && firstReleaseDate.trim().isNotEmpty) {
        _releaseDateCache['${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}'] = firstReleaseDate.trim();
      }

      final tags = first['tags'] as List?;
      if (tags == null) return const [];

      final items = List<Map<String, dynamic>>.from(
        tags.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = (a['count'] as num?)?.toInt() ?? 0;
        final countB = (b['count'] as num?)?.toInt() ?? 0;
        return countB.compareTo(countA);
      });

      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Retrieves the accurate encyclopedic original release date from MusicBrainz release-group.
  Future<String?> getOriginalReleaseDate({
    required String artist,
    required String title,
  }) async {
    final cleanArtist = artist.trim();
    final cleanTitle = title.trim();
    if (cleanArtist.isEmpty && cleanTitle.isEmpty) return null;

    final cacheKey = '${cleanArtist.toLowerCase()}:::${cleanTitle.toLowerCase()}';
    if (_releaseDateCache.containsKey(cacheKey)) {
      return _releaseDateCache[cacheKey];
    }

    try {
      final cleanTitleSanitized = _sanitizeForQuery(cleanTitle);
      final cleanArtistSanitized = _sanitizeForQuery(cleanArtist);
      final query = 'releasegroup:$cleanTitleSanitized AND artist:$cleanArtistSanitized';

      final uri = Uri.https('musicbrainz.org', '/ws/2/release-group', {
        'query': query,
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final groups = data['release-groups'] as List?;
      if (groups == null || groups.isEmpty) return null;

      final first = groups.first as Map<String, dynamic>;
      final date = first['first-release-date'] as String?;
      if (date != null && date.trim().isNotEmpty) {
        _releaseDateCache[cacheKey] = date.trim();
        return date.trim();
      }
    } catch (_) {}
    return null;
  }

  Future<List<String>> _fetchMusicBrainzArtistTags(String artist) async {
    try {
      final cleanArtist = _sanitizeForQuery(artist);
      final uri = Uri.https('musicbrainz.org', '/ws/2/artist', {
        'query': 'artist:$cleanArtist',
        'fmt': 'json',
      });

      final response = await _client.get(
        uri,
        headers: {
          'User-Agent': 'GroovdMusicApp/1.0.0 (contact@groovd.fm)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final artists = data['artists'] as List?;
      if (artists == null || artists.isEmpty) return const [];

      final first = artists.first as Map<String, dynamic>;
      final tags = first['tags'] as List?;
      if (tags == null) return const [];

      final items = List<Map<String, dynamic>>.from(
        tags.whereType<Map<String, dynamic>>(),
      );
      items.sort((a, b) {
        final countA = (a['count'] as num?)?.toInt() ?? 0;
        final countB = (b['count'] as num?)?.toInt() ?? 0;
        return countB.compareTo(countA);
      });

      return items
          .map((t) => t['name']?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // --------------------------------------------------------------------------
  // Helpers
  // --------------------------------------------------------------------------

  String _sanitizeForQuery(String input) {
    // Strip punctuation that could break Lucene queries
    return input.replaceAll(RegExp(r'[\/\\:*\?"<>|~^!\[\]{}+-]'), ' ').trim();
  }

  List<String> _cleanAndDeduplicate(List<String> raw) {
    final seen = <String>{};
    final result = <String>[];

    for (final tag in raw) {
      final lower = tag.trim().toLowerCase();
      if (lower.isEmpty || lower.length > 28 || lower.length < 2) continue;
      if (RegExp(r'^\d+$').hasMatch(lower) || RegExp(r'^\d+s$').hasMatch(lower)) continue;
      if (_ignoredTags.contains(lower)) continue;
      if (lower.contains('discogs') || lower.contains('favorite') || lower.contains('review')) continue;

      final normalized = _formatGenre(lower);
      if (seen.add(normalized.toUpperCase())) {
        result.add(normalized.toUpperCase());
      }
    }

    return result;
  }

  String _formatGenre(String s) {
    // Normalization rules for clean visual appearance
    final normalized = s.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (normalized == 'r&b' || normalized == 'rnb') return 'R&B';
    if (normalized == 'hip hop' || normalized == 'hiphop') return 'HIP-HOP';
    if (normalized == 'post punk') return 'POST-PUNK';
    if (normalized == 'art pop') return 'ART POP';
    if (normalized == 'art rock') return 'ART ROCK';
    if (normalized == 'indie rock') return 'INDIE ROCK';
    if (normalized == 'synth pop' || normalized == 'synthpop') return 'SYNTH-POP';
    if (normalized == 'dream pop') return 'DREAM POP';
    if (normalized == 'neo soul') return 'NEO-SOUL';
    if (normalized == 'french house') return 'FRENCH HOUSE';
    return normalized.toUpperCase();
  }
}
