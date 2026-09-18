import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/state/user_profile_provider.dart';

class ReviewCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isCurrentUser = review.userId == profile.userId || review.userId == 'user_me';
    final authorName = isCurrentUser ? profile.userName : review.userName;
    final authorHandle = isCurrentUser ? profile.userHandle : review.userHandle;
    final hasCustomAvatar = isCurrentUser && profile.avatarPath != null;

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
                    color: isCurrentUser && hasCustomAvatar
                        ? AppColors.pureBlack
                        : (isCurrentUser ? AppColors.acidLime : AppColors.surfaceElevated),
                    border: Border.all(
                      color: isCurrentUser ? AppColors.acidLime : AppColors.borderBold,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  alignment: Alignment.center,
                  child: hasCustomAvatar
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: Image.file(
                            File(profile.avatarPath!),
                            width: 28,
                            height: 28,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              authorName.isNotEmpty ? authorName[0].toUpperCase() : 'C',
                              style: AppTypography.monoBadge(
                                color: isCurrentUser ? AppColors.pureBlack : AppColors.textPrimary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          authorName.isNotEmpty ? authorName[0].toUpperCase() : 'C',
                          style: AppTypography.monoBadge(
                            color: isCurrentUser ? AppColors.pureBlack : AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName.toUpperCase(),
                        style: AppTypography.monoLabel(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$authorHandle • ${review.timeAgo}',
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

            // Optional Music Item Context (if in global feed)
            if (showItemHeader && review.musicItemName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.itemType == 'album' ? Icons.album : Icons.music_note,
                      size: 12,
                      color: AppColors.acidLime,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${review.musicItemName} — ${review.artistName}'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoBadge(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Headline
            if (review.headline.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.headline.toUpperCase(),
                style: AppTypography.headline(),
              ),
            ],

            // Body
            if (review.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.body,
                style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              ),
            ],

            const SizedBox(height: 14),

            // Tags & Like button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                // Animated Like button
                _AnimatedLikeButton(
                  likesCount: review.likesCount,
                  onLike: onLike,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLikeButton extends StatefulWidget {
  final int likesCount;
  final VoidCallback? onLike;

  const _AnimatedLikeButton({required this.likesCount, this.onLike});

  @override
  State<_AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<_AnimatedLikeButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.42), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.42, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    setState(() => _isLiked = !_isLiked);
    _controller.forward(from: 0.0);
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _isLiked ? AppColors.electricPink.withValues(alpha: 0.15) : AppColors.surfaceElevated,
          border: Border.all(
            color: _isLiked ? AppColors.electricPink : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 14,
                color: AppColors.electricPink,
              ),
            ),
            const SizedBox(width: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.35),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Text(
                '${widget.likesCount + (_isLiked ? 1 : 0)}',
                key: ValueKey<int>(widget.likesCount + (_isLiked ? 1 : 0)),
                style: AppTypography.monoBadge(
                  color: _isLiked ? AppColors.electricPink : AppColors.textPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
