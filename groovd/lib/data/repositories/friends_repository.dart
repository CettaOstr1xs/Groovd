import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend_profile.dart';
import '../models/music_item.dart';
import '../models/review.dart';
import 'local_review_repository.dart';

class FriendsRepository {
  final FirebaseFirestore? _customFirestore;
  final LocalReviewRepository _localReviewRepo = LocalReviewRepository();
  static const String _followingPrefKey = 'groovd_following_critics_v2';

  FriendsRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get _firestore =>
      _customFirestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Retrieves the list of real critics the user is following.
  Future<List<FriendProfile>> getFollowing(String currentUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('${_followingPrefKey}_$currentUserId') ??
        prefs.getStringList(_followingPrefKey);

    List<FriendProfile> following = [];
    if (rawList != null && rawList.isNotEmpty) {
      for (final s in rawList) {
        try {
          following.add(FriendProfile.fromJson(s));
        } catch (_) {}
      }
    }

    // Synchronize with Cloud Firestore
    final firestore = _firestore;
    if (firestore != null && currentUserId.isNotEmpty && currentUserId != 'user_me') {
      try {
        final snap = await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .get()
            .timeout(const Duration(milliseconds: 2500));

        if (snap.docs.isNotEmpty) {
          final cloudIds = snap.docs.map((d) => d.id).toSet();
          final map = {for (final f in following) f.userId: f};

          for (final doc in snap.docs) {
            final data = doc.data();
            final uid = doc.id;
            if (!map.containsKey(uid)) {
              map[uid] = FriendProfile(
                userId: uid,
                userName: data['userName'] as String? ?? 'CRITIC',
                userHandle: data['userHandle'] as String? ?? '@critic',
                avatarPath: data['avatarPath'] as String?,
                bio: data['bio'] as String? ?? '',
                isFollowing: true,
              );
            }
          }
          following = map.values.where((f) => cloudIds.contains(f.userId)).toList();
          await _persistFollowing(currentUserId, following);
        }
      } catch (_) {}
    }

    return following;
  }

  /// Follow a real critic and persist to local storage and Cloud Firestore.
  Future<List<FriendProfile>> followCritic(String currentUserId, FriendProfile critic) async {
    final following = await getFollowing(currentUserId);
    final index = following.indexWhere((c) => c.userId == critic.userId);
    final updatedCritic = critic.copyWith(
      isFollowing: true,
      followersCount: critic.followersCount + 1,
    );

    if (index >= 0) {
      following[index] = updatedCritic;
    } else {
      following.insert(0, updatedCritic);
    }

    await _persistFollowing(currentUserId, following);

    // Sync to Cloud Firestore
    final firestore = _firestore;
    if (firestore != null && currentUserId.isNotEmpty && currentUserId != 'user_me') {
      try {
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(critic.userId)
            .set({
          'userId': critic.userId,
          'userName': critic.userName,
          'userHandle': critic.userHandle,
          'avatarPath': critic.avatarPath,
          'followedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await firestore
            .collection('users')
            .doc(critic.userId)
            .collection('followers')
            .doc(currentUserId)
            .set({
          'userId': currentUserId,
          'followedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return following;
  }

  /// Unfollow a critic and persist changes.
  Future<List<FriendProfile>> unfollowCritic(String currentUserId, String friendId) async {
    final following = await getFollowing(currentUserId);
    following.removeWhere((c) => c.userId == friendId);

    await _persistFollowing(currentUserId, following);

    // Sync removal to Cloud Firestore
    final firestore = _firestore;
    if (firestore != null && currentUserId.isNotEmpty && currentUserId != 'user_me') {
      try {
        await firestore
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(friendId)
            .delete();

        await firestore
            .collection('users')
            .doc(friendId)
            .collection('followers')
            .doc(currentUserId)
            .delete();
      } catch (_) {}
    }

    return following;
  }

  /// Search real critics from Cloud Firestore users collection.
  Future<List<FriendProfile>> searchCritics(String query, {required String currentUserId}) async {
    final clean = query.trim().toLowerCase().replaceAll('@', '');
    if (clean.isEmpty) return [];

    final following = await getFollowing(currentUserId);
    final followingIds = following.map((f) => f.userId).toSet();
    final results = <FriendProfile>[];
    final seenIds = <String>{};

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final querySnap = await firestore
            .collection('users')
            .limit(30)
            .get()
            .timeout(const Duration(milliseconds: 3000));

        for (final doc in querySnap.docs) {
          final uid = doc.id;
          if (uid == currentUserId || seenIds.contains(uid)) continue;

          final data = doc.data();
          final name = data['userName'] as String? ?? '';
          final handle = data['userHandle'] as String? ?? '';
          final bio = data['bio'] as String? ?? '';

          if (name.toLowerCase().contains(clean) ||
              handle.toLowerCase().replaceAll('@', '').contains(clean) ||
              bio.toLowerCase().contains(clean)) {
            results.add(FriendProfile(
              userId: uid,
              userName: name.isNotEmpty ? name : 'CRITIC',
              userHandle: handle.isNotEmpty ? handle : '@critic',
              avatarPath: data['avatarPath'] as String?,
              backdropPath: data['backdropPath'] as String?,
              bio: bio,
              isFollowing: followingIds.contains(uid),
            ));
            seenIds.add(uid);
          }
        }
      } catch (_) {}
    }

    // Also search offline cached following
    for (final f in following) {
      if (!seenIds.contains(f.userId) && f.userId != currentUserId) {
        if (f.userName.toLowerCase().contains(clean) ||
            f.userHandle.toLowerCase().replaceAll('@', '').contains(clean) ||
            f.bio.toLowerCase().contains(clean)) {
          results.add(f.copyWith(isFollowing: true));
          seenIds.add(f.userId);
        }
      }
    }

    return results;
  }

  /// Retrieve real suggested critics from Cloud Firestore users collection.
  Future<List<FriendProfile>> getSuggestedCritics(String currentUserId) async {
    final following = await getFollowing(currentUserId);
    final followingIds = following.map((f) => f.userId).toSet();
    final suggestions = <FriendProfile>[];
    final seenIds = <String>{...followingIds, currentUserId};

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final snap = await firestore
            .collection('users')
            .limit(20)
            .get()
            .timeout(const Duration(milliseconds: 3000));

        for (final doc in snap.docs) {
          final uid = doc.id;
          if (seenIds.contains(uid)) continue;

          final data = doc.data();
          final name = data['userName'] as String? ?? '';
          final handle = data['userHandle'] as String? ?? '';

          // Only suggest users who have a name or handle configured
          if (name.isNotEmpty || handle.isNotEmpty) {
            suggestions.add(FriendProfile(
              userId: uid,
              userName: name.isNotEmpty ? name : 'CRITIC',
              userHandle: handle.isNotEmpty ? handle : '@critic',
              avatarPath: data['avatarPath'] as String?,
              backdropPath: data['backdropPath'] as String?,
              bio: data['bio'] as String? ?? '',
              isFollowing: false,
            ));
            seenIds.add(uid);
          }
        }
      } catch (_) {}
    }

    return suggestions;
  }

  /// Retrieves the social activity feed of real reviews logged by followed friends.
  Future<List<Review>> getFriendsFeed(List<String> followedUserIds) async {
    if (followedUserIds.isEmpty) return [];

    final feedReviews = <Review>[];
    final seenReviewIds = <String>{};

    // 1. Fetch live real reviews from Cloud Firestore
    final firestore = _firestore;
    if (firestore != null) {
      try {
        // Firestore whereIn supports up to 30 items
        final targetIds = followedUserIds.take(30).toList();
        final snap = await firestore
            .collection('reviews')
            .where('userId', whereIn: targetIds)
            .get()
            .timeout(const Duration(milliseconds: 3000));

        for (final doc in snap.docs) {
          if (!doc.id.startsWith('seed_') && seenReviewIds.add(doc.id)) {
            try {
              feedReviews.add(Review.fromMap(doc.data()));
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    // 2. Fetch locally stored reviews from followed users (excluding seed reviews)
    try {
      final localReviews = await _localReviewRepo.getRecentReviews(limit: 50);
      for (final r in localReviews) {
        if (!r.id.startsWith('seed_') &&
            followedUserIds.contains(r.userId) &&
            seenReviewIds.add(r.id)) {
          feedReviews.add(r);
        }
      }
    } catch (_) {}

    // Sort newest first
    feedReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return feedReviews;
  }

  /// Get the comprehensive real Critic Dossier for a specific friend.
  Future<FriendProfile?> getFriendProfile(String friendId, {required String currentUserId}) async {
    final following = await getFollowing(currentUserId);
    final isFollowing = following.any((c) => c.userId == friendId);

    final firestore = _firestore;
    if (firestore != null) {
      try {
        final userDoc = await firestore
            .collection('users')
            .doc(friendId)
            .get()
            .timeout(const Duration(milliseconds: 3000));

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;

          // Fetch their top picks if available in users/{friendId}/dossier/top_picks
          List<MusicItem> topAlbums = [];
          List<MusicItem> topSongs = [];
          try {
            final topPicksDoc = await firestore
                .collection('users')
                .doc(friendId)
                .collection('dossier')
                .doc('top_picks')
                .get()
                .timeout(const Duration(milliseconds: 2500));

            if (topPicksDoc.exists && topPicksDoc.data() != null) {
              final rawAlbums = topPicksDoc.data()!['topAlbums'] as List?;
              if (rawAlbums != null) {
                for (final item in rawAlbums) {
                  if (item is Map) {
                    try {
                      topAlbums.add(MusicItem.fromMap(Map<String, dynamic>.from(item)));
                    } catch (_) {}
                  }
                }
              }
              final rawSongs = topPicksDoc.data()!['topSongs'] as List?;
              if (rawSongs != null) {
                for (final item in rawSongs) {
                  if (item is Map) {
                    try {
                      topSongs.add(MusicItem.fromMap(Map<String, dynamic>.from(item)));
                    } catch (_) {}
                  }
                }
              }
            }
          } catch (_) {}

          // Count their real reviews in reviews collection
          int reviewsCount = 0;
          try {
            final countSnap = await firestore
                .collection('reviews')
                .where('userId', isEqualTo: friendId)
                .count()
                .get()
                .timeout(const Duration(milliseconds: 2000));
            reviewsCount = countSnap.count ?? 0;
          } catch (_) {}

          // Count their followers in users/{friendId}/followers
          int followersCount = 0;
          try {
            final followersSnap = await firestore
                .collection('users')
                .doc(friendId)
                .collection('followers')
                .count()
                .get()
                .timeout(const Duration(milliseconds: 2000));
            followersCount = followersSnap.count ?? 0;
          } catch (_) {}

          // Count their following in users/{friendId}/following
          int followingCount = 0;
          try {
            final followingSnap = await firestore
                .collection('users')
                .doc(friendId)
                .collection('following')
                .count()
                .get()
                .timeout(const Duration(milliseconds: 2000));
            followingCount = followingSnap.count ?? 0;
          } catch (_) {}

          // Count their wantlist in users/{friendId}/wishlist
          int wantlistCount = 0;
          try {
            final wantlistSnap = await firestore
                .collection('users')
                .doc(friendId)
                .collection('wishlist')
                .count()
                .get()
                .timeout(const Duration(milliseconds: 2000));
            wantlistCount = wantlistSnap.count ?? 0;
          } catch (_) {}

          // Count their lists in users/{friendId}/lists
          int listsCount = 0;
          try {
            final listsSnap = await firestore
                .collection('users')
                .doc(friendId)
                .collection('lists')
                .count()
                .get()
                .timeout(const Duration(milliseconds: 2000));
            listsCount = listsSnap.count ?? 0;
          } catch (_) {}

          DateTime? joinedAt;
          if (data['createdAt'] is Timestamp) {
            joinedAt = (data['createdAt'] as Timestamp).toDate();
          }

          return FriendProfile(
            userId: friendId,
            userName: data['userName'] as String? ?? 'CRITIC',
            userHandle: data['userHandle'] as String? ?? '@critic',
            avatarPath: data['avatarPath'] as String?,
            backdropPath: data['backdropPath'] as String?,
            bio: data['bio'] as String? ?? '',
            reviewsCount: reviewsCount,
            followersCount: followersCount,
            followingCount: followingCount,
            wantlistCount: wantlistCount,
            listsCount: listsCount,
            isFollowing: isFollowing,
            topAlbums: topAlbums,
            topSongs: topSongs,
            joinedAt: joinedAt,
          );
        }
      } catch (_) {}
    }

    // Fallback to local following list if cached
    final localMatch = following.where((c) => c.userId == friendId).firstOrNull;
    if (localMatch != null) {
      return localMatch.copyWith(isFollowing: true);
    }

    return null;
  }

  Future<void> _persistFollowing(String currentUserId, List<FriendProfile> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final strList = list.map((c) => c.toJson()).toList();
      await prefs.setStringList('${_followingPrefKey}_$currentUserId', strList);
      await prefs.setStringList(_followingPrefKey, strList);
    } catch (_) {}
  }
}
