import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum MusicType { album, song, ep }

class TrackInfo {
  final String id;
  final String name;
  final int trackNumber;
  final int durationMs;
  final String? previewUrl;
  final String artist;

  const TrackInfo({
    required this.id,
    required this.name,
    required this.trackNumber,
    required this.durationMs,
    this.previewUrl,
    required this.artist,
  });

  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'trackNumber': trackNumber,
      'durationMs': durationMs,
      'previewUrl': previewUrl,
      'artist': artist,
    };
  }

  factory TrackInfo.fromMap(Map<String, dynamic> map) {
    return TrackInfo(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      trackNumber: (map['trackNumber'] as num?)?.toInt() ?? 1,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      previewUrl: map['previewUrl'] as String?,
      artist: map['artist'] as String? ?? '',
    );
  }

  factory TrackInfo.fromSpotifyJson(Map<String, dynamic> json, {String defaultArtist = ''}) {
    String artistName = defaultArtist;
    final artistsList = json['artists'] as List?;
    if (artistsList != null && artistsList.isNotEmpty) {
      artistName = artistsList.map((a) => a['name'] as String).join(', ');
    }

    return TrackInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      trackNumber: (json['track_number'] as num?)?.toInt() ?? 1,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      previewUrl: json['preview_url'] as String?,
      artist: artistName,
    );
  }

  factory TrackInfo.fromDeezerJson(
    Map<String, dynamic> json, {
    String defaultArtist = '',
    int fallbackTrackNumber = 1,
  }) {
    String artistName = defaultArtist;
    if (json['artist'] is Map && json['artist']['name'] != null) {
      artistName = json['artist']['name'].toString();
    }

    final durationSeconds = (json['duration'] as num?)?.toInt() ?? 0;
    final parsedPos = (json['track_position'] as num?)?.toInt() ??
        (json['track_number'] as num?)?.toInt() ??
        (json['track_pos'] as num?)?.toInt() ??
        (json['position'] as num?)?.toInt();
    final trackNum = (parsedPos != null && parsedPos > 0)
        ? parsedPos
        : fallbackTrackNumber;

    return TrackInfo(
      id: json['id'].toString(),
      name: json['title'] as String? ?? '',
      trackNumber: trackNum,
      durationMs: durationSeconds * 1000,
      previewUrl: null,
      artist: artistName,
    );
  }
}

class MusicItem {
  final String id;
  final String name;
  final String artist;
  final MusicType type;
  final String coverUrl;
  final String releaseDate;
  final List<String> genres;
  final int trackCount;
  final int durationMs;
  final String? previewUrl;
  final String externalSpotifyUrl;
  final List<TrackInfo> tracks;
  final int popularity;

  const MusicItem({
    required this.id,
    required this.name,
    required this.artist,
    required this.type,
    required this.coverUrl,
    required this.releaseDate,
    this.genres = const [],
    this.trackCount = 1,
    this.durationMs = 0,
    this.previewUrl,
    this.externalSpotifyUrl = '',
    this.tracks = const [],
    this.popularity = 0,
  });

  bool get isAlbum => type == MusicType.album;
  bool get isSong => type == MusicType.song;
  bool get isEp => type == MusicType.ep;
  bool get isRelease => isAlbum || isEp;

  /// Compact badge text: 'LP', 'EP', or 'TRACK'
  String get typeBadgeLabel {
    if (isEp) return 'EP';
    if (isAlbum) return 'LP';
    return 'TRACK';
  }

  /// Compact alternative: 'LP', 'EP', or 'SINGLE'
  String get typeLabel {
    if (isEp) return 'EP';
    if (isAlbum) return 'LP';
    return 'SINGLE';
  }

  /// Detailed header badge: 'LP // ALBUM', 'EP // EXTENDED PLAY', 'SINGLE // TRACK'
  String get fullTypeLabel {
    if (isEp) return 'EP // EXTENDED PLAY';
    if (isAlbum) return 'LP // ALBUM';
    return 'SINGLE // TRACK';
  }

  /// High-contrast Neo-Brutalist badge color: Acid Lime for LP, Electric Pink for EP, Cyber Cyan for Single
  Color get typeColor {
    if (isEp) return AppColors.electricPink;
    if (isAlbum) return AppColors.acidLime;
    return AppColors.cyberCyan;
  }

  String get formattedYear {
    if (releaseDate.isEmpty) return '2024';
    if (releaseDate.length >= 4) {
      return releaseDate.substring(0, 4);
    }
    return releaseDate;
  }

  String get formattedDuration {
    if (durationMs <= 0) return '';
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (isAlbum || isEp) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      if (hours > 0) {
        return '${hours}h ${remainingMins}m';
      }
      return '$minutes MIN';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'type': type.name,
      'coverUrl': coverUrl,
      'releaseDate': releaseDate,
      'genres': genres,
      'trackCount': trackCount,
      'durationMs': durationMs,
      'previewUrl': previewUrl,
      'externalSpotifyUrl': externalSpotifyUrl,
      'tracks': tracks.map((t) => t.toMap()).toList(),
      'popularity': popularity,
    };
  }

  factory MusicItem.fromMap(Map<String, dynamic> map) {
    return MusicItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      type: (map['type'] == 'ep' || map['type'] == MusicType.ep.name)
          ? MusicType.ep
          : (map['type'] == 'album' || map['type'] == MusicType.album.name)
              ? MusicType.album
              : MusicType.song,
      coverUrl: map['coverUrl'] as String? ?? '',
      releaseDate: map['releaseDate'] as String? ?? '',
      genres: (map['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      trackCount: (map['trackCount'] as num?)?.toInt() ?? 1,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      previewUrl: map['previewUrl'] as String?,
      externalSpotifyUrl: map['externalSpotifyUrl'] as String? ?? '',
      tracks: (map['tracks'] as List?)
              ?.map((t) => TrackInfo.fromMap(t as Map<String, dynamic>))
              .toList() ??
          const [],
      popularity: (map['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  /// Detects whether a release qualifies as an EP (Extended Play).
  ///
  /// Criteria:
  /// 1. The title explicitly indicates it with 'EP' tokens (e.g., '... EP', '... - EP', '... (EP)', '... [EP]').
  /// 2. Track count is between 3 and 6 tracks (unless total runtime exceeds typical EP limit of ~32 minutes).
  /// 3. Spotify `album_type` / `album_group` is 'single' or 'album', but the release contains multiple tracks (3-6).
  static bool isEpRelease({
    required String name,
    required String rawAlbumType,
    required int trackCount,
    int durationMs = 0,
  }) {
    final cleanName = name.trim();
    final hasEpInTitle = RegExp(r'(^|[\s\(\[\-_/])ep([\s\)\]\-_/]|$)', caseSensitive: false).hasMatch(cleanName);

    // If explicitly titled as EP, it is an EP as long as it's not a massive boxset (> 12 tracks)
    if (hasEpInTitle && trackCount <= 12) {
      return true;
    }

    // Standard EP definition: 3 to 6 tracks (or 4 to 6 tracks)
    if (trackCount >= 3 && trackCount <= 6) {
      // If duration is known and is longer than 32 minutes, treat as a concise LP instead
      if (durationMs > 0 && durationMs > 32 * 60 * 1000) {
        return false;
      }
      return true;
    }

    // If Spotify classified as 'single' but it has multiple tracks (at least 3), it's an EP
    if (rawAlbumType == 'single' && trackCount >= 3) {
      return true;
    }

    return false;
  }

  /// Parses an album from Spotify Web API response.
  factory MusicItem.fromSpotifyAlbum(Map<String, dynamic> json) {
    String artistName = 'Unknown Artist';
    final artistsList = json['artists'] as List?;
    if (artistsList != null && artistsList.isNotEmpty) {
      artistName = artistsList.map((a) => a['name'] as String).join(', ');
    }

    String cover = '';
    final images = json['images'] as List?;
    if (images != null && images.isNotEmpty) {
      cover = images.first['url'] as String? ?? '';
    }

    final tracksList = <TrackInfo>[];
    if (json['tracks'] != null && json['tracks']['items'] != null) {
      for (final t in json['tracks']['items'] as List) {
        tracksList.add(TrackInfo.fromSpotifyJson(t as Map<String, dynamic>, defaultArtist: artistName));
      }
    }

    final externalUrls = json['external_urls'] as Map<String, dynamic>?;
    final spotifyUrl = externalUrls?['spotify'] as String? ?? '';
    final rawAlbumType = (json['album_type'] as String? ?? json['album_group'] as String? ?? '').toLowerCase().trim();
    final albumName = json['name'] as String? ?? '';
    final totalTracks = (json['total_tracks'] as num?)?.toInt() ?? tracksList.length;
    final totalDurationMs = tracksList.fold<int>(0, (sum, t) => sum + t.durationMs);

    final MusicType resolvedType;
    if (isEpRelease(
      name: albumName,
      rawAlbumType: rawAlbumType,
      trackCount: totalTracks,
      durationMs: totalDurationMs,
    )) {
      resolvedType = MusicType.ep;
    } else if (rawAlbumType == 'single' && totalTracks <= 2) {
      resolvedType = MusicType.song;
    } else {
      resolvedType = MusicType.album;
    }

    return MusicItem(
      id: json['id'] as String? ?? '',
      name: albumName,
      artist: artistName,
      type: resolvedType,
      coverUrl: cover,
      releaseDate: json['release_date'] as String? ?? '',
      genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      trackCount: totalTracks,
      durationMs: totalDurationMs,
      previewUrl: tracksList.isNotEmpty ? tracksList.first.previewUrl : null,
      externalSpotifyUrl: spotifyUrl,
      tracks: tracksList,
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  MusicItem copyWith({
    String? id,
    String? name,
    String? artist,
    MusicType? type,
    String? coverUrl,
    String? releaseDate,
    List<String>? genres,
    int? trackCount,
    int? durationMs,
    String? previewUrl,
    String? externalSpotifyUrl,
    List<TrackInfo>? tracks,
    int? popularity,
  }) {
    return MusicItem(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      type: type ?? this.type,
      coverUrl: coverUrl ?? this.coverUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      genres: genres ?? this.genres,
      trackCount: trackCount ?? this.trackCount,
      durationMs: durationMs ?? this.durationMs,
      previewUrl: previewUrl ?? this.previewUrl,
      externalSpotifyUrl: externalSpotifyUrl ?? this.externalSpotifyUrl,
      tracks: tracks ?? this.tracks,
      popularity: popularity ?? this.popularity,
    );
  }

  /// Parses a track from Spotify Web API response.
  factory MusicItem.fromSpotifyTrack(Map<String, dynamic> json) {
    String artistName = 'Unknown Artist';
    final artistsList = json['artists'] as List?;
    if (artistsList != null && artistsList.isNotEmpty) {
      artistName = artistsList.map((a) => a['name'] as String).join(', ');
    }

    String cover = '';
    final album = json['album'] as Map<String, dynamic>?;
    if (album != null && album['images'] != null) {
      final images = album['images'] as List;
      for (final img in images) {
        final url = (img as Map<String, dynamic>?)?['url'] as String?;
        if (url != null && url.isNotEmpty) {
          cover = url;
          break;
        }
      }
    }
    if (cover.isEmpty && json['images'] != null) {
      final images = json['images'] as List;
      for (final img in images) {
        final url = (img as Map<String, dynamic>?)?['url'] as String?;
        if (url != null && url.isNotEmpty) {
          cover = url;
          break;
        }
      }
    }

    final externalUrls = json['external_urls'] as Map<String, dynamic>?;
    final spotifyUrl = externalUrls?['spotify'] as String? ?? '';

    return MusicItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      artist: artistName,
      type: MusicType.song,
      coverUrl: cover,
      releaseDate: album?['release_date'] as String? ?? '',
      genres: const [],
      trackCount: 1,
      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
      previewUrl: json['preview_url'] as String?,
      externalSpotifyUrl: spotifyUrl,
      tracks: [
        TrackInfo(
          id: json['id'] as String? ?? '',
          name: json['name'] as String? ?? '',
          trackNumber: (json['track_number'] as num?)?.toInt() ?? 1,
          durationMs: (json['duration_ms'] as num?)?.toInt() ?? 0,
          previewUrl: json['preview_url'] as String?,
          artist: artistName,
        ),
      ],
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    );
  }

  /// Parses an album from Deezer API response.
  factory MusicItem.fromDeezerAlbum(Map<String, dynamic> json) {
    String artistName = 'Unknown Artist';
    if (json['artist'] is Map && json['artist']['name'] != null) {
      artistName = json['artist']['name'].toString();
    } else if (json['contributors'] is List && (json['contributors'] as List).isNotEmpty) {
      artistName = (json['contributors'] as List)
          .map((c) => (c as Map)['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .join(', ');
    }

    final cover = json['cover_xl'] as String? ??
        json['cover_big'] as String? ??
        json['cover_medium'] as String? ??
        json['cover'] as String? ??
        '';

    final tracksList = <TrackInfo>[];
    if (json['tracks'] != null && json['tracks']['data'] is List) {
      final list = json['tracks']['data'] as List;
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        if (t is Map<String, dynamic>) {
          tracksList.add(TrackInfo.fromDeezerJson(
            t,
            defaultArtist: artistName,
            fallbackTrackNumber: i + 1,
          ));
        }
      }
    }

    final link = json['link'] as String? ?? '';
    final recordType = (json['record_type'] as String? ?? 'album').toLowerCase().trim();
    final albumName = json['title'] as String? ?? '';
    final totalTracks = (json['nb_tracks'] as num?)?.toInt() ?? (tracksList.isNotEmpty ? tracksList.length : 1);
    final durationSeconds = (json['duration'] as num?)?.toInt() ?? 0;
    final totalDurationMs = durationSeconds > 0
        ? durationSeconds * 1000
        : tracksList.fold<int>(0, (sum, t) => sum + t.durationMs);

    final genresList = <String>[];
    if (json['genres'] != null && json['genres']['data'] is List) {
      for (final g in json['genres']['data'] as List) {
        if (g is Map && g['name'] != null) {
          genresList.add(g['name'].toString().toUpperCase());
        }
      }
    }

    final MusicType resolvedType;
    if (recordType == 'ep' ||
        isEpRelease(
          name: albumName,
          rawAlbumType: recordType,
          trackCount: totalTracks,
          durationMs: totalDurationMs,
        )) {
      resolvedType = MusicType.ep;
    } else {
      resolvedType = MusicType.album;
    }

    return MusicItem(
      id: json['id'].toString(),
      name: albumName,
      artist: artistName,
      type: resolvedType,
      coverUrl: cover,
      releaseDate: json['release_date'] as String? ?? '',
      genres: genresList,
      trackCount: totalTracks,
      durationMs: totalDurationMs,
      previewUrl: null,
      externalSpotifyUrl: link,
      tracks: tracksList,
      popularity: ((json['fans'] as num?)?.toInt() ?? 0) ~/ 1000,
    );
  }

  /// Parses a track from Deezer API response.
  factory MusicItem.fromDeezerTrack(Map<String, dynamic> json) {
    String artistName = 'Unknown Artist';
    if (json['artist'] is Map && json['artist']['name'] != null) {
      artistName = json['artist']['name'].toString();
    }

    String cover = '';
    final album = json['album'] as Map<String, dynamic>?;
    if (album != null) {
      cover = album['cover_xl'] as String? ??
          album['cover_big'] as String? ??
          album['cover_medium'] as String? ??
          album['cover'] as String? ??
          '';
    }

    final link = json['link'] as String? ?? '';
    final durationSeconds = (json['duration'] as num?)?.toInt() ?? 0;
    final durationMs = durationSeconds * 1000;
    final trackId = json['id'].toString();
    final trackName = json['title'] as String? ?? '';

    return MusicItem(
      id: trackId,
      name: trackName,
      artist: artistName,
      type: MusicType.song,
      coverUrl: cover,
      releaseDate: json['release_date'] as String? ?? album?['release_date'] as String? ?? '',
      genres: const [],
      trackCount: 1,
      durationMs: durationMs,
      previewUrl: null,
      externalSpotifyUrl: link,
      tracks: [
        TrackInfo(
          id: trackId,
          name: trackName,
          trackNumber: (json['track_position'] as num?)?.toInt() ?? 1,
          durationMs: durationMs,
          previewUrl: null,
          artist: artistName,
        ),
      ],
      popularity: (((json['rank'] as num?)?.toInt() ?? 0) ~/ 10000).clamp(0, 100),
    );
  }
}
