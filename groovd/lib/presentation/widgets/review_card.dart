import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/review.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showItemHeader;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.showItemHeader = true,
    this.onLike,
    this.onTap,
  });

  Color get _scoreColor {
    if (review.rating >= 9.0) return AppColors.acidLime;
    if (review.rating >= 8.0) return AppColors.cyberCyan;
    if (review.rating >= 6.5) return AppColors.electricPink;
    if (review.rating >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author & Time header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.borderBold, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'C',
                    style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${review.userHandle} • ${review.timeAgo}',
                        style: AppTypography.monoLabel(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                // Score Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _scoreColor,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.pureBlack, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        review.scoreFormatted,
                        style: AppTypography.scoreMedium(color: AppColors.pureBlack),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '/10',
                        style: AppTypography.monoBadge(
                          color: AppColors.pureBlack.withValues(alpha: 0.7),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional Music Item reference (for feed screens)
            if (showItemHeader) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: const Border(
                    left: BorderSide(color: AppColors.acidLime, width: 3.0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'REVIEW ON: ',
                      style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9),
                    ),
                    Expanded(
                      child: Text(
                        '${review.musicItemName} — ${review.artistName}'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Headline
            if (review.headline.isNotEmpty)
              Text(
                '“${review.headline}”',
                style: AppTypography.headline(color: AppColors.textPrimary),
              ),

            // Body
            if (review.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.body,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tags and Like Bar
            const SizedBox(height: 14),
            Row(
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: review.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          tag.toUpperCase(),
                          style: AppTypography.monoBadge(
                            color: AppColors.textMuted,
                            fontSize: 8,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Like button
                InkWell(
                  onTap: onLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite_border, size: 13, color: AppColors.electricPink),
                        const SizedBox(width: 4),
                        Text(
                          '${review.likesCount}',
                          style: AppTypography.monoBadge(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
