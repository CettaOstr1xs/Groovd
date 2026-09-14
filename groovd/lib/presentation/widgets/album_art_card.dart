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

  const AlbumArtCard({
    super.key,
    required this.imageUrl,
    this.size = 120,
    this.width,
    this.height,
    this.badgeLabel,
    this.badgeColor = AppColors.acidLime,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

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
        Container(
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
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceCard,
                    alignment: Alignment.center,
                    child: Text(
                      'LOADING...',
                      style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 9),
                    ),
                  ),
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
        ),

        // Optional badge
        if (badgeLabel != null)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.pureBlack, width: 1.5),
              ),
              child: Text(
                badgeLabel!.toUpperCase(),
                style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}
