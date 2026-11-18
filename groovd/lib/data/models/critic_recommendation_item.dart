import 'music_item.dart';

/// Represents an AI-generated album recommendation tailored to the user's taste.
class CriticRecommendationItem {
  final MusicItem item;
  final String reasoning;
  final String vibeTag;
  final DateTime generatedAt;

  const CriticRecommendationItem({
    required this.item,
    required this.reasoning,
    required this.vibeTag,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'item': item.toMap(),
      'reasoning': reasoning,
      'vibeTag': vibeTag,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory CriticRecommendationItem.fromJson(Map<String, dynamic> json) {
    return CriticRecommendationItem(
      item: MusicItem.fromMap(json['item'] as Map<String, dynamic>? ?? {}),
      reasoning: json['reasoning'] as String? ?? '',
      vibeTag: json['vibeTag'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  CriticRecommendationItem copyWith({
    MusicItem? item,
    String? reasoning,
    String? vibeTag,
    DateTime? generatedAt,
  }) {
    return CriticRecommendationItem(
      item: item ?? this.item,
      reasoning: reasoning ?? this.reasoning,
      vibeTag: vibeTag ?? this.vibeTag,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
