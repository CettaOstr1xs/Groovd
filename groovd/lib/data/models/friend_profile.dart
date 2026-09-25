import 'dart:convert';
import 'music_item.dart';

/// Represents another critic or friend in the Groovd community.
class FriendProfile {
  final String userId;
  final String userName;
  final String userHandle;
  final String? avatarPath;
  final String? backdropPath;
  final String bio;
  final int reviewsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final List<MusicItem> topAlbums;
  final List<MusicItem> topSongs;
  final int wantlistCount;
  final int listsCount;
  final DateTime? joinedAt;

  const FriendProfile({
    required this.userId,
    required this.userName,
    required this.userHandle,
    this.avatarPath,
    this.backdropPath,
    this.bio = '',
    this.reviewsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.wantlistCount = 0,
    this.listsCount = 0,
    this.isFollowing = false,
    this.topAlbums = const [],
    this.topSongs = const [],
    this.joinedAt,
  });

  String get formattedHandle =>
      userHandle.startsWith('@') ? userHandle : '@$userHandle';

  String get formattedFollowers {
    if (followersCount >= 1000000) {
      final millions = (followersCount / 1000000).toStringAsFixed(1);
      return '${millions.endsWith('.0') ? millions.substring(0, millions.length - 2) : millions}M';
    }
    if (followersCount >= 1000) {
      final thousands = (followersCount / 1000).toStringAsFixed(1);
      return '${thousands.endsWith('.0') ? thousands.substring(0, thousands.length - 2) : thousands}K';
    }
    return '$followersCount';
  }

  FriendProfile copyWith({
    String? userId,
    String? userName,
    String? userHandle,
    String? avatarPath,
    String? backdropPath,
    String? bio,
    int? reviewsCount,
    int? followersCount,
    int? followingCount,
    int? wantlistCount,
    int? listsCount,
    bool? isFollowing,
    List<MusicItem>? topAlbums,
    List<MusicItem>? topSongs,
    DateTime? joinedAt,
  }) {
    return FriendProfile(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userHandle: userHandle ?? this.userHandle,
      avatarPath: avatarPath ?? this.avatarPath,
      backdropPath: backdropPath ?? this.backdropPath,
      bio: bio ?? this.bio,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      wantlistCount: wantlistCount ?? this.wantlistCount,
      listsCount: listsCount ?? this.listsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      topAlbums: topAlbums ?? this.topAlbums,
      topSongs: topSongs ?? this.topSongs,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userHandle': userHandle,
      'avatarPath': avatarPath,
      'backdropPath': backdropPath,
      'bio': bio,
      'reviewsCount': reviewsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'wantlistCount': wantlistCount,
      'listsCount': listsCount,
      'isFollowing': isFollowing,
      'topAlbums': topAlbums.map((a) => a.toMap()).toList(),
      'topSongs': topSongs.map((s) => s.toMap()).toList(),
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }

  factory FriendProfile.fromMap(Map<String, dynamic> map) {
    return FriendProfile(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'CRITIC',
      userHandle: map['userHandle'] as String? ?? '@critic',
      avatarPath: map['avatarPath'] as String?,
      backdropPath: map['backdropPath'] as String?,
      bio: map['bio'] as String? ?? '',
      reviewsCount: (map['reviewsCount'] as num?)?.toInt() ?? 0,
      followersCount: (map['followersCount'] as num?)?.toInt() ?? 0,
      followingCount: (map['followingCount'] as num?)?.toInt() ?? 0,
      wantlistCount: (map['wantlistCount'] as num?)?.toInt() ?? 0,
      listsCount: (map['listsCount'] as num?)?.toInt() ?? 0,
      isFollowing: map['isFollowing'] as bool? ?? false,
      topAlbums: (map['topAlbums'] as List?)
              ?.whereType<Map>()
              .map((m) => MusicItem.fromMap(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      topSongs: (map['topSongs'] as List?)
              ?.whereType<Map>()
              .map((m) => MusicItem.fromMap(Map<String, dynamic>.from(m)))
              .toList() ??
          const [],
      joinedAt: map['joinedAt'] != null
          ? DateTime.tryParse(map['joinedAt'].toString())
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory FriendProfile.fromJson(String source) =>
      FriendProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
