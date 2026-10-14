import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:groovd/data/models/review.dart';
import 'local_review_repository.dart';
import 'review_repository.dart';

/// Cloud Firestore implementation of [ReviewRepository] with local SharedPreferences fallback.
class FirestoreReviewRepository implements ReviewRepository {
  final FirebaseFirestore _firestore;
  final LocalReviewRepository _local = LocalReviewRepository();
  static const String collectionPath = 'reviews';

  FirestoreReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  bool _syncAttempted = false;

  /// Background sync to push any locally-logged reviews to Firestore if they were saved offline
  Future<void> syncLocalReviewsToFirestore() async {
    if (_syncAttempted) return;
    _syncAttempted = true;
    try {
      final localReviews = await _local.getRecentReviews(limit: 100);
      for (final r in localReviews) {
        if (!r.id.startsWith('seed_')) {
          await _firestore
              .collection(collectionPath)
              .doc(r.id)
              .set(r.toMap(), SetOptions(merge: true))
              .timeout(const Duration(milliseconds: 2000));
        }
      }
    } catch (_) {}
  }

  @override
  Future<List<Review>> getReviewsForItem(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  }) async {
    // Opportunistically trigger background sync of local reviews
    syncLocalReviewsToFirestore();
    try {
      final list = <Review>[];

      // Query by ID
      final snapshotById = await _firestore
          .collection(collectionPath)
          .where('musicItemId', isEqualTo: musicItemId)
          .get()
          .timeout(const Duration(milliseconds: 3000));
      list.addAll(snapshotById.docs.map((d) => Review.fromMap(d.data())));

      // If itemName is provided, also query by musicItemName if cross-catalog
      if (itemName != null && itemName.trim().isNotEmpty) {
        try {
          final snapshotByName = await _firestore
              .collection(collectionPath)
              .where('musicItemName', isEqualTo: itemName)
              .get()
              .timeout(const Duration(milliseconds: 3000));
          list.addAll(snapshotByName.docs.map((d) => Review.fromMap(d.data())));
        } catch (_) {}

        // Also query stripped base title if itemName contained brackets/editions
        final baseTitle = itemName.replaceAll(RegExp(r'\s*[\(\[].*?[\)\]]'), '').trim();
        if (baseTitle.isNotEmpty && baseTitle.toLowerCase() != itemName.trim().toLowerCase()) {
          try {
            final snapshotByBase = await _firestore
                .collection(collectionPath)
                .where('musicItemName', isEqualTo: baseTitle)
                .get()
                .timeout(const Duration(milliseconds: 3000));
            list.addAll(snapshotByBase.docs.map((d) => Review.fromMap(d.data())));
          } catch (_) {}
        }
      }

      final localList = await _local.getReviewsForItem(
        musicItemId,
        itemName: itemName,
        artistName: artistName,
        itemType: itemType,
      );

      final map = <String, Review>{};
      for (final r in localList) {
        map[r.id] = r;
      }
      for (final r in list) {
        if (r.matchesItem(
          id: musicItemId,
          name: itemName,
          artist: artistName,
          type: itemType,
        )) {
          map[r.id] = r;
        }
      }
      final merged = map.values.toList();
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (_) {
      return _local.getReviewsForItem(
        musicItemId,
        itemName: itemName,
        artistName: artistName,
        itemType: itemType,
      );
    }
  }

  @override
  Future<List<Review>> getRecentReviews({int limit = 20}) async {
    // Opportunistically trigger background sync of local reviews
    syncLocalReviewsToFirestore();
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get()
          .timeout(const Duration(milliseconds: 3000));
      final list = snapshot.docs.map((d) => Review.fromMap(d.data())).toList();
      final localList = await _local.getRecentReviews(limit: limit);
      final map = <String, Review>{};
      for (final r in localList) {
        map[r.id] = r;
      }
      for (final r in list) {
        map[r.id] = r;
      }
      final merged = map.values.toList();
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged.take(limit).toList();
    } catch (_) {
      return _local.getRecentReviews(limit: limit);
    }
  }

  @override
  Future<List<Review>> getUserReviews(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(milliseconds: 2500));
      final list = snapshot.docs.map((d) => Review.fromMap(d.data())).toList();
      final localList = await _local.getUserReviews(userId);
      final map = <String, Review>{};
      for (final r in localList) {
        map[r.id] = r;
      }
      if (userId != 'user_me') {
        final guestLocal = await _local.getUserReviews('user_me');
        for (final r in guestLocal) {
          map[r.id] = r;
        }
      }
      for (final r in list) {
        map[r.id] = r;
      }
      final merged = map.values.toList();
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (_) {
      final localList = await _local.getUserReviews(userId);
      if (userId != 'user_me') {
        final guestLocal = await _local.getUserReviews('user_me');
        final map = <String, Review>{};
        for (final r in localList) {
          map[r.id] = r;
        }
        for (final r in guestLocal) {
          map[r.id] = r;
        }
        final merged = map.values.toList();
        merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return merged;
      }
      return localList;
    }
  }

  @override
  Future<void> addReview(Review review) async {
    // 1. Immediately store to local storage (instant and offline resilient)
    await _local.addReview(review);

    // 2. Sync to Cloud Firestore with fail-safe timeout
    try {
      await _firestore
          .collection(collectionPath)
          .doc(review.id)
          .set(review.toMap())
          .timeout(const Duration(milliseconds: 2500));
    } catch (_) {
      // Offline queue or transient latency; local store already has it
    }
  }

  @override
  Future<void> likeReview(String reviewId) async {
    await _local.likeReview(reviewId);
    try {
      await _firestore
          .collection(collectionPath)
          .doc(reviewId)
          .update({'likesCount': FieldValue.increment(1)})
          .timeout(const Duration(milliseconds: 2500));
    } catch (_) {}
  }

  @override
  Future<double> getAverageScore(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  }) async {
    final reviews = await getReviewsForItem(
      musicItemId,
      itemName: itemName,
      artistName: artistName,
      itemType: itemType,
    );
    if (reviews.isEmpty) return 0.0;
    return reviews.fold<double>(0.0, (acc, r) => acc + r.rating) / reviews.length;
  }

  @override
  Future<int> getReviewCount(
    String musicItemId, {
    String? itemName,
    String? artistName,
    String? itemType,
  }) async {
    final reviews = await getReviewsForItem(
      musicItemId,
      itemName: itemName,
      artistName: artistName,
      itemType: itemType,
    );
    return reviews.length;
  }

  @override
  Future<void> updateAuthorMetadata(String userId, String newName, String newHandle, [String? newAvatarUrl]) async {
    await _local.updateAuthorMetadata(userId, newName, newHandle, newAvatarUrl);
    try {
      final userReviews = await _firestore
          .collection(collectionPath)
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(milliseconds: 2500));
      for (final doc in userReviews.docs) {
        final updateData = <String, dynamic>{
          'userName': newName,
          'userHandle': newHandle,
        };
        if (newAvatarUrl != null) {
          updateData['userAvatarUrl'] = newAvatarUrl;
        }
        await doc.reference.update(updateData).timeout(const Duration(milliseconds: 1500));
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _local.deleteReview(reviewId);
    try {
      await _firestore
          .collection(collectionPath)
          .doc(reviewId)
          .delete()
          .timeout(const Duration(milliseconds: 2500));
    } catch (_) {}
  }

  @override
  Future<void> migrateUserReviews({
    required String fromUserId,
    required String toUserId,
    required String newName,
    required String newHandle,
    String? newAvatarUrl,
  }) async {
    await _local.migrateUserReviews(
      fromUserId: fromUserId,
      toUserId: toUserId,
      newName: newName,
      newHandle: newHandle,
      newAvatarUrl: newAvatarUrl,
    );
    try {
      final snapshot = await _firestore
          .collection(collectionPath)
          .where('userId', isEqualTo: fromUserId)
          .get()
          .timeout(const Duration(milliseconds: 3000));
      for (final doc in snapshot.docs) {
        final updateData = <String, dynamic>{
          'userId': toUserId,
          'userName': newName,
          'userHandle': newHandle,
        };
        if (newAvatarUrl != null) {
          updateData['userAvatarUrl'] = newAvatarUrl;
        }
        await doc.reference.update(updateData).timeout(const Duration(milliseconds: 1500));
      }
    } catch (_) {}
  }
}
