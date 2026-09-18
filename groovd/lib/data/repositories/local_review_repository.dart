import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/review.dart';
import '../services/spotify_mock_data.dart';
import 'review_repository.dart';

class LocalReviewRepository implements ReviewRepository {
  static const String _storageKey = 'groovd_user_reviews_v1';
  final List<Review> _inMemoryReviews = [];
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // Pre-populate with initial seed reviews
    _inMemoryReviews.addAll(SpotifyMockData.seedReviews);

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getStringList(_storageKey);
      if (storedJson != null && storedJson.isNotEmpty) {
        for (final item in storedJson) {
          try {
            final map = jsonDecode(item) as Map<String, dynamic>;
            final review = Review.fromMap(map);
            // Avoid duplicates
            if (!_inMemoryReviews.any((r) => r.id == review.id)) {
              _inMemoryReviews.insert(0, review);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    _initialized = true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userReviews = _inMemoryReviews
          .where((r) => !SpotifyMockData.seedReviews.any((s) => s.id == r.id))
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
  Future<void> updateAuthorMetadata(String userId, String newName, String newHandle) async {
    await _ensureInitialized();
    bool changed = false;
    for (int i = 0; i < _inMemoryReviews.length; i++) {
      if (_inMemoryReviews[i].userId == userId) {
        _inMemoryReviews[i] = _inMemoryReviews[i].copyWith(
          userName: newName,
          userHandle: newHandle,
        );
        changed = true;
      }
    }
    if (changed) {
      await _persist();
    }
  }
}
