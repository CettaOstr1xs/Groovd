import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/music_item.dart';
import '../data/models/user_music_list.dart';
import 'auth_providers.dart';
import 'user_profile_provider.dart';

class UserListsNotifier extends Notifier<List<UserMusicList>> {
  static const String _storageKey = 'groovd_user_lists_v1';

  String get _currentUserId {
    final authUser = ref.read(authStateProvider).asData?.value;
    if (authUser != null) return authUser.uid;
    return ref.read(userProfileProvider).userId;
  }

  @override
  List<UserMusicList> build() {
    _loadFromPrefs();

    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final prevUser = previous?.asData?.value;
      final nextUser = next.asData?.value;
      if (prevUser != null && nextUser == null) {
        resetToGuest();
      } else if (nextUser != null && prevUser?.uid != nextUser.uid) {
        syncForUser(nextUser.uid);
      }
    });

    return const [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      final loaded = <UserMusicList>[];
      for (final raw in rawList) {
        if (raw.isNotEmpty) {
          try {
            final map = jsonDecode(raw) as Map<String, dynamic>;
            loaded.add(UserMusicList.fromMap(map));
          } catch (_) {}
        }
      }
      state = loaded;
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
          .collection('lists')
          .get()
          .timeout(const Duration(milliseconds: 3000));

      final cloudLists = <UserMusicList>[];
      for (final doc in snapshot.docs) {
        try {
          cloudLists.add(UserMusicList.fromMap(doc.data()));
        } catch (_) {}
      }

      final map = {for (final l in state) l.id: l};
      for (final cl in cloudLists) {
        if (!map.containsKey(cl.id) || cl.updatedAt.isAfter(map[cl.id]!.updatedAt)) {
          map[cl.id] = cl;
        }
      }

      final merged = map.values.toList();
      merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      state = merged;
      await _persistLocal();

      // Push any local lists that are missing in cloud
      for (final l in state) {
        if (!cloudLists.any((c) => c.id == l.id)) {
          await firestore
              .collection('users')
              .doc(uid)
              .collection('lists')
              .doc(l.id)
              .set(l.toMap(), SetOptions(merge: true))
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
    state = const [];
  }

  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = state.map((item) => jsonEncode(item.toMap())).toList();
      await prefs.setStringList(_storageKey, listJson);
    } catch (_) {}
  }

  Future<void> _syncDocToFirestore(UserMusicList list) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('lists')
            .doc(list.id)
            .set(list.toMap())
            .timeout(const Duration(milliseconds: 2500));
      }
    } catch (_) {}
  }

  Future<void> _deleteDocFromFirestore(String listId) async {
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('lists')
            .doc(listId)
            .delete()
            .timeout(const Duration(milliseconds: 2500));
      }
    } catch (_) {}
  }

  /// Creates a new curated list and returns it.
  Future<UserMusicList> createList(String title, {String description = ''}) async {
    final now = DateTime.now();
    final cleanTitle = title.trim().isEmpty ? 'UNTITLED ARCHIVE' : title.trim();
    final newList = UserMusicList(
      id: 'list_${now.millisecondsSinceEpoch}',
      title: cleanTitle,
      description: description.trim(),
      items: const [],
      createdAt: now,
      updatedAt: now,
    );

    final current = List<UserMusicList>.from(state);
    current.insert(0, newList);
    state = current;

    await _persistLocal();
    _syncDocToFirestore(newList);
    return newList;
  }

  /// Updates title or description of an existing list.
  Future<void> updateList(String listId, {String? title, String? description}) async {
    final index = state.indexWhere((l) => l.id == listId);
    if (index == -1) return;

    final existing = state[index];
    final updated = existing.copyWith(
      title: title != null && title.trim().isNotEmpty ? title.trim() : existing.title,
      description: description ?? existing.description,
      updatedAt: DateTime.now(),
    );

    final current = List<UserMusicList>.from(state);
    current[index] = updated;
    state = current;

    await _persistLocal();
    _syncDocToFirestore(updated);
  }

  /// Deletes a list completely.
  Future<void> deleteList(String listId) async {
    final current = List<UserMusicList>.from(state);
    current.removeWhere((l) => l.id == listId);
    state = current;

    await _persistLocal();
    _deleteDocFromFirestore(listId);
  }

  /// Appends an album or song to a list (avoiding duplicate within the same list).
  Future<bool> addItemToList(String listId, MusicItem item) async {
    final index = state.indexWhere((l) => l.id == listId);
    if (index == -1) return false;

    final existing = state[index];
    if (existing.items.any((i) => i.id == item.id)) {
      return false; // already in list
    }

    final updatedItems = List<MusicItem>.from(existing.items)..add(item);
    final updated = existing.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    final current = List<UserMusicList>.from(state);
    current[index] = updated;
    state = current;

    await _persistLocal();
    _syncDocToFirestore(updated);
    return true;
  }

  /// Removes an item from a list.
  Future<void> removeItemFromList(String listId, String musicItemId) async {
    final index = state.indexWhere((l) => l.id == listId);
    if (index == -1) return;

    final existing = state[index];
    final updatedItems = List<MusicItem>.from(existing.items)
      ..removeWhere((i) => i.id == musicItemId);

    final updated = existing.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    final current = List<UserMusicList>.from(state);
    current[index] = updated;
    state = current;

    await _persistLocal();
    _syncDocToFirestore(updated);
  }

  /// Reorders items in a list.
  Future<void> reorderItems(String listId, int oldIndex, int newIndex) async {
    final index = state.indexWhere((l) => l.id == listId);
    if (index == -1) return;

    final existing = state[index];
    final updatedItems = List<MusicItem>.from(existing.items);
    if (oldIndex < 0 || oldIndex >= updatedItems.length) return;
    final item = updatedItems.removeAt(oldIndex);
    final targetIndex = newIndex.clamp(0, updatedItems.length);
    updatedItems.insert(targetIndex, item);

    final updated = existing.copyWith(
      items: updatedItems,
      updatedAt: DateTime.now(),
    );

    final current = List<UserMusicList>.from(state);
    current[index] = updated;
    state = current;

    await _persistLocal();
    _syncDocToFirestore(updated);
  }
}

final userListsProvider =
    NotifierProvider<UserListsNotifier, List<UserMusicList>>(UserListsNotifier.new);

final userListsCountProvider = Provider<int>((ref) {
  return ref.watch(userListsProvider).length;
});

final listByIdProvider = Provider.family<UserMusicList?, String>((ref, listId) {
  final lists = ref.watch(userListsProvider);
  try {
    return lists.firstWhere((l) => l.id == listId);
  } catch (_) {
    return null;
  }
});

/// Fetches another critic's curated lists from Cloud Firestore
final userCuratedListsProvider =
    FutureProvider.family<List<UserMusicList>, String>((ref, userId) async {
  try {
    if (Firebase.apps.isEmpty) return const [];
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('lists')
        .get()
        .timeout(const Duration(milliseconds: 3000));

    final lists = <UserMusicList>[];
    for (final doc in snapshot.docs) {
      try {
        lists.add(UserMusicList.fromMap(doc.data()));
      } catch (_) {}
    }
    lists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return lists;
  } catch (_) {
    return const [];
  }
});
