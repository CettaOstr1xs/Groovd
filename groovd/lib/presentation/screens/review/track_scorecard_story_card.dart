import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/review.dart';
import '../../widgets/album_art_card.dart';
import '../../widgets/critic_avatar.dart';
import '../../widgets/rating_spike_sign.dart';
import 'critique_story_card.dart';

class StoryTrackRating {
  final int trackNumber;
  final String title;
  final double? rating;
  final int? durationMs;

  const StoryTrackRating({
    required this.trackNumber,
    required this.title,
    this.rating,
    this.durationMs,
  });

  String get scoreFormatted => rating != null ? rating!.toStringAsFixed(1) : '—';

  String get formattedDuration {
    if (durationMs == null || durationMs! <= 0) return '';
    final totalSeconds = durationMs! ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class TrackScorecardStoryCard extends StatelessWidget {
  final Review review;
  final StoryTheme theme;
  final String? avatarPath;
  final List<StoryTrackRating> tracks;
  final double? animationProgress; // 0.0 to 1.0; null means static rest state (1.0)
  final String? releaseYear;

  const TrackScorecardStoryCard({
    super.key,
    required this.review,
    this.theme = StoryTheme.darkMatrix,
    this.avatarPath,
    this.tracks = const [],
    this.animationProgress,
    this.releaseYear,
  });

  Color get _backgroundColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF090A0B);
      case StoryTheme.acidBrutal:
        return AppColors.acidLime;
      case StoryTheme.cyberCyan:
        return const Color(0xFF05131A);
      case StoryTheme.zinePaper:
        return const Color(0xFFF4EFE6);
    }
  }

  Color get _cardBackground {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF131417);
      case StoryTheme.acidBrutal:
        return const Color(0xFF000000);
      case StoryTheme.cyberCyan:
        return const Color(0xFF0B1E26);
      case StoryTheme.zinePaper:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get _primaryTextColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
      case StoryTheme.cyberCyan:
      case StoryTheme.acidBrutal:
        return const Color(0xFFFFFFFF);
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  Color get _secondaryTextColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF8E8E98);
      case StoryTheme.acidBrutal:
        return const Color(0xFFBDBDBD);
      case StoryTheme.cyberCyan:
        return const Color(0xFF75A1B0);
      case StoryTheme.zinePaper:
        return const Color(0xFF666666);
    }
  }

  Color get _accentColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
      case StoryTheme.acidBrutal:
        return AppColors.acidLime;
      case StoryTheme.cyberCyan:
        return AppColors.cyberCyan;
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  Color get _borderColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF282830);
      case StoryTheme.acidBrutal:
        return const Color(0xFF000000);
      case StoryTheme.cyberCyan:
        return AppColors.cyberCyan.withValues(alpha: 0.35);
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  Color get _outerFrameColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF202028);
      case StoryTheme.acidBrutal:
        return const Color(0xFF000000);
      case StoryTheme.cyberCyan:
        return AppColors.cyberCyan;
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(review.createdAt).toUpperCase();
    final progress = animationProgress ?? 1.0;

    // Fast & Punchy 3.5s Animation Keyframe Curve:
    // Phase 1: 0.0 -> 0.28 (~1.0s of 3.5s): Cover centered & zoomed (2.2x).
    // Phase 2: 0.28 -> 0.44 (~0.5s transition): Cover scales down (2.2x -> 1.0x) and glides into header dock.
    // Phase 3: 0.38 -> 0.52: Left-aligned metadata & Overall Score Banner slide / pop in.
    // Phase 4: 0.46 -> 0.86: Track ratings cascade in and Acid Lime gauge lines animate out!
    // Phase 5: 0.82 -> 1.0: Critic signature bar and rest state lock in.

    final bool isZoomPhase = progress < 0.28;
    final double dockProgress = progress < 0.28
        ? 0.0
        : (progress > 0.44 ? 1.0 : ((progress - 0.28) / 0.16));
    final double curvedDock = Curves.easeInOutCubic.transform(dockProgress);

    final double headerProgress = progress < 0.38
        ? 0.0
        : (progress > 0.52 ? 1.0 : ((progress - 0.38) / 0.14));
    final double headerOpacity = headerProgress.clamp(0.0, 1.0);
    final double headerSlideX = 20.0 * (1.0 - headerProgress);

    final double scoreBannerProgress = progress < 0.40
        ? 0.0
        : (progress > 0.54 ? 1.0 : Curves.easeOutBack.transform(((progress - 0.40) / 0.14).clamp(0.0, 1.0)));

    final double coverDockSize = 68.0;
    final double coverZoomSize = 150.0;
    final double currentCoverSize = coverZoomSize - (coverZoomSize - coverDockSize) * curvedDock;

    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(color: _outerFrameColor, width: 3.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Archive Stamp Header (Matching Poster Card)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: Text(
                          'GROOVD',
                          style: AppTypography.monoBadge(
                            color: theme == StoryTheme.acidBrutal
                                ? Colors.black
                                : (theme == StoryTheme.zinePaper ? Colors.white : Colors.black),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '// CRITIC ARCHIVE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.monoLabel(
                            color: theme == StoryTheme.acidBrutal ? Colors.black : _secondaryTextColor,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: AppTypography.monoLabel(
                    color: theme == StoryTheme.acidBrutal ? Colors.black : _secondaryTextColor,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Main Hero Card Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: _borderColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme == StoryTheme.acidBrutal ? Colors.black : Colors.black87,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth;
                    final cardHeight = constraints.maxHeight;

                    final centerOffsetX = (cardWidth - currentCoverSize) / 2;
                    final centerOffsetY = (cardHeight - currentCoverSize) / 2;
                    const dockedOffsetX = 0.0;
                    const dockedOffsetY = 0.0;

                    final currentX = centerOffsetX - (centerOffsetX - dockedOffsetX) * curvedDock;
                    final currentY = centerOffsetY - (centerOffsetY - dockedOffsetY) * curvedDock;

                    return Stack(
                      children: [
                        // Fully Docked Content View
                        Opacity(
                          opacity: curvedDock,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Release Info Row: Docked Cover Slot + Left-Aligned Metadata
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Docked Cover Placeholder
                                  SizedBox(
                                    width: coverDockSize,
                                    height: coverDockSize,
                                  ),
                                  const SizedBox(width: 12),

                                  // Left-Aligned Metadata
                                  Expanded(
                                    child: Transform.translate(
                                      offset: Offset(headerSlideX, 0),
                                      child: Opacity(
                                        opacity: headerOpacity,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Format Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: review.itemType == 'album'
                                                    ? AppColors.acidLime
                                                    : (review.itemType == 'ep' ? AppColors.electricPink : AppColors.cyberCyan),
                                                borderRadius: BorderRadius.circular(1.5),
                                              ),
                                              child: Text(
                                                review.itemType == 'album'
                                                    ? 'LP // ALBUM'
                                                    : (review.itemType == 'ep' ? 'EP // EXTENDED PLAY' : 'SINGLE // SONG'),
                                                style: AppTypography.monoBadge(
                                                  color: AppColors.pureBlack,
                                                  fontSize: 7.5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Title
                                            Text(
                                              review.musicItemName.toUpperCase(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.displaySmall(
                                                fontSize: 15,
                                                color: _primaryTextColor,
                                              ).copyWith(height: 1.15),
                                            ),
                                            const SizedBox(height: 2),

                                            // Artist
                                            Text(
                                              'BY ${review.artistName.toUpperCase()}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.monoLabel(
                                                color: _secondaryTextColor,
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // 2. Big Score Highlight Banner
                              Transform.scale(
                                scale: scoreBannerProgress,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: _accentColor.withValues(alpha: 0.12),
                                    border: Border.all(color: _accentColor, width: 1.5),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'OVERALL CRITIC SCORE',
                                        style: AppTypography.monoLabel(
                                          color: _secondaryTextColor,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RatingSpikeSign(
                                            rating: review.rating,
                                            size: 18,
                                            color: _accentColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${review.scoreFormatted}/10',
                                            style: AppTypography.scoreMedium(
                                              color: _accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 3. Full Tracklist with Solid Straight Acid Lime Rating Lines
                              Expanded(
                                child: _buildDynamicTracklist(context, progress),
                              ),

                              const SizedBox(height: 8),

                              // 4. Critic Signature Bar at bottom of card (Matching Poster Card)
                              Row(
                                children: [
                                  CriticAvatar(
                                    avatarPath: (avatarPath != null && avatarPath!.isNotEmpty)
                                        ? avatarPath
                                        : review.userAvatarUrl,
                                    fallbackInitial: review.userName,
                                    size: 20,
                                    borderRadius: 1.5,
                                    borderWidth: 1.0,
                                    borderColor: Colors.black,
                                    fallbackBgColor: _accentColor,
                                    fallbackTextColor: Colors.black,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          review.userName.toUpperCase(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.monoLabel(
                                            fontSize: 8.5,
                                            color: _primaryTextColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '@${review.userHandle.replaceAll('@', '').toUpperCase()}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.monoLabel(
                                            fontSize: 7.5,
                                            color: _secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: AppColors.acidLime,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Moving / Zooming Cover Artwork Layer
                        Positioned(
                          left: currentX,
                          top: currentY,
                          child: Container(
                            width: currentCoverSize,
                            height: currentCoverSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(
                                color: Colors.white,
                                width: isZoomPhase ? 2.5 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isZoomPhase
                                      ? Colors.black.withValues(alpha: 0.6)
                                      : Colors.black,
                                  offset: isZoomPhase ? const Offset(0, 8) : const Offset(3, 3),
                                  blurRadius: isZoomPhase ? 20 : 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(1),
                              child: AlbumArtCard(
                                imageUrl: review.coverUrl,
                                size: currentCoverSize,
                                showShadow: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bottom Barcode & Verification Footer (Matching Poster Card)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'RATE & LOG REVIEWS ON GROOVD',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoBadge(
                      color: theme == StoryTheme.acidBrutal ? Colors.black : _secondaryTextColor,
                      fontSize: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '||| | |||| | |||',
                  style: AppTypography.monoLabel(
                    color: theme == StoryTheme.acidBrutal ? Colors.black : _accentColor,
                    fontSize: 9.5,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicTracklist(BuildContext context, double progress) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'NO TRACK RATINGS RECORDED',
          style: AppTypography.monoBadge(
            color: _secondaryTextColor,
            fontSize: 9,
          ),
        ),
      );
    }

    // When tracks > 9 (e.g. 10, 12, 14, 16): separate into two columns (1 to N/2 and N/2+1 to N)
    final bool isDualColumn = tracks.length > 9;
    final int count = tracks.length;

    if (!isDualColumn) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(count, (i) {
              final item = tracks[i];
              return _buildTrackRow(
                item: item,
                index: i,
                totalCount: count,
                progress: progress,
                isDualColumn: false,
              );
            }),
          );
        },
      );
    }

    // Two-part partition (e.g. 12 tracks: left 1-6, right 7-12)
    final int half = (count / 2).ceil();
    final leftTracks = tracks.sublist(0, half);
    final rightTracks = tracks.sublist(half);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(leftTracks.length, (i) {
                  final item = leftTracks[i];
                  return _buildTrackRow(
                    item: item,
                    index: i,
                    totalCount: count,
                    progress: progress,
                    isDualColumn: true,
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(rightTracks.length, (i) {
                  final item = rightTracks[i];
                  return _buildTrackRow(
                    item: item,
                    index: half + i,
                    totalCount: count,
                    progress: progress,
                    isDualColumn: true,
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackRow({
    required StoryTrackRating item,
    required int index,
    required int totalCount,
    required double progress,
    required bool isDualColumn,
  }) {
    final double startTime = 0.44 + 0.36 * (index / math.max(1, totalCount));
    final double itemProgress = progress < startTime
        ? 0.0
        : (progress > (startTime + 0.08) ? 1.0 : ((progress - startTime) / 0.08));

    final double opacity = itemProgress.clamp(0.0, 1.0);
    final double slideY = 6.0 * (1.0 - itemProgress);

    // Line fill animation
    final double lineStartTime = startTime + 0.02;
    final double lineProgress = progress < lineStartTime
        ? 0.0
        : (progress > (lineStartTime + 0.12) ? 1.0 : ((progress - lineStartTime) / 0.12));

    final double rating = item.rating ?? 0.0;
    final double ratingFactor = (rating / 10.0).clamp(0.0, 1.0);
    final double currentWidthFactor = ratingFactor * Curves.easeOutCubic.transform(lineProgress.clamp(0.0, 1.0));

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            border: Border.all(
              color: _borderColor.withValues(alpha: 0.35),
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Track Info Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDualColumn ? 5 : 7,
                  vertical: isDualColumn ? 2.5 : 3.5,
                ),
                child: Row(
                  children: [
                    // Index
                    SizedBox(
                      width: isDualColumn ? 16 : 18,
                      child: Text(
                        item.trackNumber.toString().padLeft(2, '0'),
                        style: AppTypography.monoLabel(
                          color: _secondaryTextColor,
                          fontSize: isDualColumn ? 7.5 : 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: isDualColumn ? 4 : 6),

                    // Title
                    Expanded(
                      child: Text(
                        item.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel(
                          color: _primaryTextColor,
                          fontSize: isDualColumn ? 7.5 : 8.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (!isDualColumn && item.formattedDuration.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        child: Text(
                          item.formattedDuration,
                          textAlign: TextAlign.right,
                          style: AppTypography.monoLabel(
                            color: _secondaryTextColor.withValues(alpha: 0.65),
                            fontSize: 7.5,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(width: isDualColumn ? 4 : 6),

                    // Track Score with Iconic Sparkle Sign
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.rating != null) ...[
                          RatingSpikeSign(
                            rating: item.rating!,
                            size: isDualColumn ? 8.0 : 9.5,
                            color: AppColors.acidLime,
                          ),
                          SizedBox(width: isDualColumn ? 2.5 : 3.5),
                        ],
                        Text(
                          item.scoreFormatted,
                          style: AppTypography.monoBadge(
                            color: item.rating != null ? AppColors.acidLime : _secondaryTextColor.withValues(alpha: 0.5),
                            fontSize: isDualColumn ? 7.5 : 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Solid straight rating line ("below the border of each track section, only use that acid lime colour")
              Container(
                height: 2.0,
                width: double.infinity,
                color: _borderColor.withValues(alpha: 0.25),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: currentWidthFactor.clamp(0.0, 1.0),
                  child: Container(
                    color: AppColors.acidLime,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
