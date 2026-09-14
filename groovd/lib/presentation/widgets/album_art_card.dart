import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class AlbumArtCard extends StatelessWidget {
  final String imageUrl;
  final double size;
  final double? width;
  final double? height;
  final String? badgeLabel;
  final Color badgeColor;
  final bool showShadow;
  final String? heroTag;

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
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

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

    return Stack(
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
      ],
    );
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
