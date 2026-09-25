import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';
import 'review_repository.dart';

class LocalReviewRepository implements ReviewRepository {
  static const String _storageKey = 'groovd_user_reviews_v1';
  final List<Review> _inMemoryReviews = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Real user reviews only - no mock reviews
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getStringList(_storageKey);
      bool needsPruning = false;
      if (storedJson != null && storedJson.isNotEmpty) {
        for (final item in storedJson) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final review = Review.fromMap(map);
            final isMock = review.id.startsWith('rev_1') ||
                review.id.startsWith('rev_2') ||
                review.id.startsWith('rev_3') ||
                review.id.startsWith('rev_4') ||
                review.id.startsWith('rev_5') ||
                review.id.startsWith('seed_') ||
                review.userId.startsWith('critic_') ||
                review.userName.toUpperCase() == 'ARCHIVE_99' ||
                review.userName.toUpperCase() == 'VEX // VINYL' ||
                review.userName.toUpperCase() == 'NEO_RAVER' ||
                review.userName.toUpperCase() == 'SONIC_JOURNAL' ||
                review.userName.toUpperCase() == 'HEADPHONE_LUST' ||
                review.userHandle.toLowerCase() == '@archive_99' ||
                review.userHandle.toLowerCase() == '@vexvinyl' ||
                review.userHandle.toLowerCase() == '@neoraver' ||
                review.userHandle.toLowerCase() == '@sonicjournal' ||
                review.userHandle.toLowerCase() == '@audiophile_zero';

            if (isMock) {
              needsPruning = true;
              continue;
            }

            // Avoid duplicates
            if (!_inMemoryReviews.any((r) => r.id == review.id)) {
              _inMemoryReviews.insert(0, review);
            }
          } catch (_) {}
        }
      }
      if (needsPruning) {
        await _persist();
      }
    } catch (_) {}

    _initialized = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userReviews = _inMemoryReviews
          .map((r) => jsonEncode(r.toMap()))
          .toList();
      await prefs.setStringList(_storageKey, userReviews);
    } catch (_) {}
  }

  @override
  Future<List<Review>> getReviewsForItem(String musicItemId) async {
    await _ensureInitialized();
    final list = _inMemoryReviews.where((r) => r.musicItemId == musicItemId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<List<Review>> getRecentReviews({int limit = 20}) async {
    await _ensureInitialized();
    final sorted = List<Review>.from(_inMemoryReviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Review>> getUserReviews(String userId) async {
    await _ensureInitialized();
    final list = _inMemoryReviews.where((r) => r.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> addReview(Review review) async {
    await _ensureInitialized();
    // Remove if already exists with same id or replace
    _inMemoryReviews.removeWhere((r) => r.id == review.id);
    _inMemoryReviews.insert(0, review);
    await _persist();
  }

  @override
  Future<void> likeReview(String reviewId) async {
    await _ensureInitialized();
    final index = _inMemoryReviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      final r = _inMemoryReviews[index];
      _inMemoryReviews[index] = r.copyWith(likesCount: r.likesCount + 1);
      await _persist();
    }
  }

  @override
  Future<double> getAverageScore(String musicItemId) async {
    await _ensureInitialized();
    final items = _inMemoryReviews.where((r) => r.musicItemId == musicItemId).toList();
    if (items.isEmpty) return 0.0;
    final sum = items.fold<double>(0.0, (acc, r) => acc + r.rating);
    return sum / items.length;
  }

  @override
  Future<int> getReviewCount(String musicItemId) async {
    await _ensureInitialized();
    return _inMemoryReviews.where((r) => r.musicItemId == musicItemId).length;
  }

  @override
  Future<void> updateAuthorMetadata(String userId, String newName, String newHandle, [String? newAvatarUrl]) async {
    await _ensureInitialized();
    bool changed = false;
    for (int i = 0; i < _inMemoryReviews.length; i++) {
      if (_inMemoryReviews[i].userId == userId) {
        _inMemoryReviews[i] = _inMemoryReviews[i].copyWith(
          userName: newName,
          userHandle: newHandle,
          userAvatarUrl: newAvatarUrl ?? _inMemoryReviews[i].userAvatarUrl,
        );
        changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await _ensureInitialized();
    final initialLength = _inMemoryReviews.length;
    _inMemoryReviews.removeWhere((r) => r.id == reviewId);
    if (_inMemoryReviews.length != initialLength) {
      await _persist();
    }
  }

  @override
  Future<void> migrateUserReviews({
    required String fromUserId,
    required String toUserId,
    required String newName,
    required String newHandle,
    String? newAvatarUrl,
  }) async {
    await _ensureInitialized();
    bool changed = false;
    for (int i = 0; i < _inMemoryReviews.length; i++) {
      if (_inMemoryReviews[i].userId == fromUserId) {
        _inMemoryReviews[i] = _inMemoryReviews[i].copyWith(
          userId: toUserId,
          userName: newName,
          userHandle: newHandle,
          userAvatarUrl: newAvatarUrl ?? _inMemoryReviews[i].userAvatarUrl,
        );
        changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
  }
}
