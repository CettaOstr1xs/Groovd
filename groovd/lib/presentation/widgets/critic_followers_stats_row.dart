import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Neo-brutalist counter row displaying a critic's followers and following count.
class CriticFollowersStatsRow extends StatelessWidget {
  final int followersCount;
  final int followingCount;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const CriticFollowersStatsRow({
    super.key,
    required this.followersCount,
    required this.followingCount,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  static String formatCount(int count) {
    if (count >= 1000000) {
      final millions = (count / 1000000).toStringAsFixed(1);
      return '${millions.endsWith('.0') ? millions.substring(0, millions.length - 2) : millions}M';
    }
    if (count >= 1000) {
      final thousands = (count / 1000).toStringAsFixed(1);
      return '${thousands.endsWith('.0') ? thousands.substring(0, thousands.length - 2) : thousands}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatPill(
          context,
          count: formatCount(followersCount),
          label: 'FOLLOWERS',
          accentColor: AppColors.acidLime,
          onTap: onFollowersTap,
        ),
        const SizedBox(width: 8),
        _buildStatPill(
          context,
          count: formatCount(followingCount),
          label: 'FOLLOWING',
          accentColor: AppColors.cyberCyan,
          onTap: onFollowingTap,
        ),
      ],
    );
  }

  Widget _buildStatPill(
    BuildContext context, {
    required String count,
    required String label,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard.withValues(alpha: 0.8),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(2),
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
          children: [
            Container(
              width: 3.5,
              height: 11,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              count,
              style: AppTypography.monoLabel(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.monoLabel(
                color: AppColors.textSecondary,
                fontSize: 9.5,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
