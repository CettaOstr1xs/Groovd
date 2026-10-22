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

  double? get _maxRating {
    final rated = tracks.where((t) => t.rating != null).map((t) => t.rating!).toList();
    return rated.isEmpty ? null : rated.reduce(math.max);
  }

  String get _formattedReleaseDetails {
    final parts = <String>[];

    // Release Year
    final year = (releaseYear != null && releaseYear!.trim().isNotEmpty)
        ? releaseYear!.trim()
        : review.createdAt.year.toString();
    if (year.isNotEmpty) {
      parts.add(year);
    }

    if (review.itemType == 'song') {
      if (tracks.isNotEmpty && tracks.first.formattedDuration.isNotEmpty) {
        parts.add(tracks.first.formattedDuration);
      }
    } else {
      // Track count for EP / Album
      if (tracks.isNotEmpty) {
        parts.add('${tracks.length} ${tracks.length == 1 ? 'TRACK' : 'TRACKS'}');
      }

      // Total Duration across all tracks
      int totalMs = 0;
      for (final t in tracks) {
        if (t.durationMs != null && t.durationMs! > 0) {
          totalMs += t.durationMs!;
        }
      }

      if (totalMs > 0) {
        final totalSeconds = totalMs ~/ 1000;
        final totalMinutes = totalSeconds ~/ 60;
        if (totalMinutes >= 60) {
          final hours = totalMinutes ~/ 60;
          final remainingMins = totalMinutes % 60;
          if (remainingMins > 0) {
            parts.add('${hours}H ${remainingMins}M');
          } else {
            parts.add('${hours}H');
          }
        } else if (totalMinutes > 0) {
          parts.add('$totalMinutes MIN');
        } else {
          parts.add('$totalSeconds SEC');
        }
      }
    }

    return parts.join(' • ');
  }

  Widget _buildFormatBadge({double fontSize = 7.5}) {
    Color badgeColor;
    if (review.itemType == 'album') {
      badgeColor = AppColors.acidLime;
    } else if (review.itemType == 'ep') {
      badgeColor = AppColors.electricPink;
    } else {
      badgeColor = AppColors.cyberCyan;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(1.5),
      ),
      child: Text(
        review.itemType == 'album'
            ? 'LP // ALBUM'
            : (review.itemType == 'ep' ? 'EP // EXTENDED PLAY' : 'SINGLE // SONG'),
        style: AppTypography.monoBadge(
          color: AppColors.pureBlack,
          fontSize: fontSize,
        ),
      ),
    );
  }

  Widget _buildOverallScoreBanner({required double scoreProgressFactor}) {
    final bool isZine = theme == StoryTheme.zinePaper;
    final bool isAcid = theme == StoryTheme.acidBrutal;
    final Color bannerBg = isAcid
        ? const Color(0xFF000000)
        : (isZine ? const Color(0xFFF7F7F7) : const Color(0xFF0D0E11));
    final Color tagTextColor = isZine ? Colors.white : AppColors.pureBlack;
    final Color labelColor = isAcid ? Colors.black : _secondaryTextColor;

    // 10-Block Segmented Rating Calibration Gauge colors
    final Color blockInactiveBg = isAcid
        ? Colors.white.withValues(alpha: 0.12)
        : (isZine ? const Color(0xFFE2DDD5) : const Color(0xFF1B1C22));
    final Color blockBorderColor = isAcid
        ? Colors.white.withValues(alpha: 0.25)
        : (isZine ? const Color(0xFFD0CAC0) : _borderColor.withValues(alpha: 0.5));

    final double currentScore = review.rating * scoreProgressFactor;
    const int totalBlocks = 10;
    const double gap = 2.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bannerBg,
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.8),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: OVERALL Tag + CRITIC SCORE label
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    child: Text(
                      'OVERALL',
                      style: AppTypography.monoBadge(
                        color: tagTextColor,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '// CRITIC SCORE',
                    style: AppTypography.monoLabel(
                      color: labelColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),

              // Right: Iconic Sparkle + Score Display
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  RatingSpikeSign(
                    rating: review.rating,
                    size: 11.0,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: AppTypography.displaySmall(
                      fontSize: 16,
                      color: _accentColor,
                    ).copyWith(fontWeight: FontWeight.w900, height: 1.0),
                  ),
                  Text(
                    '/10',
                    style: AppTypography.monoLabel(
                      fontSize: 8.5,
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          // 10-Block Segmented Rating Calibration Gauge (animates smoothly to the right as each track appears)
          Row(
            children: List.generate(totalBlocks, (index) {
              // Each block represents 1 point range [index.0, (index + 1).0]
              final double fillRatio = (currentScore - index).clamp(0.0, 1.0);
              final bool isBlockActive = fillRatio > 0.0;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < totalBlocks - 1 ? gap : 0.0),
                  child: Container(
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: blockInactiveBg,
                      border: Border.all(
                        color: isBlockActive
                            ? _accentColor.withValues(alpha: 0.6)
                            : blockBorderColor,
                        width: 0.75,
                      ),
                      borderRadius: BorderRadius.circular(1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fillRatio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM d, yyyy').format(review.createdAt).toUpperCase();
    final progress = animationProgress ?? 1.0;

    // Cinematic 8.5s Animation Keyframe Curve (+ 3.0s viewer analysis hold = 11.5s total video):
    // Phase 1: 0.0 -> 0.22 (~1.9s): Big cover centered & zoomed with album and artist name centered below it.
    // Phase 2: 0.22 -> 0.32 (~0.85s): Cover scales down & glides to top-left dock; centered text fades out.
    // Phase 3: 0.30 -> 0.38 (~0.68s): Left-aligned metadata and // TRACKLIST header appear.
    // Phase 4: 0.38 -> 0.88 (~4.25s): Sequential track waterfall: each track appears, loads its acid lime line,
    //          while the 10-block overall critic score seamlessly fills to the right step-by-step!
    // Phase 5: 0.88 -> 0.96 (~0.68s): Top-rated track border illuminates in Acid Lime!
    // Phase 6: 0.94 -> 1.0 (~0.51s): Critic signature bar and rest state lock in.
    // Phase 7: 1.0 (3.0s hold): Resting scorecard remains on screen at 60 FPS for viewer analysis.

    final bool isZoomPhase = progress < 0.22;
    final double dockProgress = progress < 0.22
        ? 0.0
        : (progress > 0.32 ? 1.0 : ((progress - 0.22) / 0.10));
    final double curvedDock = Curves.easeInOutCubic.transform(dockProgress);

    final double headerProgress = progress < 0.30
        ? 0.0
        : (progress > 0.38 ? 1.0 : ((progress - 0.30) / 0.08));
    final double headerOpacity = headerProgress.clamp(0.0, 1.0);
    final double headerSlideX = 18.0 * (1.0 - headerProgress);

    // Docked & Zoomed Cover Sizes
    final double coverDockSize = 92.0;
    final double coverZoomSize = 220.0;
    final double currentCoverSize = coverZoomSize - (coverZoomSize - coverDockSize) * curvedDock;

    // Track waterfall progress parameters (matching _buildTrackRow)
    final bool isDualColumn = tracks.length > 9;
    final int count = tracks.length;
    final int totalSteps = isDualColumn ? ((count / 2).ceil()) : math.max(1, count);

    const double trackPhaseStart = 0.38;
    const double trackPhaseEnd = 0.88;

    // Adapt the 10-block overall critic score fill to move smoothly to the right
    // as each track appears and finishes its animation:
    double scoreProgressFactor;
    if (animationProgress == null) {
      scoreProgressFactor = 1.0;
    } else if (progress <= trackPhaseStart) {
      scoreProgressFactor = 0.0;
    } else if (progress >= trackPhaseEnd) {
      scoreProgressFactor = 1.0;
    } else {
      if (tracks.isEmpty) {
        scoreProgressFactor = Curves.easeInOutCubic.transform(
          ((progress - trackPhaseStart) / (trackPhaseEnd - trackPhaseStart)).clamp(0.0, 1.0),
        );
      } else {
        final double stepDuration = (trackPhaseEnd - trackPhaseStart) / totalSteps;
        final double elapsed = progress - trackPhaseStart;
        final int currentStep = (elapsed / stepDuration).floor().clamp(0, totalSteps - 1);
        final double stepStartTime = trackPhaseStart + currentStep * stepDuration;
        final double stepFraction = ((progress - stepStartTime) / stepDuration).clamp(0.0, 1.0);
        // Step fraction curved so it fills smoothly across the duration of each track
        final double curvedStep = Curves.easeInOutCubic.transform(stepFraction);
        final double completedSteps = currentStep + curvedStep;
        scoreProgressFactor = (completedSteps / totalSteps).clamp(0.0, 1.0);
      }
    }

    final maxRating = _maxRating;

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
            // Top Archive Stamp Header
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
                    final centerOffsetY = (cardHeight - currentCoverSize) / 2 - 25;
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
                              // 1. Release Info Row: Bigger Docked Cover Slot + Left-Aligned Metadata
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Docked Cover Placeholder
                                  SizedBox(
                                    width: coverDockSize,
                                    height: coverDockSize,
                                  ),
                                  const SizedBox(width: 14),

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
                                            _buildFormatBadge(fontSize: 7.5),
                                            const SizedBox(height: 5),

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
                                            const SizedBox(height: 3),

                                            // Artist
                                            Text(
                                              'BY ${review.artistName.toUpperCase()}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.monoLabel(
                                                color: _primaryTextColor.withValues(alpha: 0.85),
                                                fontSize: 9.0,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),

                                            // Release Details (Year • Track Count • Total Duration)
                                            Text(
                                              _formattedReleaseDetails,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.monoLabel(
                                                color: _secondaryTextColor,
                                                fontSize: 8.0,
                                                fontWeight: FontWeight.w600,
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

                              // 2. Unique Overall Critic Score Banner (Above // TRACKLIST)
                              Transform.translate(
                                offset: Offset(headerSlideX, 0),
                                child: Opacity(
                                  opacity: headerOpacity,
                                  child: _buildOverallScoreBanner(scoreProgressFactor: scoreProgressFactor),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 3. Tracklist Section Header Label
                              Row(
                                children: [
                                  Text(
                                    '// TRACKLIST',
                                    style: AppTypography.monoLabel(
                                      color: _secondaryTextColor,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: _borderColor.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 3. Full Tracklist with Sequential Loading and Top-Rated Highlight
                              Expanded(
                                child: _buildDynamicTracklist(
                                  context: context,
                                  progress: progress,
                                  maxRating: maxRating,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // 4. Critic Signature Bar at bottom of card
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

                        // Centered Album Title & Artist Name during Zoom Phase (Fades out smoothly as it zooms out!)
                        if (curvedDock < 0.98)
                          Positioned(
                            left: 12,
                            right: 12,
                            top: currentY + currentCoverSize + 16,
                            child: Opacity(
                              opacity: (1.0 - curvedDock).clamp(0.0, 1.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildFormatBadge(fontSize: 8.0),
                                  const SizedBox(height: 8),
                                  Text(
                                    review.musicItemName.toUpperCase(),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.displaySmall(
                                      fontSize: 18,
                                      color: _primaryTextColor,
                                    ).copyWith(height: 1.15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'BY ${review.artistName.toUpperCase()}',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      color: _primaryTextColor.withValues(alpha: 0.85),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formattedReleaseDetails,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      color: _secondaryTextColor,
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Moving / Zooming Cover Artwork Layer (Bigger, NO White Border)
                        Positioned(
                          left: currentX,
                          top: currentY,
                          child: Container(
                            width: currentCoverSize,
                            height: currentCoverSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: isZoomPhase
                                      ? Colors.black.withValues(alpha: 0.7)
                                      : Colors.black.withValues(alpha: 0.45),
                                  offset: isZoomPhase ? const Offset(0, 10) : const Offset(3, 3),
                                  blurRadius: isZoomPhase ? 24 : 0,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
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

            // Bottom Barcode & Verification Footer
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

  Widget _buildDynamicTracklist({
    required BuildContext context,
    required double progress,
    required double? maxRating,
  }) {
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
                maxRating: maxRating,
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
                    maxRating: maxRating,
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
                    maxRating: maxRating,
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
    required double? maxRating,
  }) {
    // Sequential waterfall: each track loads fully before the next track begins!
    final int step = isDualColumn ? (index % ((totalCount / 2).ceil())) : index;
    final int totalSteps = isDualColumn ? ((totalCount / 2).ceil()) : math.max(1, totalCount);

    const double trackPhaseStart = 0.38;
    const double trackPhaseEnd = 0.88;
    final double stepDuration = (trackPhaseEnd - trackPhaseStart) / totalSteps;

    final double startTime = trackPhaseStart + step * stepDuration;
    final double rowAppearDuration = stepDuration * 0.32;
    final double lineAnimStart = startTime + stepDuration * 0.20;
    final double lineAnimDuration = stepDuration * 0.75;

    // Row entrance:
    final double itemProgress = progress < startTime
        ? 0.0
        : (progress > (startTime + rowAppearDuration)
            ? 1.0
            : ((progress - startTime) / rowAppearDuration));
    final double opacity = itemProgress.clamp(0.0, 1.0);
    final double slideY = 6.0 * (1.0 - Curves.easeOutCubic.transform(itemProgress));

    // Line fill animation (strictly Acid Lime as requested):
    final double lineProgress = progress < lineAnimStart
        ? 0.0
        : (progress > (lineAnimStart + lineAnimDuration)
            ? 1.0
            : ((progress - lineAnimStart) / lineAnimDuration));
    final double rating = item.rating ?? 0.0;
    final double ratingFactor = (rating / 10.0).clamp(0.0, 1.0);
    final double currentWidthFactor = ratingFactor * Curves.easeOutCubic.transform(lineProgress.clamp(0.0, 1.0));

    // End-of-animation border highlighting for Highest rated track ONLY (Lowest rated removed as requested):
    final bool isHighest = maxRating != null && item.rating == maxRating;

    final double highlightProgress = progress < 0.88
        ? 0.0
        : (progress > 0.96 ? 1.0 : ((progress - 0.88) / 0.08));
    final double curvedHighlight = Curves.easeInOutCubic.transform(highlightProgress.clamp(0.0, 1.0));

    Color effectiveBorderColor = _borderColor.withValues(alpha: 0.35);
    double effectiveBorderWidth = 1.0;

    if (isHighest) {
      effectiveBorderColor = Color.lerp(
        _borderColor.withValues(alpha: 0.35),
        AppColors.acidLime,
        curvedHighlight,
      )!;
      effectiveBorderWidth = 1.0 + 0.5 * curvedHighlight;
    }

    return Transform.translate(
      offset: Offset(0, slideY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: _cardBackground,
            border: Border.all(
              color: effectiveBorderColor,
              width: effectiveBorderWidth,
            ),
            borderRadius: BorderRadius.circular(1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Track Info Bar (Compact text sizing to maximize breathing room)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDualColumn ? 5 : 6,
                  vertical: isDualColumn ? 2.0 : 2.5,
                ),
                child: Row(
                  children: [
                    // Index
                    SizedBox(
                      width: isDualColumn ? 14 : 16,
                      child: Text(
                        item.trackNumber.toString().padLeft(2, '0'),
                        style: AppTypography.monoLabel(
                          color: _secondaryTextColor,
                          fontSize: isDualColumn ? 7.0 : 7.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: isDualColumn ? 4 : 5),

                    // Title (Adjusted text size so there is ample room)
                    Expanded(
                      child: Text(
                        item.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel(
                          color: _primaryTextColor,
                          fontSize: isDualColumn ? 7.0 : 7.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (!isDualColumn && item.formattedDuration.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 30,
                        child: Text(
                          item.formattedDuration,
                          textAlign: TextAlign.right,
                          style: AppTypography.monoLabel(
                            color: _secondaryTextColor.withValues(alpha: 0.65),
                            fontSize: 7.0,
                          ),
                        ),
                      ),
                    ],

                    SizedBox(width: isDualColumn ? 4 : 5),

                    // Track Score with Iconic Sparkle Sign (Clean Acid Lime)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.rating != null) ...[
                          RatingSpikeSign(
                            rating: item.rating!,
                            size: isDualColumn ? 7.0 : 8.5,
                            color: AppColors.acidLime,
                          ),
                          SizedBox(width: isDualColumn ? 2.0 : 3.0),
                        ],
                        Text(
                          item.scoreFormatted,
                          style: AppTypography.monoBadge(
                            color: item.rating != null ? AppColors.acidLime : _secondaryTextColor.withValues(alpha: 0.5),
                            fontSize: isDualColumn ? 7.0 : 7.5,
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
