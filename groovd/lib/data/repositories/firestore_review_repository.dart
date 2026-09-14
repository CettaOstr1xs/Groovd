import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:groovd/data/models/review.dart';
import 'review_repository.dart';

/// Cloud Firestore implementation of [ReviewRepository].
class FirestoreReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore;
  static const String collectionPath = 'reviews';

  FirestoreReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Review>> getReviewsForItem(String musicItemId) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where('musicItemId', isEqualTo: musicItemId)
        .get();
    final list = snapshot.docs.map((d) => Review.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Review>> getRecentReviews({int limit = 20}) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .limit(limit)
        .get();
    final list = snapshot.docs.map((d) => Review.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Review>> getUserReviews(String userId) async {
    final snapshot = await _firestore
        .collection(collectionPath)
        .where('userId', isEqualTo: userId)
        .get();
    final list = snapshot.docs.map((d) => Review.fromMap(d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addReview(Review review) async {
    await _firestore
        .collection(collectionPath)
        .doc(review.id)
        .set(review.toMap());
  }

  @override
  Future<void> likeReview(String reviewId) async {
    await _firestore
        .collection(collectionPath)
        .doc(reviewId)
        .update({'likesCount': FieldValue.increment(1)});
  }

  @override
  Future<double> getAverageScore(String musicItemId) async {
    final reviews = await getReviewsForItem(musicItemId);
    if (reviews.isEmpty) return 0.0;
    return reviews.fold<double>(0.0, (acc, r) => acc + r.rating) / reviews.length;
  }

  @override
  Future<int> getReviewCount(String musicItemId) async {
    final reviews = await getReviewsForItem(musicItemId);
    return reviews.length;
  }
}
