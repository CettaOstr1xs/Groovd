enum MusicType { album, song }

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
    if (isAlbum) {
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
      type: (map['type'] == 'album' || map['type'] == MusicType.album.name)
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

    return MusicItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      artist: artistName,
      type: MusicType.album,
      coverUrl: cover,
      releaseDate: json['release_date'] as String? ?? '',
      genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      trackCount: (json['total_tracks'] as num?)?.toInt() ?? tracksList.length,
      durationMs: tracksList.fold<int>(0, (sum, t) => sum + t.durationMs),
      previewUrl: tracksList.isNotEmpty ? tracksList.first.previewUrl : null,
      externalSpotifyUrl: spotifyUrl,
      tracks: tracksList,
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
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
      if (images.isNotEmpty) {
        cover = images.first['url'] as String? ?? '';
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
}
