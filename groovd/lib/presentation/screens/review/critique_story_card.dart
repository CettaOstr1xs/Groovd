import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/review.dart';
import '../../widgets/album_art_card.dart';
import '../../widgets/critic_avatar.dart';

enum StoryTheme {
  darkMatrix,
  acidBrutal,
  cyberCyan,
  zinePaper,
}

enum StoryLayout {
  fullCritique,
  posterCard,
}

class CritiqueStoryCard extends StatelessWidget {
  final Review review;
  final StoryTheme theme;
  final StoryLayout layout;
  final String? avatarPath;

  const CritiqueStoryCard({
    super.key,
    required this.review,
    this.theme = StoryTheme.darkMatrix,
    this.layout = StoryLayout.fullCritique,
    this.avatarPath,
  });

  Color get _backgroundColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF0C0D0E);
      case StoryTheme.acidBrutal:
        return AppColors.acidLime;
      case StoryTheme.cyberCyan:
        return const Color(0xFF07181F);
      case StoryTheme.zinePaper:
        return const Color(0xFFF4EFE6);
    }
  }

  Color get _cardBackground {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF161719);
      case StoryTheme.acidBrutal:
        return const Color(0xFF000000);
      case StoryTheme.cyberCyan:
        return const Color(0xFF0E222A);
      case StoryTheme.zinePaper:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get _primaryTextColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
      case StoryTheme.cyberCyan:
        return const Color(0xFFFFFFFF);
      case StoryTheme.acidBrutal:
        return const Color(0xFFFFFFFF);
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  Color get _secondaryTextColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF9E9E9E);
      case StoryTheme.acidBrutal:
        return const Color(0xFFBDBDBD);
      case StoryTheme.cyberCyan:
        return const Color(0xFF7CA6B5);
      case StoryTheme.zinePaper:
        return const Color(0xFF666666);
    }
  }

  Color get _accentColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return AppColors.acidLime;
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
        return const Color(0xFF2A2A2A);
      case StoryTheme.acidBrutal:
        return const Color(0xFF000000);
      case StoryTheme.cyberCyan:
        return AppColors.cyberCyan.withValues(alpha: 0.4);
      case StoryTheme.zinePaper:
        return const Color(0xFF111111);
    }
  }

  Color get _outerFrameColor {
    switch (theme) {
      case StoryTheme.darkMatrix:
        return const Color(0xFF1D1F21);
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
    final isFull = layout == StoryLayout.fullCritique;

    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(color: _outerFrameColor, width: 3.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar Stamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: Text(
                          'GROOVD',
                          style: AppTypography.monoBadge(
                            color: theme == StoryTheme.acidBrutal ? Colors.black : (theme == StoryTheme.zinePaper ? Colors.white : Colors.black),
                            fontSize: 10,
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
                            fontSize: 9,
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
                    fontSize: 9,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Main Hero Critique Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: _borderColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: theme == StoryTheme.acidBrutal ? Colors.black : Colors.black54,
                      offset: const Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Centered Artwork sitting at the Middle Top of the Card
                    Center(
                      child: AlbumArtCard(
                        imageUrl: review.coverUrl,
                        size: isFull ? 96 : 124,
                        showShadow: true,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Centered Release Header
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                              style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 8),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            review.musicItemName.toUpperCase(),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displaySmall(
                              fontSize: isFull ? 15 : 18,
                              color: _primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BY ${review.artistName.toUpperCase()}',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel(
                              color: _secondaryTextColor,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Big Score Highlight Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.12),
                        border: Border.all(color: _accentColor, width: 1.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CRITIC SCORE',
                                  style: AppTypography.monoLabel(
                                    color: _secondaryTextColor,
                                    fontSize: 8,
                                  ),
                                ),
                                Text(
                                  review.scoreTierLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.monoBadge(
                                    color: _accentColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${review.scoreFormatted}/10',
                              style: AppTypography.scoreLarge(
                                color: _accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Headline
                    if (review.headline.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: _accentColor, width: 3.5),
                          ),
                        ),
                        child: Text(
                          '“${review.headline.toUpperCase()}”',
                          maxLines: isFull ? 2 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.headline(
                            fontSize: isFull ? 14 : 16,
                            color: _primaryTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Body commentary (Full Critique mode only)
                    if (isFull && review.body.isNotEmpty) ...[
                      Expanded(
                        child: Text(
                          review.body,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(
                            color: _secondaryTextColor,
                            fontSize: 11,
                          ).copyWith(height: 1.45),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                    ],

                    // Tags (if available)
                    if (review.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: review.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: _cardBackground,
                              border: Border.all(color: _borderColor),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: AppTypography.monoBadge(
                                color: _accentColor,
                                fontSize: 8,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Divider(color: _borderColor, height: 1),
                    const SizedBox(height: 10),

                    // Critic Signature Row
                    Row(
                      children: [
                        CriticAvatar(
                          avatarPath: (avatarPath != null && avatarPath!.isNotEmpty)
                              ? avatarPath
                              : review.userAvatarUrl,
                          fallbackInitial: review.userName,
                          size: 28,
                          borderRadius: 2,
                          borderWidth: 1.5,
                          borderColor: Colors.black,
                          fallbackBgColor: _accentColor,
                          fallbackTextColor: Colors.black,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monoLabel(
                                  fontSize: 10,
                                  color: _primaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                review.userHandle,
                                style: AppTypography.monoLabel(
                                  fontSize: 8,
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
            ),

            const SizedBox(height: 16),

            // Bottom Barcode / Scan Stamp
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
                    fontSize: 10,
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
}
