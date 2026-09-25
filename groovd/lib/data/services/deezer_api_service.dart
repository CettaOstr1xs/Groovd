import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/artist.dart';
import '../models/music_item.dart';

/// Service providing music metadata directly from the public Deezer API.
/// Requires zero authentication, no client secrets, and no premium subscription.
class DeezerApiService {
  final http.Client _client;
  static const String _baseUrl = 'api.deezer.com';

  final Map<String, MusicItem> _albumCache = {};
  final Map<String, MusicItem> _trackCache = {};
  final Map<String, Map<String, dynamic>> _artistCache = {};

  DeezerApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Search for music items across albums, tracks, or both.
  Future<List<MusicItem>> search(String query, {String type = 'all', int limit = 10}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final safeLimit = limit.clamp(1, 25);

    try {
      if (type == 'album') {
        return await searchAlbums(cleanQuery, limit: safeLimit);
      } else if (type == 'track') {
        return await searchTracks(cleanQuery, limit: safeLimit);
      }

      // Search both concurrently for comprehensive results
      final halfLimit = (safeLimit / 2).ceil().clamp(1, 15);
      final results = await Future.wait([
        searchAlbums(cleanQuery, limit: halfLimit),
        searchTracks(cleanQuery, limit: halfLimit),
      ]);

      final albums = results[0];
      final tracks = results[1];

      final combined = <MusicItem>[];
      final seenIds = <String>{};

      // Interleave results so both top albums and top songs appear high
      final maxLen = albums.length > tracks.length ? albums.length : tracks.length;
      for (var i = 0; i < maxLen; i++) {
        if (i < albums.length) {
          final a = albums[i];
          if (seenIds.add(a.id)) combined.add(a);
        }
        if (i < tracks.length) {
          final t = tracks[i];
          if (seenIds.add(t.id)) combined.add(t);
        }
      }

      return combined.take(safeLimit).toList();
    } catch (_) {
      return [];
    }
  }

  /// Search specifically for albums.
  Future<List<MusicItem>> searchAlbums(String query, {int limit = 10}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final uri = Uri.https(_baseUrl, '/search/album', {
        'q': clean,
        'limit': limit.clamp(1, 25).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return [];
        final data = json['data'] as List?;
        if (data != null) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((a) => MusicItem.fromDeezerAlbum(a))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Search specifically for tracks.
  Future<List<MusicItem>> searchTracks(String query, {int limit = 10}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final uri = Uri.https(_baseUrl, '/search/track', {
        'q': clean,
        'limit': limit.clamp(1, 25).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return [];
        final data = json['data'] as List?;
        if (data != null) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((t) => MusicItem.fromDeezerTrack(t))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Search for matching artists.
  Future<List<Artist>> searchArtists(String query, {int limit = 5}) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    try {
      final uri = Uri.https(_baseUrl, '/search/artist', {
        'q': clean,
        'limit': limit.clamp(1, 20).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return [];
        final data = json['data'] as List?;
        if (data != null) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((a) => Artist.fromDeezerJson(a))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Search for a single artist by name.
  Future<Map<String, dynamic>?> searchArtist(String artistName) async {
    final clean = artistName.trim();
    if (clean.isEmpty) return null;

    try {
      final uri = Uri.https(_baseUrl, '/search/artist', {
        'q': clean,
        'limit': '1',
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return null;
        final data = json['data'] as List?;
        if (data != null && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get detailed album information including complete tracklist.
  Future<MusicItem?> getAlbum(String albumId) async {
    final cleanId = albumId.trim();
    if (cleanId.isEmpty) return null;

    if (_albumCache.containsKey(cleanId) && _albumCache[cleanId]!.tracks.isNotEmpty) {
      return _albumCache[cleanId];
    }

    try {
      final uri = Uri.https(_baseUrl, '/album/$cleanId');
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return null;

        // Ensure complete tracklist: if embedded tracks are empty or truncated, fetch /album/{id}/tracks
        final nbTracks = (json['nb_tracks'] as num?)?.toInt() ?? 0;
        final embeddedTracks = (json['tracks']?['data'] as List?) ?? [];
        if (embeddedTracks.isEmpty || (nbTracks > 0 && embeddedTracks.length < nbTracks)) {
          try {
            final tracksUri = Uri.https(_baseUrl, '/album/$cleanId/tracks', {'limit': '100'});
            final tracksRes = await _client.get(tracksUri);
            if (tracksRes.statusCode == 200) {
              final tracksJson = jsonDecode(tracksRes.body) as Map<String, dynamic>;
              if (tracksJson['data'] is List && (tracksJson['data'] as List).isNotEmpty) {
                json['tracks'] = tracksJson;
              }
            }
          } catch (_) {}
        }

        final item = MusicItem.fromDeezerAlbum(json);
        _albumCache[cleanId] = item;
        return item;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get detailed track information.
  Future<MusicItem?> getTrack(String trackId) async {
    final cleanId = trackId.trim();
    if (cleanId.isEmpty) return null;

    if (_trackCache.containsKey(cleanId)) {
      return _trackCache[cleanId];
    }

    try {
      final uri = Uri.https(_baseUrl, '/track/$cleanId');
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return null;
        final item = MusicItem.fromDeezerTrack(json);
        _trackCache[cleanId] = item;
        return item;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get artist profile details by artist ID.
  Future<Map<String, dynamic>?> getArtist(String artistId) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return null;

    if (_artistCache.containsKey(cleanId)) {
      return _artistCache[cleanId];
    }

    try {
      final uri = Uri.https(_baseUrl, '/artist/$cleanId');
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return null;
        _artistCache[cleanId] = json;
        return json;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get top tracks for an artist.
  Future<List<MusicItem>> getArtistTopTracks(String artistId, {int limit = 10}) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return [];

    try {
      final uri = Uri.https(_baseUrl, '/artist/$cleanId/top', {
        'limit': limit.clamp(1, 20).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return [];
        final data = json['data'] as List?;
        if (data != null) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((t) => MusicItem.fromDeezerTrack(t))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get discography (albums and singles) for an artist.
  Future<List<MusicItem>> getArtistAlbums(String artistId, {int limit = 25}) async {
    final cleanId = artistId.trim();
    if (cleanId.isEmpty) return [];

    try {
      final uri = Uri.https(_baseUrl, '/artist/$cleanId/albums', {
        'limit': limit.clamp(1, 50).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        if (json.containsKey('error')) return [];
        final data = json['data'] as List?;
        if (data != null) {
          final list = <MusicItem>[];
          final seenTitles = <String>{};
          for (final a in data.whereType<Map<String, dynamic>>()) {
            final item = MusicItem.fromDeezerAlbum(a);
            final normTitle = item.name.toLowerCase().trim();
            if (seenTitles.add(normTitle)) {
              list.add(item);
            }
          }
          return list;
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get trending albums derived from current chart releases.
  Future<List<MusicItem>> getTrendingAlbums({int limit = 10}) async {
    try {
      final uri = Uri.https(_baseUrl, '/chart/0/tracks', {
        'limit': '30',
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List?;
        if (data != null) {
          final albums = <MusicItem>[];
          final seenIds = <String>{};
          for (final t in data.whereType<Map<String, dynamic>>()) {
            final alb = t['album'] as Map<String, dynamic>?;
            if (alb != null && alb['id'] != null) {
              final albId = alb['id'].toString();
              if (seenIds.add(albId)) {
                // Ensure artist is attached from track if missing in album object
                final albWithArtist = Map<String, dynamic>.from(alb);
                if (!albWithArtist.containsKey('artist') && t.containsKey('artist')) {
                  albWithArtist['artist'] = t['artist'];
                }
                albums.add(MusicItem.fromDeezerAlbum(albWithArtist));
              }
            }
          }
          if (albums.isNotEmpty) {
            return albums.take(limit).toList();
          }
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get hot trending tracks from current charts.
  Future<List<MusicItem>> getHotTracks({int limit = 10}) async {
    try {
      final uri = Uri.https(_baseUrl, '/chart/0/tracks', {
        'limit': limit.clamp(1, 25).toString(),
      });
      final res = await _client.get(uri);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final data = json['data'] as List?;
        if (data != null) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((t) => MusicItem.fromDeezerTrack(t))
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
