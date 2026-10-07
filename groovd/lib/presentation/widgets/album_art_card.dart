import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/state/review_providers.dart';

class AlbumArtCard extends ConsumerWidget {
  final String imageUrl;
  final double size;
  final double? width;
  final double? height;
  final String? badgeLabel;
  final Color badgeColor;
  final bool showShadow;
  final String? heroTag;
  final VoidCallback? onTap;
  final int? logCount;
  final MusicItem? musicItem;
  final String? musicItemId;
  final bool showRepeatCount;

  const AlbumArtCard({
    super.key,
    required this.imageUrl,
    this.size = 120,
    this.width,
    this.height,
    this.badgeLabel,
    this.badgeColor = AppColors.acidLime,
    this.showShadow = true,
    this.heroTag,
    this.onTap,
    this.logCount,
    this.musicItem,
    this.musicItemId,
    this.showRepeatCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = width ?? size;
    final h = height ?? size;

    int? effectiveCount;
    if (showRepeatCount) {
      effectiveCount = logCount;
      if (effectiveCount == null) {
        if (musicItem != null) {
          effectiveCount = ref.watch(currentUserItemLogCountProvider(ItemReviewQuery.fromItem(musicItem!)));
        } else if (musicItemId != null && musicItemId!.isNotEmpty) {
          final counts = ref.watch(currentUserLogCountsProvider);
          effectiveCount = counts[musicItemId!] ?? 0;
        }
      }
    }

    Widget imageContent = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.borderBold, width: 2.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const _BrutalistShimmer(),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceElevated,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.album, color: AppColors.textMuted, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'NO ART',
                      style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 8),
                    ),
                  ],
                ),
              ),
            )
          : Container(
              color: AppColors.surfaceElevated,
              alignment: Alignment.center,
              child: const Icon(Icons.music_note, color: AppColors.textMuted, size: 32),
            ),
    );

    if (heroTag != null) {
      imageContent = Hero(
        tag: heroTag!,
        child: Material(
          color: Colors.transparent,
          child: imageContent,
        ),
      );
    }

    Widget result = Stack(
      clipBehavior: Clip.none,
      children: [
        // Hard-edge offset shadow
        if (showShadow)
          Positioned(
            top: 4,
            left: 4,
            right: -4,
            bottom: -4,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.pureBlack,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
            ),
          ),

        // Main Image Frame
        imageContent,

        // Optional badge
        if (badgeLabel != null)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.pureBlack, width: 1.0),
              ),
              child: Text(
                badgeLabel!.toUpperCase(),
                style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 8),
              ),
            ),
          ),

        // Count badge if logged more than 1 time (e.g. 2x, 3x)
        if (effectiveCount != null && effectiveCount > 1)
          Positioned(
            top: 5,
            left: 5,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: w < 60 ? 3.5 : 5.0,
                vertical: w < 60 ? 1.0 : 2.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.acidLime,
                borderRadius: BorderRadius.circular(1.5),
                border: Border.all(color: AppColors.pureBlack, width: 1.2),
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
                  Icon(
                    Icons.repeat,
                    size: w < 60 ? 7.5 : 9.0,
                    color: AppColors.pureBlack,
                  ),
                  SizedBox(width: w < 60 ? 1.5 : 2.5),
                  Text(
                    '${effectiveCount}X',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: w < 60 ? 7.5 : 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: result,
        ),
      );
    }

    return result;
  }
}

class _BrutalistShimmer extends StatefulWidget {
  const _BrutalistShimmer();

  @override
  State<_BrutalistShimmer> createState() => _BrutalistShimmerState();
}

class _BrutalistShimmerState extends State<_BrutalistShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final pulse = 0.25 + (_anim.value * 0.4);
        return Container(
          color: AppColors.surfaceElevated.withValues(alpha: pulse),
          alignment: Alignment.center,
          child: Opacity(
            opacity: 0.4 + (_anim.value * 0.5),
            child: const Icon(Icons.music_note, color: AppColors.acidLime, size: 24),
          ),
        );
      },
    );
  }
}
