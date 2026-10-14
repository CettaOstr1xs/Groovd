import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/repositories/review_repository.dart';
import 'package:groovd/data/repositories/local_review_repository.dart';
import 'package:groovd/data/repositories/firestore_review_repository.dart';
import 'auth_providers.dart';
import 'user_profile_provider.dart';
import 'wishlist_provider.dart';

/// Active Review Repository Provider (auto-switches to Firestore when Firebase is initialized)
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirestoreReviewRepository();
    }
  } catch (_) {}
  return LocalReviewRepository();
});

/// Current User Info Computed Providers
final currentUserIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser != null) return authUser.uid;
  return ref.watch(userProfileProvider).userId;
});

final currentUserNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  if (profile.userName.isNotEmpty && profile.userName != 'CRITIC // YOU') {
    return profile.userName;
  }
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser?.displayName != null && authUser!.displayName!.isNotEmpty) {
    return authUser.displayName!.toUpperCase();
  }
  return profile.userName;
});

final currentUserHandleProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.userHandle;
});

/// State notifier to trigger refreshes when reviews are added/liked
class ReviewRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyChanged() => state++;
}

final reviewRefreshProvider = NotifierProvider<ReviewRefreshNotifier, int>(ReviewRefreshNotifier.new);

/// Recent Reviews Stream/Future
final recentReviewsProvider = FutureProvider<List<Review>>((ref) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getRecentReviews(limit: 30);
});

/// Resilient query descriptor for fetching item reviews across different catalog IDs.
class ItemReviewQuery {
  final String id;
  final String? name;
  final String? artist;
  final String? type;

  const ItemReviewQuery({
    required this.id,
    this.name,
    this.artist,
    this.type,
  });

  factory ItemReviewQuery.fromId(String id) => ItemReviewQuery(id: id);

  factory ItemReviewQuery.fromItem(MusicItem item) => ItemReviewQuery(
        id: item.id,
        name: item.name,
        artist: item.artist,
        type: item.type.name,
      );

  factory ItemReviewQuery.fromReview(Review review) => ItemReviewQuery(
        id: review.musicItemId,
        name: review.musicItemName,
        artist: review.artistName,
        type: review.itemType,
      );

  String get canonicalKey {
    if (name != null && name!.trim().isNotEmpty && artist != null && artist!.trim().isNotEmpty) {
      final normTitle = MusicItem.toLatinKey(name!);
      final normArtist = MusicItem.toLatinKey(artist!);
      final normType = (type?.toLowerCase() == 'song' || type?.toLowerCase() == 'track') ? 'song' : 'album';
      return '$normType::$normArtist::$normTitle';
    }
    return 'id::$id';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ItemReviewQuery) return false;
    return canonicalKey == other.canonicalKey;
  }

  @override
  int get hashCode => canonicalKey.hashCode;

  @override
  String toString() => 'ItemReviewQuery($canonicalKey, id: $id)';
}

/// Reviews for specific Music Item
final itemReviewsProvider = FutureProvider.family<List<Review>, ItemReviewQuery>((ref, query) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  final fetched = await repo.getReviewsForItem(
    query.id,
    itemName: query.name,
    artistName: query.artist,
    itemType: query.type,
  );

  // Cross-reference user's cached reviews to ensure locally/already logged reviews appear
  final currentUserId = ref.watch(currentUserIdProvider);
  final userReviews = ref.watch(userReviewsProvider(currentUserId)).asData?.value ?? const [];
  final guestReviews = currentUserId != 'user_me'
      ? (ref.watch(userReviewsProvider('user_me')).asData?.value ?? const [])
      : const <Review>[];
  final allPersonalReviews = [...userReviews, ...guestReviews];

  final personalMatches = allPersonalReviews.where((r) {
    if (r.musicItemId.isNotEmpty && r.musicItemId == query.id) return true;
    return r.matchesItem(
      id: query.id,
      name: query.name,
      artist: query.artist,
      type: query.type,
    );
  });

  final map = <String, Review>{};
  for (final r in fetched) {
    map[r.id] = r;
  }
  for (final r in personalMatches) {
    map[r.id] = r;
  }
  final merged = map.values.toList();
  merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
});

/// Average Rating for specific Music Item
final itemAverageScoreProvider = FutureProvider.family<double, ItemReviewQuery>((ref, query) async {
  final reviews = await ref.watch(itemReviewsProvider(query).future);
  if (reviews.isEmpty) return 0.0;
  final total = reviews.map((r) => r.rating).reduce((a, b) => a + b);
  return total / reviews.length;
});

/// Review Count for specific Music Item
final itemReviewCountProvider = FutureProvider.family<int, ItemReviewQuery>((ref, query) async {
  final reviews = await ref.watch(itemReviewsProvider(query).future);
  return reviews.length;
});

/// User's Reviews Provider
final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getUserReviews(userId);
});

/// Computed reactive mapping of item IDs and canonical keys to the count of reviews for a user.
final userLogCountsProvider = Provider.family<Map<String, int>, String>((ref, userId) {
  final userReviewsAsync = ref.watch(userReviewsProvider(userId));
  final reviews = userReviewsAsync.asData?.value ?? const [];

  final map = <String, int>{};
  for (final r in reviews) {
    if (r.musicItemId.isNotEmpty) {
      map[r.musicItemId] = (map[r.musicItemId] ?? 0) + 1;
    }
    final key = ItemReviewQuery(
      id: r.musicItemId,
      name: r.musicItemName,
      artist: r.artistName,
      type: r.itemType,
    ).canonicalKey;
    map[key] = (map[key] ?? 0) + 1;
  }
  return map;
});

/// Computed reactive mapping of item IDs and canonical keys to the count of reviews by current user.
final currentUserLogCountsProvider = Provider<Map<String, int>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  return ref.watch(userLogCountsProvider(currentUserId));
});

/// Number of times the current user has logged/reviewed a specific music item.
final currentUserItemLogCountProvider = Provider.family<int, ItemReviewQuery>((ref, query) {
  final map = ref.watch(currentUserLogCountsProvider);
  final countFromMap = map[query.canonicalKey] ?? map[query.id] ?? 0;

  final currentUserId = ref.watch(currentUserIdProvider);
  final userReviews = ref.watch(userReviewsProvider(currentUserId)).asData?.value ?? const [];
  final guestReviews = currentUserId != 'user_me'
      ? (ref.watch(userReviewsProvider('user_me')).asData?.value ?? const [])
      : const <Review>[];
  final countFromResilientMatch = [...userReviews, ...guestReviews].where((r) {
    if (r.musicItemId.isNotEmpty && r.musicItemId == query.id) return true;
    return r.matchesItem(
      id: query.id,
      name: query.name,
      artist: query.artist,
      type: query.type,
    );
  }).length;

  return countFromMap > countFromResilientMatch ? countFromMap : countFromResilientMatch;
});

/// Provider that returns the chronological 1-based log sequence index of a specific review
/// among all reviews of the same music release by that user.
///
/// For example:
/// - 1st log of Album X -> index 1 (no badge, as count <= 1)
/// - 2nd log of Album X -> index 2 ('2X' badge on this 2nd log container)
/// - 3rd log of Album X -> index 3 ('3X' badge on this 3rd log container)
final userReviewLogIndexProvider = Provider.family<int, ({String userId, Review review})>((ref, arg) {
  final userReviewsAsync = ref.watch(userReviewsProvider(arg.userId));
  final reviews = userReviewsAsync.asData?.value ?? const [];

  final targetKey = ItemReviewQuery.fromReview(arg.review).canonicalKey;

  // Filter reviews matching the same music item
  final matchingReviews = reviews.where((r) {
    if (r.musicItemId.isNotEmpty && r.musicItemId == arg.review.musicItemId) {
      return true;
    }
    return ItemReviewQuery.fromReview(r).canonicalKey == targetKey;
  }).toList();

  // Sort chronologically ascending (earliest review first)
  matchingReviews.sort((a, b) {
    final cmp = a.createdAt.compareTo(b.createdAt);
    if (cmp != 0) return cmp;
    return a.id.compareTo(b.id);
  });

  final idx = matchingReviews.indexWhere((r) => r.id == arg.review.id);
  return idx >= 0 ? idx + 1 : 1;
});

/// Convenience provider for current user's review log index.
final currentUserReviewLogIndexProvider = Provider.family<int, Review>((ref, review) {
  final currentUserId = ref.watch(currentUserIdProvider);
  return ref.watch(userReviewLogIndexProvider((userId: currentUserId, review: review)));
});

/// Calculates the automatic overall score for an album or EP based on the current user's
/// ratings of all individual tracks on the release.
///
/// Returns null if:
/// - The item is not an album or EP (`!item.isRelease`)
/// - The release has no tracks (`item.tracks.isEmpty`)
/// - NOT ALL tracks have been rated/reviewed by the user
///
/// When ALL tracks have been rated, returns the mathematical average of the user's
/// track ratings rounded to 1 decimal place (0.0 to 10.0).
final albumAutomaticOverallScoreProvider = Provider.family<double?, MusicItem>((ref, item) {
  if (!item.isRelease || item.tracks.isEmpty) {
    return null;
  }

  final currentUserId = ref.watch(currentUserIdProvider);
  final userReviewsAsync = ref.watch(userReviewsProvider(currentUserId));
  final reviews = userReviewsAsync.asData?.value ?? const [];
  final guestReviews = currentUserId != 'user_me'
      ? (ref.watch(userReviewsProvider('user_me')).asData?.value ?? const [])
      : const <Review>[];
  final allReviews = [...reviews, ...guestReviews];

  final List<double> trackRatings = [];

  for (final track in item.tracks) {
    final trackArtist = track.artist.isNotEmpty ? track.artist : item.artist;

    Review? matchedReview;
    for (final r in allReviews) {
      if (track.id.isNotEmpty && r.musicItemId.isNotEmpty && r.musicItemId == track.id) {
        matchedReview = r;
        break;
      }
      final rType = r.itemType.toLowerCase();
      if (rType == 'song' || rType == 'track') {
        if (r.matchesItem(
          id: track.id,
          name: track.name,
          artist: trackArtist,
          type: 'song',
        )) {
          matchedReview = r;
          break;
        }
      }
    }

    if (matchedReview == null) {
      // At least one track on the album/ep has not been rated
      return null;
    }

    trackRatings.add(matchedReview.rating);
  }

  if (trackRatings.isEmpty) return null;
  final avg = trackRatings.reduce((a, b) => a + b) / trackRatings.length;
  return (avg * 10).round() / 10.0;
});

/// Provider to look up the current user's rating for a specific track, if rated.
final trackUserRatingProvider = Provider.family<double?, ({TrackInfo track, String albumArtist})>((ref, arg) {
  final currentUserId = ref.watch(currentUserIdProvider);
  final userReviewsAsync = ref.watch(userReviewsProvider(currentUserId));
  final reviews = userReviewsAsync.asData?.value ?? const [];
  final guestReviews = currentUserId != 'user_me'
      ? (ref.watch(userReviewsProvider('user_me')).asData?.value ?? const [])
      : const <Review>[];
  final allReviews = [...reviews, ...guestReviews];

  final trackArtist = arg.track.artist.isNotEmpty ? arg.track.artist : arg.albumArtist;

  for (final r in allReviews) {
    if (arg.track.id.isNotEmpty && r.musicItemId.isNotEmpty && r.musicItemId == arg.track.id) {
      return r.rating;
    }
    final rType = r.itemType.toLowerCase();
    if (rType == 'song' || rType == 'track') {
      if (r.matchesItem(
        id: arg.track.id,
        name: arg.track.name,
        artist: trackArtist,
        type: 'song',
      )) {
        return r.rating;
      }
    }
  }
  return null;
});

/// Review Action Controller
class ReviewController {
  final Ref ref;

  ReviewController(this.ref);

  Future<void> submitReview(Review review) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.addReview(review);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();

    // Automatically remove rated/reviewed release from wantlist/wishlist
    await ref.read(wishlistProvider.notifier).removeItemByReview(review);
  }

  Future<void> likeReview(String reviewId) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.likeReview(reviewId);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }

  Future<void> deleteReview(String reviewId) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.deleteReview(reviewId);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }

  Future<void> updateUserIdentity(String userId, String newName, String newHandle, [String? newAvatarUrl]) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.updateAuthorMetadata(userId, newName, newHandle, newAvatarUrl);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }

  Future<void> migrateUserReviews({
    required String fromUserId,
    required String toUserId,
    required String newName,
    required String newHandle,
    String? newAvatarUrl,
  }) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.migrateUserReviews(
      fromUserId: fromUserId,
      toUserId: toUserId,
      newName: newName,
      newHandle: newHandle,
      newAvatarUrl: newAvatarUrl,
    );
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }
}

final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController(ref);
});
