import '../models/review.dart';

abstract class ReviewRepository {
  Future<List<Review>> getReviewsForItem(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  });
  Future<List<Review>> getRecentReviews({int limit = 20});
  Future<List<Review>> getUserReviews(String userId);
  Future<void> addReview(Review review);
  Future<void> likeReview(String reviewId);
  Future<double> getAverageScore(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  });
  Future<int> getReviewCount(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  });
  Future<void> updateAuthorMetadata(String userId, String newName, String newHandle, [String? newAvatarUrl]);
  Future<void> deleteReview(String reviewId);
  Future<void> migrateUserReviews({
    required String fromUserId,
    required String toUserId,
    required String newName,
    required String newHandle,
    String? newAvatarUrl,
  });
}
