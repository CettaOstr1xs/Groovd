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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
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

  static const List<String> _fullMonthNames = [
    'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
    'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER'
  ];

  static const List<String> _shortMonthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];

  /// Accurate release year (e.g. '2008'). Does NOT default to fake '2024' when date is missing.
  String get formattedYear {
    final clean = releaseDate.trim();
    if (clean.isEmpty) return '';
    final yearMatch = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(clean);
    if (yearMatch != null) {
      return yearMatch.group(1)!;
    }
    if (clean.length >= 4) {
      return clean.substring(0, 4);
    }
    return clean;
  }

  /// Full formatted release date with day, month, and year (e.g. '5 OCTOBER 2023' or '24 JANUARY 2008').
  String get formattedReleaseDate {
    final clean = releaseDate.trim();
    if (clean.isEmpty) return '';

    // Format 1: YYYY-MM-DD or YYYY/MM/DD
    final ymdMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(clean);
    if (ymdMatch != null) {
      final year = ymdMatch.group(1)!;
      final month = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final day = int.tryParse(ymdMatch.group(3)!) ?? 1;
      final monthName = (month >= 1 && month <= 12) ? _fullMonthNames[month - 1] : '';
      if (monthName.isNotEmpty) {
        return '$day $monthName $year';
      }
      return '$day/$month/$year';
    }

    // Format 2: YYYY-MM
    final ymMatch = RegExp(r'^(\d{4})[-/](\d{1,2})$').firstMatch(clean);
    if (ymMatch != null) {
      final year = ymMatch.group(1)!;
      final month = int.tryParse(ymMatch.group(2)!) ?? 1;
      final monthName = (month >= 1 && month <= 12) ? _fullMonthNames[month - 1] : '';
      if (monthName.isNotEmpty) {
        return '$monthName $year';
      }
      return '$month/$year';
    }

    // Format 3: DD-MM-YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})').firstMatch(clean);
    if (dmyMatch != null) {
      final day = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final month = int.tryParse(dmyMatch.group(2)!) ?? 1;
      final year = dmyMatch.group(3)!;
      final monthName = (month >= 1 && month <= 12) ? _fullMonthNames[month - 1] : '';
      if (monthName.isNotEmpty) {
        return '$day $monthName $year';
      }
      return '$day/$month/$year';
    }

    // Standard DateTime parsing fallback
    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      final monthName = _fullMonthNames[parsed.month - 1];
      return '${parsed.day} $monthName ${parsed.year}';
    }

    // Single year e.g. '2008'
    if (RegExp(r'^\d{4}$').hasMatch(clean)) {
      return clean;
    }

    return clean.toUpperCase();
  }

  /// Compact formatted release date for cards and list tiles (e.g. '5 OCT 2023', '24 JAN 2008', or '2008').
  String get formattedReleaseDateCompact {
    final clean = releaseDate.trim();
    if (clean.isEmpty) return '';

    final ymdMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(clean);
    if (ymdMatch != null) {
      final year = ymdMatch.group(1)!;
      final month = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final day = int.tryParse(ymdMatch.group(3)!) ?? 1;
      final monthName = (month >= 1 && month <= 12) ? _shortMonthNames[month - 1] : '';
      if (monthName.isNotEmpty) {
        return '$day $monthName $year';
      }
    }

    final ymMatch = RegExp(r'^(\d{4})[-/](\d{1,2})$').firstMatch(clean);
    if (ymMatch != null) {
      final year = ymMatch.group(1)!;
      final month = int.tryParse(ymMatch.group(2)!) ?? 1;
      final monthName = (month >= 1 && month <= 12) ? _shortMonthNames[month - 1] : '';
      if (monthName.isNotEmpty) {
        return '$monthName $year';
      }
    }

    return formattedYear;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MusicItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          artist == other.artist &&
          type == other.type &&
          releaseDate == other.releaseDate;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      artist.hashCode ^
      type.hashCode ^
      releaseDate.hashCode;

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

  /// Normalizes a release or song title for resilient cross-catalog matching.
  static String normalizeTitle(String title) {
    var t = title.trim().toLowerCase();
    // Normalize unicode punctuation
    t = t
        .replaceAll('’', '\'')
        .replaceAll('‘', '\'')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    // Strip common editions / remasters in brackets/parentheses e.g. (2011 Remaster), (Deluxe Edition), [Remastered]
    t = t.replaceAll(
      RegExp(
        r'\s*[\(\[][^\)\]]*(?:deluxe|remaster|anniversary|expanded|edition|explicit|clean|bonus|version|original)[^\)\]]*[\)\]]',
        caseSensitive: false,
      ),
      '',
    );
    // Strip trailing - Single, - EP, - Remastered 2024
    t = t.replaceAll(RegExp(r'\s*-\s*(single|ep|remastered|\d{4}\s*remaster)$', caseSensitive: false), '');
    // Condense whitespace
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// Normalizes an artist name for resilient cross-catalog matching.
  static String normalizeArtist(String artist) {
    var a = artist.trim().toLowerCase();
    // Normalize unicode punctuation
    a = a
        .replaceAll('’', '\'')
        .replaceAll('‘', '\'')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-');

    // Extract primary artist if features are present e.g. 'Kendrick Lamar feat. Rihanna' -> 'Kendrick Lamar'
    final featMatch = RegExp(r'\s*(feat\.?|ft\.?|with|featuring)\s+.*$', caseSensitive: false).firstMatch(a);
    if (featMatch != null) {
      a = a.substring(0, featMatch.start).trim();
    }
    // Extract first artist if comma-separated or ampersand
    if (a.contains(',')) {
      a = a.split(',').first.trim();
    }
    if (a.contains(' & ')) {
      a = a.split(' & ').first.trim();
    }
    return a.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const Map<String, String> _cyrillicToLatinMap = {
    'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'е': 'e', 'ё': 'yo',
    'ж': 'zh', 'з': 'z', 'и': 'i', 'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm',
    'н': 'n', 'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't', 'у': 'u',
    'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch', 'ш': 'sh', 'щ': 'shch',
    'ъ': '', 'ы': 'y', 'ь': '', 'э': 'e', 'ю': 'yu', 'я': 'ya',
  };

  /// Transliterates Cyrillic text to phonetic Latin for cross-catalog comparison.
  static String cyrillicToLatin(String input) {
    final sb = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i].toLowerCase();
      sb.write(_cyrillicToLatinMap[char] ?? input[i]);
    }
    return sb.toString();
  }

  /// Converts any string into a stripped phonetic key for cross-catalog index matching.
  static String toLatinKey(String input) {
    var s = cyrillicToLatin(input.trim().toLowerCase());
    s = s.replaceAll('y', 'i');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  /// Known cross-alphabet artist aliases (e.g. Spotify Latin vs Deezer Cyrillic/Kanji).
  static const Map<String, List<String>> _artistAliases = {
    'kino': ['кино'],
    'кино': ['kino'],
    'tsoi': ['цой', 'виктор цой', 'кино'],
    'tsoy': ['цой', 'виктор цой', 'кино'],
    'цой': ['tsoi', 'kino'],
    'виктор цой': ['viktor tsoi', 'kino'],
    'grazhdanskaya oborona': ['гражданская оборона', 'гроб'],
    'гражданская оборона': ['grazhdanskaya oborona'],
    'grob': ['гражданская оборона', 'гроб'],
    'гроб': ['grazhdanskaya oborona'],
    'ddt': ['ддт'],
    'ддт': ['ddt'],
    'aquarium': ['аквариум'],
    'akvarium': ['аквариум'],
    'аквариум': ['aquarium'],
    'zemfira': ['земфира'],
    'земфира': ['zemfira'],
    'korol i shut': ['король и шут', 'киш'],
    'король и шут': ['korol i shut'],
    'splean': ['сплин'],
    'splin': ['сплин'],
    'сплин': ['splean'],
    'mumiy troll': ['мумий тролль'],
    'мумий тролль': ['mumiy troll'],
    'nautilus pompilius': ['наутилус помпилиус'],
    'наутилус помпилиус': ['nautilus pompilius'],
    'bi-2': ['би-2'],
    'bi 2': ['би-2'],
    'би-2': ['bi-2'],
    'aria': ['ария'],
    'ария': ['aria'],
    'ploho': ['плохо'],
    'плохо': ['ploho'],
    'molchat doma': ['молчат дома'],
    'молчат дома': ['molchat doma'],
    'kinoko teikoku': ['きのこ帝国'],
    'きのこ帝国': ['kinoko teikoku'],
    'midori': ['ミドリ'],
    'ミドリ': ['midori'],
    'fishmans': ['フィッシュマンズ'],
    'フィッシュマンズ': ['fishmans'],
    'soutaiseiriron': ['相対性理論'],
    '相対性理論': ['soutaiseiriron'],
    'radwimps': ['ラッドウィンプス'],
    'ラッドウィンプス': ['radwimps'],
    'the black skirts': ['검정치마'],
    '검정치마': ['the black skirts'],
    'hyukoh': ['혁오'],
    '혁오': ['hyukoh'],
    'se so neon': ['새소년'],
    '새소년': ['se so neon'],
  };

  /// Checks whether two artist strings refer to the same artist across languages and scripts.
  static bool areArtistsEquivalent(String artist1, String artist2) {
    final a1 = normalizeArtist(artist1);
    final a2 = normalizeArtist(artist2);
    if (a1.isEmpty || a2.isEmpty) return false;
    if (a1 == a2 || a1.contains(a2) || a2.contains(a1)) return true;

    // Direct key equivalence via Cyrillic-to-Latin transliteration
    final k1 = toLatinKey(a1);
    final k2 = toLatinKey(a2);
    if (k1.isNotEmpty && k2.isNotEmpty && (k1 == k2 || k1.contains(k2) || k2.contains(k1))) {
      return true;
    }

    // Check parenthesized alias extraction e.g. 東京酒吐座(Tokyo Shoegazer)
    final p1 = RegExp(r'\(([^)]+)\)').firstMatch(a1)?.group(1)?.trim();
    if (p1 != null && p1.isNotEmpty && (p1 == a2 || p1.contains(a2) || a2.contains(p1))) {
      return true;
    }
    final p2 = RegExp(r'\(([^)]+)\)').firstMatch(a2)?.group(1)?.trim();
    if (p2 != null && p2.isNotEmpty && (p2 == a1 || p2.contains(a1) || a1.contains(p2))) {
      return true;
    }

    // Check alias mapping
    final aliases1 = _artistAliases[a1] ?? const [];
    if (aliases1.any((alias) {
      final aLower = alias.toLowerCase();
      return a2 == aLower || a2.contains(aLower) || toLatinKey(a2) == toLatinKey(aLower);
    })) {
      return true;
    }

    final aliases2 = _artistAliases[a2] ?? const [];
    if (aliases2.any((alias) {
      final aLower = alias.toLowerCase();
      return a1 == aLower || a1.contains(aLower) || toLatinKey(a1) == toLatinKey(aLower);
    })) {
      return true;
    }

    return false;
  }

  /// Checks whether two release/track titles match across scripts and editions.
  static bool areTitlesEquivalent(String name1, String name2) {
    final n1 = normalizeTitle(name1);
    final n2 = normalizeTitle(name2);
    if (n1.isEmpty || n2.isEmpty) return false;
    if (n1 == n2 || n1.contains(n2) || n2.contains(n1)) return true;

    // Key equivalence via transliteration
    final k1 = toLatinKey(n1);
    final k2 = toLatinKey(n2);
    if (k1.isNotEmpty && k2.isNotEmpty && (k1 == k2 || k1.contains(k2) || k2.contains(k1))) {
      return true;
    }

    return false;
  }

  /// Checks whether two items/queries represent the same musical work across different
  /// API providers (Deezer, Spotify, Mock, etc.).
  static bool isSameRelease({
    required String name1,
    required String artist1,
    String? type1,
    String? id1,
    required String name2,
    required String artist2,
    String? type2,
    String? id2,
  }) {
    if (id1 != null && id2 != null && id1.isNotEmpty && id2.isNotEmpty && id1 == id2) {
      return true;
    }

    final artistsMatch = areArtistsEquivalent(artist1, artist2);
    if (!artistsMatch) return false;

    final titlesMatch = areTitlesEquivalent(name1, name2);
    if (!titlesMatch) return false;

    // Distinguish standalone single tracks from full albums/EPs if types are both known
    if (type1 != null && type2 != null && type1.isNotEmpty && type2.isNotEmpty) {
      final isRelease1 = type1 == 'album' || type1 == 'ep';
      final isRelease2 = type2 == 'album' || type2 == 'ep';
      if (isRelease1 != isRelease2) return false;
    }

    return true;
  }

  /// Convenience method on a MusicItem instance to check equality of work with another item.
  bool isSameWork(MusicItem other) {
    return isSameRelease(
      name1: name,
      artist1: artist,
      type1: type.name,
      id1: id,
      name2: other.name,
      artist2: other.artist,
      type2: other.type.name,
      id2: other.id,
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
