import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/music_item.dart';
import '../data/models/wishlist_item.dart';

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  static const String _storageKey = 'groovd_wishlist_items_v1';

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
    current.insert(0, WishlistItem(
      musicItem: item,
      addedAt: DateTime.now(),
      note: note,
    ));
    state = current;
    await _persist();
  }

  Future<void> removeItem(String musicItemId) async {
    final current = List<WishlistItem>.from(state);
    current.removeWhere((w) => w.musicItem.id == musicItemId);
    state = current;
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
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
