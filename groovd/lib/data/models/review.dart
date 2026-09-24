class Review {
  final String id;
  final String musicItemId;
  final String musicItemName;
  final String artistName;
  final String coverUrl;
  final String itemType; // 'album' or 'song'
  final String userId;
  final String userName;
  final String userHandle;
  final String? userAvatarUrl;
  final double rating; // 1.0 to 10.0
  final String headline;
  final String body;
  final List<String> tags;
  final DateTime createdAt;
  final int likesCount;

  const Review({
    required this.id,
    required this.musicItemId,
    required this.musicItemName,
    required this.artistName,
    required this.coverUrl,
    required this.itemType,
    required this.userId,
    required this.userName,
    required this.userHandle,
    this.userAvatarUrl,
    required this.rating,
    required this.headline,
    required this.body,
    this.tags = const [],
    required this.createdAt,
    this.likesCount = 0,
  });

  String get scoreFormatted => rating.toStringAsFixed(1);

  String get scoreTierLabel {
    if (rating >= 9.5) return 'MASTERPIECE';
    if (rating >= 8.5) return 'CRITIC\'S ESSENTIAL';
    if (rating >= 7.5) return 'ACCLAIMED';
    if (rating >= 6.0) return 'SOLID LISTEN';
    if (rating >= 4.5) return 'DIVISIVE';
    return 'CRITICAL SKIP';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 30) {
      return '${diff.inDays ~/ 30}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Whether this entry has written commentary (headline or body text).
  bool get hasWrittenReview => headline.trim().isNotEmpty || body.trim().isNotEmpty;

  /// Whether this entry is a score-only rating without written commentary.
  bool get isQuickRating => !hasWrittenReview;

  Review copyWith({
    String? id,
    String? musicItemId,
    String? musicItemName,
    String? artistName,
    String? coverUrl,
    String? itemType,
    String? userId,
    String? userName,
    String? userHandle,
    String? userAvatarUrl,
    bool clearAvatar = false,
    double? rating,
    String? headline,
    String? body,
    List<String>? tags,
    DateTime? createdAt,
    int? likesCount,
  }) {
    return Review(
      id: id ?? this.id,
      musicItemId: musicItemId ?? this.musicItemId,
      musicItemName: musicItemName ?? this.musicItemName,
      artistName: artistName ?? this.artistName,
      coverUrl: coverUrl ?? this.coverUrl,
      itemType: itemType ?? this.itemType,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      userAvatarUrl: clearAvatar ? null : (userAvatarUrl ?? this.userAvatarUrl),
      rating: rating ?? this.rating,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'musicItemId': musicItemId,
      'musicItemName': musicItemName,
      'artistName': artistName,
      'coverUrl': coverUrl,
      'itemType': itemType,
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'userAvatarUrl': userAvatarUrl,
      'rating': rating,
      'headline': headline,
      'body': body,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      musicItemId: map['musicItemId'] as String? ?? '',
      musicItemName: map['musicItemName'] as String? ?? '',
      artistName: map['artistName'] as String? ?? '',
      coverUrl: map['coverUrl'] as String? ?? '',
      itemType: map['itemType'] as String? ?? 'album',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'ANONYMOUS CRITIC',
      userHandle: map['userHandle'] as String? ?? '@groover',
      userAvatarUrl: map['userAvatarUrl'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      headline: map['headline'] as String? ?? '',
      body: map['body'] as String? ?? '',
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
