import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/music_item.dart';
import 'review_providers.dart';

class DossierTopPicks {
  final List<MusicItem?> topAlbums; // length 3
  final List<MusicItem?> topSongs;  // length 3

  const DossierTopPicks({
    this.topAlbums = const [null, null, null],
    this.topSongs = const [null, null, null],
  });

  DossierTopPicks copyWith({
    List<MusicItem?>? topAlbums,
    List<MusicItem?>? topSongs,
  }) {
    return DossierTopPicks(
      topAlbums: topAlbums ?? this.topAlbums,
      topSongs: topSongs ?? this.topSongs,
    );
  }
}

class DossierTopPicksNotifier extends Notifier<DossierTopPicks> {
  static const String _albumKey = 'groovd_dossier_top_albums_v1';
  static const String _songKey = 'groovd_dossier_top_songs_v1';

  @override
  DossierTopPicks build() {
    _loadFromPrefs();
    return const DossierTopPicks();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final albumStrs = prefs.getStringList(_albumKey) ?? [];
      final songStrs = prefs.getStringList(_songKey) ?? [];

      final albums = List<MusicItem?>.filled(3, null);
      for (int i = 0; i < albumStrs.length && i < 3; i++) {
        if (albumStrs[i].isNotEmpty) {
          try {
            albums[i] = MusicItem.fromMap(jsonDecode(albumStrs[i]) as Map<String, dynamic>);
          } catch (_) {}
        }
      }

      final songs = List<MusicItem?>.filled(3, null);
      for (int i = 0; i < songStrs.length && i < 3; i++) {
        if (songStrs[i].isNotEmpty) {
          try {
            songs[i] = MusicItem.fromMap(jsonDecode(songStrs[i]) as Map<String, dynamic>);
          } catch (_) {}
        }
      }

      state = DossierTopPicks(topAlbums: albums, topSongs: songs);
    } catch (_) {}
  }

  Future<void> pinItem({
    required bool isAlbum,
    required int slotIndex,
    required MusicItem item,
  }) async {
    final currentAlbums = List<MusicItem?>.from(state.topAlbums);
    final currentSongs = List<MusicItem?>.from(state.topSongs);

    if (isAlbum) {
      if (slotIndex >= 0 && slotIndex < 3) {
        currentAlbums[slotIndex] = item;
      }
    } else {
      if (slotIndex >= 0 && slotIndex < 3) {
        currentSongs[slotIndex] = item;
      }
    }

    state = DossierTopPicks(topAlbums: currentAlbums, topSongs: currentSongs);
    await _persist();
  }

  Future<void> unpinItem({
    required bool isAlbum,
    required int slotIndex,
  }) async {
    final currentAlbums = List<MusicItem?>.from(state.topAlbums);
    final currentSongs = List<MusicItem?>.from(state.topSongs);

    if (isAlbum) {
      if (slotIndex >= 0 && slotIndex < 3) {
        currentAlbums[slotIndex] = null;
      }
    } else {
      if (slotIndex >= 0 && slotIndex < 3) {
        currentSongs[slotIndex] = null;
      }
    }

    state = DossierTopPicks(topAlbums: currentAlbums, topSongs: currentSongs);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final albumStrs = state.topAlbums
          .map((a) => a != null ? jsonEncode(a.toMap()) : '')
          .toList();
      final songStrs = state.topSongs
          .map((s) => s != null ? jsonEncode(s.toMap()) : '')
          .toList();
      await prefs.setStringList(_albumKey, albumStrs);
      await prefs.setStringList(_songKey, songStrs);
    } catch (_) {}
  }
}

final dossierTopPicksProvider =
    NotifierProvider<DossierTopPicksNotifier, DossierTopPicks>(
  DossierTopPicksNotifier.new,
);

/// Provider that resolves the final Top 3 Albums and Top 3 Songs,
/// merging user manual pins with automatic review-based highest ratings.
final resolvedTopPicksProvider = Provider<DossierTopPicks>((ref) {
  final picks = ref.watch(dossierTopPicksProvider);
  final userId = ref.watch(currentUserIdProvider);
  final reviewsAsync = ref.watch(userReviewsProvider(userId));
  final reviews = reviewsAsync.asData?.value ?? [];

  // Ranked album reviews
  final albumReviews = reviews
      .where((r) => r.itemType == 'album')
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));

  // Ranked song reviews
  final songReviews = reviews
      .where((r) => r.itemType == 'song')
      .toList()
    ..sort((a, b) => b.rating.compareTo(a.rating));

  final finalAlbums = List<MusicItem?>.from(picks.topAlbums);
  final usedAlbumIds = finalAlbums.whereType<MusicItem>().map((e) => e.id).toSet();

  for (int i = 0; i < 3; i++) {
    if (finalAlbums[i] == null) {
      for (final r in albumReviews) {
        if (!usedAlbumIds.contains(r.musicItemId)) {
          finalAlbums[i] = MusicItem(
            id: r.musicItemId,
            name: r.musicItemName,
            artist: r.artistName,
            type: MusicType.album,
            coverUrl: r.coverUrl,
            releaseDate: '',
          );
          usedAlbumIds.add(r.musicItemId);
          break;
        }
      }
    }
  }

  final finalSongs = List<MusicItem?>.from(picks.topSongs);
  final usedSongIds = finalSongs.whereType<MusicItem>().map((e) => e.id).toSet();

  for (int i = 0; i < 3; i++) {
    if (finalSongs[i] == null) {
      for (final r in songReviews) {
        if (!usedSongIds.contains(r.musicItemId)) {
          finalSongs[i] = MusicItem(
            id: r.musicItemId,
            name: r.musicItemName,
            artist: r.artistName,
            type: MusicType.song,
            coverUrl: r.coverUrl,
            releaseDate: '',
          );
          usedSongIds.add(r.musicItemId);
          break;
        }
      }
    }
  }

  return DossierTopPicks(topAlbums: finalAlbums, topSongs: finalSongs);
});
