import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class GiantScoreBadge extends StatelessWidget {
  final double score;
  final int? reviewCount;
  final bool compact;

  const GiantScoreBadge({
    super.key,
    required this.score,
    this.reviewCount,
    this.compact = false,
  });

  Color get _accentColor {
    if (score >= 9.0) return AppColors.acidLime;
    if (score >= 8.0) return AppColors.cyberCyan;
    if (score >= 6.5) return AppColors.electricPink;
    if (score >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  String get _descriptor {
    if (score >= 9.5) return 'MASTERPIECE';
    if (score >= 8.5) return 'CRITIC\'S ESSENTIAL';
    if (score >= 7.5) return 'UNIVERSAL ACCLAIM';
    if (score >= 6.0) return 'GENERALLY FAVORABLE';
    if (score >= 4.5) return 'MIXED REVIEWS';
    return 'CRITICAL SKIP';
  }

  @override
  Widget build(BuildContext context) {
    final scoreStr = score > 0 ? score.toStringAsFixed(1) : '—.—';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.pureBlack, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              scoreStr,
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
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'COMMUNITY SCORE',
                style: AppTypography.monoLabel(fontSize: 10, letterSpacing: 2.0),
              ),
              if (reviewCount != null)
                Text(
                  '$reviewCount REVIEWS',
                  style: AppTypography.monoLabel(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.pureBlack, width: 2.0),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pureBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  scoreStr,
                  style: AppTypography.scoreGiant(color: AppColors.pureBlack),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '/ 10.0',
                      style: AppTypography.scoreMedium(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        _descriptor,
                        style: AppTypography.monoBadge(
                          color: _accentColor,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
