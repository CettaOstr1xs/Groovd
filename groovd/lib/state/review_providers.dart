import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Reviews for specific Music Item
final itemReviewsProvider = FutureProvider.family<List<Review>, String>((ref, itemId) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewsForItem(itemId);
});

/// Average Rating for specific Music Item
final itemAverageScoreProvider = FutureProvider.family<double, String>((ref, itemId) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getAverageScore(itemId);
});

/// Review Count for specific Music Item
final itemReviewCountProvider = FutureProvider.family<int, String>((ref, itemId) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getReviewCount(itemId);
});

/// User's Reviews Provider
final userReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  ref.watch(reviewRefreshProvider);
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getUserReviews(userId);
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

  Future<void> updateUserIdentity(String userId, String newName, String newHandle) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.updateAuthorMetadata(userId, newName, newHandle);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }

  Future<void> migrateUserReviews({
    required String fromUserId,
    required String toUserId,
    required String newName,
    required String newHandle,
  }) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.migrateUserReviews(
      fromUserId: fromUserId,
      toUserId: toUserId,
      newName: newName,
      newHandle: newHandle,
    );
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }
}

final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController(ref);
});
