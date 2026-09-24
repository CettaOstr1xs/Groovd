import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class GiantScoreBadge extends StatelessWidget {
  final double score;
  final int? reviewCount;
  final bool compact;
  final bool verdictBar;
  final String? label;

  const GiantScoreBadge({
    super.key,
    required this.score,
    this.reviewCount,
    this.compact = false,
    this.verdictBar = false,
    this.label,
  });

  const GiantScoreBadge.verdictBar({
    super.key,
    required this.score,
    this.label,
  })  : compact = false,
        verdictBar = true,
        reviewCount = null;

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
    if (verdictBar) {
      return ScoreVerdictBar(
        score: score,
        label: label ?? 'CRITIC SCORE',
      );
    }

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

          // Animated Brutalist score meter bar
          const SizedBox(height: 14),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(1),
            ),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: (score / 10.0).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: Container(
                    color: _accentColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A sleek, redesigned Neo-Brutalist score and verdict bar.
///
/// Features:
/// - Compact, proportional horizontal footprint
/// - Bold score pill with dynamic score-tier accent coloring
/// - Clean label & tier descriptor
/// - 10-segment audio VU level meter
class ScoreVerdictBar extends StatelessWidget {
  final double score;
  final String label;

  const ScoreVerdictBar({
    super.key,
    required this.score,
    this.label = 'CRITIC SCORE',
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
    final accent = _accentColor;
    final descriptor = _descriptor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.borderBold, width: 1.5),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(2.5, 2.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Bold score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.pureBlack, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.pureBlack,
                  offset: Offset(1.5, 1.5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  scoreStr,
                  style: AppTypography.scoreMedium(
                    color: AppColors.pureBlack,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  '/10',
                  style: AppTypography.monoBadge(
                    color: AppColors.pureBlack.withValues(alpha: 0.75),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Label and Category Descriptor
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.monoLabel(
                    fontSize: 9,
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  descriptor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoBadge(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // 10-Segment Neo-Brutalist VU Meter Bar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (idx) {
              final isFilled = (idx + 1) <= score.round();
              return Container(
                width: 3.5,
                height: 18,
                margin: const EdgeInsets.only(left: 2.5),
                decoration: BoxDecoration(
                  color: isFilled ? accent : AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(0.5),
                  border: Border.all(
                    color: isFilled ? AppColors.pureBlack : AppColors.border.withValues(alpha: 0.6),
                    width: 0.8,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
