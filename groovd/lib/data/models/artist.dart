class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> genres;
  final int followers;
  final int popularity;
  final String? bio;
  final String? shortDescription;
  final String spotifyUrl;

  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.genres = const [],
    this.followers = 0,
    this.popularity = 0,
    this.bio,
    this.shortDescription,
    this.spotifyUrl = '',
  });

  Artist copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? genres,
    int? followers,
    int? popularity,
    String? bio,
    String? shortDescription,
    String? spotifyUrl,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      genres: genres ?? this.genres,
      followers: followers ?? this.followers,
      popularity: popularity ?? this.popularity,
      bio: bio ?? this.bio,
      shortDescription: shortDescription ?? this.shortDescription,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
    );
  }

  String get formattedFollowers {
    if (followers <= 0) return '0 FOLLOWERS';
    if (followers >= 1000000) {
      final millions = (followers / 1000000).toStringAsFixed(1);
      return '${millions.endsWith('.0') ? millions.substring(0, millions.length - 2) : millions}M FOLLOWERS';
    }
    if (followers >= 1000) {
      final thousands = (followers / 1000).toStringAsFixed(1);
      return '${thousands.endsWith('.0') ? thousands.substring(0, thousands.length - 2) : thousands}K FOLLOWERS';
    }
    return '$followers FOLLOWERS';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'genres': genres,
      'followers': followers,
      'popularity': popularity,
      'bio': bio,
      'shortDescription': shortDescription,
      'spotifyUrl': spotifyUrl,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      genres: (map['genres'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      popularity: (map['popularity'] as num?)?.toInt() ?? 0,
      bio: map['bio'] as String?,
      shortDescription: map['shortDescription'] as String?,
      spotifyUrl: map['spotifyUrl'] as String? ?? '',
    );
  }

  factory Artist.fromSpotifyJson(Map<String, dynamic> json) {
    String image = '';
    final images = json['images'] as List?;
    if (images != null && images.isNotEmpty) {
      for (final img in images) {
        if (img is Map && img['url'] != null && img['url'].toString().trim().isNotEmpty) {
          image = img['url'].toString().trim();
          break;
        }
      }
    }

    final followersMap = json['followers'] as Map<String, dynamic>?;
    final totalFollowers = (followersMap?['total'] as num?)?.toInt() ?? 0;

    final externalUrls = json['external_urls'] as Map<String, dynamic>?;
    final spotifyLink = externalUrls?['spotify'] as String? ?? '';

    final rawGenres = (json['genres'] as List?)
            ?.map((e) => e.toString().toUpperCase())
            .toList() ??
        const [];

    return Artist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: image,
      genres: rawGenres,
      followers: totalFollowers,
      popularity: (json['popularity'] as num?)?.toInt() ?? 0,
      spotifyUrl: spotifyLink,
    );
  }

  factory Artist.fromDeezerJson(Map<String, dynamic> json) {
    final image = json['picture_xl'] as String? ??
        json['picture_big'] as String? ??
        json['picture_medium'] as String? ??
        json['picture'] as String? ??
        '';

    return Artist(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      imageUrl: image,
      genres: const [],
      followers: (json['nb_fan'] as num?)?.toInt() ?? 0,
      popularity: 75,
      spotifyUrl: json['link'] as String? ?? '',
    );
  }
}
