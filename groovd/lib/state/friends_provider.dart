import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/friend_profile.dart';
import '../data/models/review.dart';
import '../data/repositories/friends_repository.dart';
import 'auth_providers.dart';
import 'review_providers.dart';
import 'user_profile_provider.dart';

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) {
  return FriendsRepository();
});

/// Manages the list of critics the current user is following.
class FollowingListNotifier extends AsyncNotifier<List<FriendProfile>> {
  String get _currentUserId {
    final authUser = ref.read(authStateProvider).asData?.value;
    if (authUser != null) return authUser.uid;
    try {
      if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
        return FirebaseAuth.instance.currentUser!.uid;
      }
    } catch (_) {}
    final profileUid = ref.read(userProfileProvider).userId;
    if (profileUid.isNotEmpty) return profileUid;
    return 'user_me';
  }

  @override
  Future<List<FriendProfile>> build() async {
    final repo = ref.watch(friendsRepositoryProvider);
    final uid = _currentUserId;

    // Listen for auth state changes to reload following list
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final prevUser = previous?.asData?.value;
      final nextUser = next.asData?.value;
      if (prevUser?.uid != nextUser?.uid) {
        ref.invalidateSelf();
      }
    });

    return repo.getFollowing(uid);
  }

  Future<void> followCritic(FriendProfile critic) async {
    final repo = ref.read(friendsRepositoryProvider);
    final uid = _currentUserId;
    final currentList = state.value ?? [];

    // Optimistically update immediately for snappy 0ms UI response
    final updatedCritic = critic.copyWith(
      isFollowing: true,
      followersCount: critic.followersCount + 1,
    );
    final optimisticList = [
      updatedCritic,
      ...currentList.where((c) => c.userId != critic.userId),
    ];
    state = AsyncValue.data(optimisticList);

    try {
      final updated = await repo.followCritic(uid, critic);
      state = AsyncValue.data(updated);
      ref.invalidate(friendsFeedProvider);
      ref.invalidate(suggestedCriticsProvider);
      ref.invalidate(friendProfileProvider(critic.userId));
      ref.invalidate(userFollowersCountProvider(critic.userId));
      ref.invalidate(currentUserFollowerIdsProvider);
    } catch (_) {
      // Revert on failure
      state = AsyncValue.data(currentList);
    }
  }

  Future<void> unfollowCritic(String friendId) async {
    final repo = ref.read(friendsRepositoryProvider);
    final uid = _currentUserId;
    final currentList = state.value ?? [];

    // Optimistically update immediately
    final optimisticList = currentList.where((c) => c.userId != friendId).toList();
    state = AsyncValue.data(optimisticList);

    try {
      final updated = await repo.unfollowCritic(uid, friendId);
      state = AsyncValue.data(updated);
      ref.invalidate(friendsFeedProvider);
      ref.invalidate(suggestedCriticsProvider);
      ref.invalidate(friendProfileProvider(friendId));
      ref.invalidate(userFollowersCountProvider(friendId));
      ref.invalidate(currentUserFollowerIdsProvider);
    } catch (_) {
      // Revert on failure
      state = AsyncValue.data(currentList);
    }
  }

  Future<void> toggleFollow(FriendProfile critic) async {
    final currentList = state.value ?? [];
    final isFollowing = currentList.any((c) => c.userId == critic.userId);
    if (isFollowing) {
      await unfollowCritic(critic.userId);
    } else {
      await followCritic(critic);
    }
  }
}

final followingListProvider =
    AsyncNotifierProvider<FollowingListNotifier, List<FriendProfile>>(
  FollowingListNotifier.new,
);

/// Provider checking whether a specific critic is followed by current user.
final isFollowingProvider = Provider.family<bool, String>((ref, friendId) {
  final followingAsync = ref.watch(followingListProvider);
  return followingAsync.maybeWhen(
    data: (list) => list.any((f) => f.userId == friendId),
    orElse: () => false,
  );
});

/// Real-time stream of follower IDs for the currently active user.
final currentUserFollowerIdsProvider = StreamProvider<Set<String>>((ref) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (Firebase.apps.isEmpty || currentUserId.isEmpty || currentUserId == 'user_me') {
    return Stream.value(<String>{});
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('followers')
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet())
      .handleError((_) => <String>{});
});

/// Provider checking whether a specific critic already follows the current user.
final isFollowerOfCurrentUserProvider = Provider.family<bool, String>((ref, friendId) {
  final followersAsync = ref.watch(currentUserFollowerIdsProvider);
  final followers = followersAsync.value ?? <String>{};
  return followers.contains(friendId);
});

/// Social activity feed of all reviews from followed friends.
final friendsFeedProvider = FutureProvider<List<Review>>((ref) async {
  final followingAsync = ref.watch(followingListProvider);
  final following = followingAsync.value ?? [];
  final followedIds = following.map((f) => f.userId).toList();

  final repo = ref.watch(friendsRepositoryProvider);
  return repo.getFriendsFeed(followedIds);
});

/// Critic search query notifier
class CriticSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String val) => state = val;
  void clear() => state = '';
}

final criticSearchQueryProvider =
    NotifierProvider<CriticSearchQueryNotifier, String>(
  CriticSearchQueryNotifier.new,
);

/// Real-time search results for critics
final searchedCriticsProvider = FutureProvider<List<FriendProfile>>((ref) async {
  final query = ref.watch(criticSearchQueryProvider);
  if (query.trim().isEmpty) return [];

  final repo = ref.watch(friendsRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  return repo.searchCritics(query, currentUserId: currentUserId);
});

/// Suggested critics to follow
final suggestedCriticsProvider = FutureProvider<List<FriendProfile>>((ref) async {
  final repo = ref.watch(friendsRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return repo.getSuggestedCritics(currentUserId);
});

/// Detailed Critic Dossier for a specific friend
final friendProfileProvider =
    FutureProvider.family<FriendProfile?, String>((ref, friendId) async {
  final repo = ref.watch(friendsRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return repo.getFriendProfile(friendId, currentUserId: currentUserId);
});

/// Reviews written by a specific friend (real data only)
final friendReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, friendId) async {
  ref.watch(reviewRefreshProvider);

  final repo = ref.watch(reviewRepositoryProvider);
  final userReviews = await repo.getUserReviews(friendId);

  // Filter out any mock/seed reviews
  final list = userReviews.where((r) => !r.id.startsWith('seed_')).toList();
  list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return list;
});

/// Real-time stream of follower count for any user from Cloud Firestore
final userFollowersCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  if (Firebase.apps.isEmpty || userId.isEmpty || userId == 'user_me') {
    return Stream.value(0);
  }
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('followers')
      .snapshots()
      .map((snap) => snap.docs.length)
      .handleError((_) => 0);
});
