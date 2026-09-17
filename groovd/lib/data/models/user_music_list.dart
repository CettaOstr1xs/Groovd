import 'music_item.dart';

class UserMusicList {
  final String id;
  final String title;
  final String description;
  final List<MusicItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserMusicList({
    required this.id,
    required this.title,
    this.description = '',
    this.items = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  int get itemCount => items.length;
  int get albumCount => items.where((i) => i.isAlbum).length;
  int get songCount => items.where((i) => !i.isAlbum).length;

  List<String> get previewCoverUrls {
    final urls = <String>[];
    for (final item in items) {
      if (item.coverUrl.isNotEmpty && !urls.contains(item.coverUrl)) {
        urls.add(item.coverUrl);
        if (urls.length == 4) break;
      }
    }
    return urls;
  }

  String get summaryLabel {
    if (items.isEmpty) return 'EMPTY ARCHIVE';
    if (albumCount > 0 && songCount > 0) {
      return '$albumCount ${albumCount == 1 ? 'LP' : 'LPS'} • $songCount ${songCount == 1 ? 'TRACK' : 'TRACKS'}';
    } else if (albumCount > 0) {
      return '$albumCount ${albumCount == 1 ? 'ALBUM' : 'ALBUMS'}';
    } else {
      return '$songCount ${songCount == 1 ? 'TRACK' : 'TRACKS'}';
    }
  }

  UserMusicList copyWith({
    String? id,
    String? title,
    String? description,
    List<MusicItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserMusicList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'items': items.map((i) => i.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserMusicList.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];
    return UserMusicList(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'UNTITLED LIST',
      description: map['description'] as String? ?? '',
      items: rawItems
          .map((itemMap) => MusicItem.fromMap(Map<String, dynamic>.from(itemMap as Map)))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
