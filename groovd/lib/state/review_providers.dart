import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/repositories/review_repository.dart';
import 'package:groovd/data/repositories/local_review_repository.dart';
import 'package:groovd/data/repositories/firestore_review_repository.dart';

/// Active Review Repository Provider (auto-switches to Firestore when Firebase is initialized)
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  try {
    if (Firebase.apps.isNotEmpty) {
      return FirestoreReviewRepository();
    }
  } catch (_) {}
  return LocalReviewRepository();
});

/// Current User Info Notifiers
class CurrentUserIdNotifier extends Notifier<String> {
  @override
  String build() => 'user_me';
  void set(String id) => state = id;
}
final currentUserIdProvider = NotifierProvider<CurrentUserIdNotifier, String>(CurrentUserIdNotifier.new);

class CurrentUserNameNotifier extends Notifier<String> {
  @override
  String build() => 'CRITIC // YOU';
  void set(String name) => state = name;
}
final currentUserNameProvider = NotifierProvider<CurrentUserNameNotifier, String>(CurrentUserNameNotifier.new);

class CurrentUserHandleNotifier extends Notifier<String> {
  @override
  String build() => '@groovd_me';
  void set(String handle) => state = handle;
}
final currentUserHandleProvider = NotifierProvider<CurrentUserHandleNotifier, String>(CurrentUserHandleNotifier.new);

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
  }

  Future<void> likeReview(String reviewId) async {
    final repo = ref.read(reviewRepositoryProvider);
    await repo.likeReview(reviewId);
    ref.read(reviewRefreshProvider.notifier).notifyChanged();
  }
}

final reviewControllerProvider = Provider<ReviewController>((ref) {
  return ReviewController(ref);
});
