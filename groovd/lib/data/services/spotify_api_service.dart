import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/music_item.dart';

class SpotifyApiService {
  String? clientId;
  String? clientSecret;

  String? _accessToken;
  DateTime? _tokenExpiry;

  SpotifyApiService({this.clientId, this.clientSecret});

  bool get isConfigured =>
      clientId != null &&
      clientId!.trim().isNotEmpty &&
      clientSecret != null &&
      clientSecret!.trim().isNotEmpty;

  void updateCredentials(String newClientId, String newClientSecret) {
    clientId = newClientId.trim();
    clientSecret = newClientSecret.trim();
    _accessToken = null;
    _tokenExpiry = null;
  }

  /// Request or reuse an OAuth2 Client Credentials access token from Spotify.
  Future<String?> _getValidToken({bool forceRefresh = false}) async {
    if (!isConfigured) return null;

    if (!forceRefresh &&
        _accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'grant_type': 'client_credentials'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _accessToken = data['access_token'] as String?;
        final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        return _accessToken;
      } else {
        // ignore: avoid_print
        print('Spotify Token Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Spotify Auth Exception: $e');
      return null;
    }
  }

  /// Search for albums and tracks.
  Future<List<MusicItem>> search(String query, {String type = 'album,track', int limit = 10}) async {
    final token = await _getValidToken();
    if (token == null) return [];

    // Spotify caps limit to 10 for developer mode apps; exceeding this causes a 400 'Invalid limit' error.
    final safeLimit = limit.clamp(1, 10);

    try {
      final uri = Uri.https('api.spotify.com', '/v1/search', {
        'q': query,
        'type': type,
        'limit': safeLimit.toString(),
      });
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        final freshToken = await _getValidToken(forceRefresh: true);
        if (freshToken != null) {
          response = await http.get(uri, headers: {'Authorization': 'Bearer $freshToken'});
        }
      }

      // If Spotify returns 400 with 'Invalid limit', retry once with limit=5
      if (response.statusCode == 400 &&
          response.body.contains('Invalid limit') &&
          safeLimit > 5) {
        final retryUri = Uri.https('api.spotify.com', '/v1/search', {
          'q': query,
          'type': type,
          'limit': '5',
        });
        response = await http.get(
          retryUri,
          headers: {'Authorization': 'Bearer $token'},
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = <MusicItem>[];

        if (data['albums'] != null && data['albums']['items'] != null) {
          for (final a in data['albums']['items'] as List) {
            items.add(MusicItem.fromSpotifyAlbum(a as Map<String, dynamic>));
          }
        }

        if (data['tracks'] != null && data['tracks']['items'] != null) {
          for (final t in data['tracks']['items'] as List) {
            items.add(MusicItem.fromSpotifyTrack(t as Map<String, dynamic>));
          }
        }

        return items;
      } else {
        // ignore: avoid_print
        print('Spotify Search Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      // ignore: avoid_print
      print('Spotify Search Exception: $e');
      return [];
    }
  }

  final Map<String, List<String>> _artistGenreCache = {};

  /// Fetch primary genres for an artist from Spotify.
  Future<List<String>> getArtistGenres(String artistId) async {
    if (_artistGenreCache.containsKey(artistId)) {
      return _artistGenreCache[artistId]!;
    }
    final token = await _getValidToken();
    if (token == null) return [];

    try {
      final uri = Uri.parse('https://api.spotify.com/v1/artists/$artistId');
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        final freshToken = await _getValidToken(forceRefresh: true);
        if (freshToken != null) {
          response = await http.get(uri, headers: {'Authorization': 'Bearer $freshToken'});
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final genresList = (data['genres'] as List?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ?? [];
        final cleanGenres = genresList.take(4).toList();
        _artistGenreCache[artistId] = cleanGenres;
        return cleanGenres;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get detailed album info including full tracklist and artist genres fallback.
  Future<MusicItem?> getAlbum(String albumId) async {
    final token = await _getValidToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse('https://api.spotify.com/v1/albums/$albumId');
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        final freshToken = await _getValidToken(forceRefresh: true);
        if (freshToken != null) {
          response = await http.get(uri, headers: {'Authorization': 'Bearer $freshToken'});
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        var item = MusicItem.fromSpotifyAlbum(data);
        if (item.genres.isEmpty) {
          final artists = data['artists'] as List?;
          if (artists != null && artists.isNotEmpty) {
            final artistId = artists.first['id'] as String?;
            if (artistId != null && artistId.isNotEmpty) {
              final genres = await getArtistGenres(artistId);
              if (genres.isNotEmpty) {
                item = item.copyWith(genres: genres);
              }
            }
          }
        }
        return item;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Spotify GetAlbum Exception: $e');
      return null;
    }
  }

  /// Get detailed track info and artist genres fallback.
  Future<MusicItem?> getTrack(String trackId) async {
    final token = await _getValidToken();
    if (token == null) return null;

    try {
      final uri = Uri.parse('https://api.spotify.com/v1/tracks/$trackId');
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        final freshToken = await _getValidToken(forceRefresh: true);
        if (freshToken != null) {
          response = await http.get(uri, headers: {'Authorization': 'Bearer $freshToken'});
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        var item = MusicItem.fromSpotifyTrack(data);
        if (item.genres.isEmpty) {
          final artists = data['artists'] as List?;
          if (artists != null && artists.isNotEmpty) {
            final artistId = artists.first['id'] as String?;
            if (artistId != null && artistId.isNotEmpty) {
              final genres = await getArtistGenres(artistId);
              if (genres.isNotEmpty) {
                item = item.copyWith(genres: genres);
              }
            }
          }
        }
        return item;
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Spotify GetTrack Exception: $e');
      return null;
    }
  }

  /// Get new album releases.
  Future<List<MusicItem>> getNewReleases({int limit = 10}) async {
    final token = await _getValidToken();
    if (token == null) return [];

    final safeLimit = limit.clamp(1, 10);

    try {
      final uri = Uri.parse('https://api.spotify.com/v1/browse/new-releases?limit=$safeLimit');
      var response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        final freshToken = await _getValidToken(forceRefresh: true);
        if (freshToken != null) {
          response = await http.get(uri, headers: {'Authorization': 'Bearer $freshToken'});
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = <MusicItem>[];
        if (data['albums'] != null && data['albums']['items'] != null) {
          for (final a in data['albums']['items'] as List) {
            items.add(MusicItem.fromSpotifyAlbum(a as Map<String, dynamic>));
          }
        }
        return items;
      }
      // Spotify restricted /v1/browse/new-releases for dev apps; fallback to searching new albums
      return await search('tag:new', type: 'album', limit: safeLimit);
    } catch (e) {
      // ignore: avoid_print
      print('Spotify NewReleases Exception: $e');
      return await search('tag:new', type: 'album', limit: safeLimit);
    }
  }
}
