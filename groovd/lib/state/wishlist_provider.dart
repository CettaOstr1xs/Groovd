import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/music_item.dart';
import '../data/models/review.dart';
import '../data/models/wishlist_item.dart';
import 'auth_providers.dart';
import 'user_profile_provider.dart';

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  static const String _storageKey = 'groovd_wishlist_items_v1';

  String get _currentUserId {
    final authUser = ref.read(authStateProvider).asData?.value;
    if (authUser != null) return authUser.uid;
    return ref.read(userProfileProvider).userId;
  }

  @override
  List<WishlistItem> build() {
    _loadFromPrefs();
    return const [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey) ?? [];
      final items = <WishlistItem>[];
      for (final raw in listJson) {
        if (raw.isNotEmpty) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            items.add(WishlistItem.fromMap(map));
          } catch (_) {}
        }
      }
      state = items;
    } catch (_) {}

    // Asynchronously synchronize with Cloud Firestore
    _syncFromFirestore();
  }

  Future<void> _syncFromFirestore([String? targetUserId]) async {
    final uid = targetUserId ?? _currentUserId;
    try {
      if (Firebase.apps.isEmpty) return;
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('wishlist')
          .get()
          .timeout(const Duration(milliseconds: 3000));

      final cloudItems = <WishlistItem>[];
      for (final doc in snapshot.docs) {
        try {
          cloudItems.add(WishlistItem.fromMap(doc.data()));
        } catch (_) {}
      }

      // Merge cloud items with current state
      final currentMap = {for (final item in state) item.musicItem.id: item};
      for (final c in cloudItems) {
        currentMap.putIfAbsent(c.musicItem.id, () => c);
      }

      final merged = currentMap.values.toList();
      merged.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      state = merged;
      await _persist();

      // Also push any local-only items up to cloud
      for (final item in state) {
        if (!cloudItems.any((c) => c.musicItem.id == item.musicItem.id)) {
          await firestore
              .collection('users')
              .doc(uid)
              .collection('wishlist')
              .doc(item.musicItem.id)
              .set(item.toMap())
              .timeout(const Duration(milliseconds: 2000));
        }
      }
    } catch (_) {}
  }

  Future<void> syncForUser(String userId) async {
    await _syncFromFirestore(userId);
  }

  Future<void> resetToGuest() async {
    state = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = state.map((item) => jsonEncode(item.toMap())).toList();
      await prefs.setStringList(_storageKey, listJson);
    } catch (_) {}
  }

  /// Toggles an item in the wishlist.
  /// Returns `true` if added, `false` if removed.
  Future<bool> toggleItem(MusicItem item, {String note = ''}) async {
    final exists = state.any((w) => w.musicItem.id == item.id);
    if (exists) {
      await removeItem(item.id);
      return false;
    } else {
      await addItem(item, note: note);
      return true;
    }
  }

  Future<void> addItem(MusicItem item, {String note = ''}) async {
    final current = List<WishlistItem>.from(state);
    current.removeWhere((w) => w.musicItem.id == item.id);
    final newItem = WishlistItem(
      musicItem: item,
      addedAt: DateTime.now(),
      note: note,
    );
    current.insert(0, newItem);
    state = current;
    await _persist();

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('wishlist')
            .doc(item.id)
            .set(newItem.toMap())
            .timeout(const Duration(milliseconds: 2500));
      }
    } catch (_) {}
  }

  Future<void> removeItem(String musicItemId) async {
    final current = List<WishlistItem>.from(state);
    current.removeWhere((w) => w.musicItem.id == musicItemId);
    state = current;
    await _persist();

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('wishlist')
            .doc(musicItemId)
            .delete()
            .timeout(const Duration(milliseconds: 2500));
      }
    } catch (_) {}
  }

  /// Automatically removes an item matching a review (by ID or matching Title + Artist).
  Future<void> removeItemByReview(Review review) async {
    final current = List<WishlistItem>.from(state);
    final targetName = review.musicItemName.trim().toLowerCase();
    final targetArtist = review.artistName.trim().toLowerCase();

    final removedIds = <String>[];
    current.removeWhere((w) {
      final idMatch = w.musicItem.id == review.musicItemId;
      final nameArtistMatch = w.musicItem.name.trim().toLowerCase() == targetName &&
          w.musicItem.artist.trim().toLowerCase() == targetArtist;
      if (idMatch || nameArtistMatch) {
        removedIds.add(w.musicItem.id);
        return true;
      }
      return false;
    });

    if (current.length != state.length) {
      state = current;
      await _persist();

      try {
        if (Firebase.apps.isNotEmpty) {
          for (final id in removedIds) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserId)
                .collection('wishlist')
                .doc(id)
                .delete()
                .timeout(const Duration(milliseconds: 2000));
          }
        }
      } catch (_) {}
    }
  }

  /// Automatically prunes any wishlist items that have already been rated or reviewed.
  Future<void> removeReviewedItems(List<Review> reviews) async {
    if (reviews.isEmpty || state.isEmpty) return;
    final current = List<WishlistItem>.from(state);
    final reviewedItemIds = reviews.map((r) => r.musicItemId).toSet();
    final reviewedNameArtists = reviews
        .map((r) => '${r.musicItemName.trim().toLowerCase()}:::${r.artistName.trim().toLowerCase()}')
        .toSet();

    final removedIds = <String>[];
    current.removeWhere((w) {
      final idMatches = reviewedItemIds.contains(w.musicItem.id);
      final key = '${w.musicItem.name.trim().toLowerCase()}:::${w.musicItem.artist.trim().toLowerCase()}';
      final nameMatches = reviewedNameArtists.contains(key);
      if (idMatches || nameMatches) {
        removedIds.add(w.musicItem.id);
        return true;
      }
      return false;
    });

    if (current.length != state.length) {
      state = current;
      await _persist();

      try {
        if (Firebase.apps.isNotEmpty) {
          for (final id in removedIds) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUserId)
                .collection('wishlist')
                .doc(id)
                .delete()
                .timeout(const Duration(milliseconds: 2000));
          }
        }
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    final oldIds = state.map((w) => w.musicItem.id).toList();
    state = const [];
    await _persist();

    try {
      if (Firebase.apps.isNotEmpty) {
        for (final id in oldIds) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .collection('wishlist')
              .doc(id)
              .delete()
              .timeout(const Duration(milliseconds: 1500));
        }
      }
    } catch (_) {}
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

final isInWishlistProvider = Provider.family<bool, String>((ref, musicItemId) {
  final items = ref.watch(wishlistProvider);
  return items.any((w) => w.musicItem.id == musicItemId);
});

final wishlistCountProvider = Provider<int>((ref) {
  return ref.watch(wishlistProvider).length;
});
