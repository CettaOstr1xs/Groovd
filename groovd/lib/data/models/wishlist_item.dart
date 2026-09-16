import 'music_item.dart';

class WishlistItem {
  final MusicItem musicItem;
  final DateTime addedAt;
  final String note;

  const WishlistItem({
    required this.musicItem,
    required this.addedAt,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'musicItem': musicItem.toMap(),
      'addedAt': addedAt.toIso8601String(),
      'note': note,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    return WishlistItem(
      musicItem: MusicItem.fromMap(map['musicItem'] as Map<String, dynamic>),
      addedAt: DateTime.tryParse(map['addedAt'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
    );
  }

  WishlistItem copyWith({
    MusicItem? musicItem,
    DateTime? addedAt,
    String? note,
  }) {
    return WishlistItem(
      musicItem: musicItem ?? this.musicItem,
      addedAt: addedAt ?? this.addedAt,
      note: note ?? this.note,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(addedAt);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}
