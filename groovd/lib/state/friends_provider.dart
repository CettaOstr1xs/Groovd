import 'package:firebase_auth/firebase_auth.dart';
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
    return ref.read(userProfileProvider).userId;
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await repo.followCritic(uid, critic);
      ref.invalidate(friendsFeedProvider);
      ref.invalidate(suggestedCriticsProvider);
      return updated;
    });
  }

  Future<void> unfollowCritic(String friendId) async {
    final repo = ref.read(friendsRepositoryProvider);
    final uid = _currentUserId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updated = await repo.unfollowCritic(uid, friendId);
      ref.invalidate(friendsFeedProvider);
      ref.invalidate(suggestedCriticsProvider);
      return updated;
    });
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
