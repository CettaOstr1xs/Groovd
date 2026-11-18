import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/critic_recommendation_item.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/scramble_text.dart';

/// Neo-brutalist Option A modal popup: The Vinyl Slipcase & CRT Terminal Dossier.
/// Features a physical vinyl record peeking out, genre chips, and a 2000ms cyberpunk
/// teletype text scramble decode of the AI Critic's reasoning.
class CriticRecommendationModal extends StatelessWidget {
  final CriticRecommendationItem recommendation;

  const CriticRecommendationModal({
    super.key,
    required this.recommendation,
  });

  /// Displays the Option A vinyl slipcase elaboration modal.
  static Future<void> show(
    BuildContext context, {
    required CriticRecommendationItem recommendation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CriticRecommendationModal(recommendation: recommendation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = recommendation.item;
    final heroTag = 'slipcase_${item.id}';

    // Extract up to 3 genres, falling back to vibeTag or release type
    final displayGenres = <String>[];
    if (item.genres.isNotEmpty) {
      displayGenres.addAll(item.genres.take(3));
    } else if (recommendation.vibeTag.isNotEmpty) {
      displayGenres.add(recommendation.vibeTag.replaceAll('#', ''));
    } else {
      displayGenres.add(item.typeBadgeLabel);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 40, 14, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.pureBlack, width: 2.5),
        borderRadius: BorderRadius.zero,
        boxShadow: const [
          BoxShadow(
            color: AppColors.acidLime,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(7, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Industrial Slipcase Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: AppColors.pureBlack,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 8),
                    color: AppColors.acidLime,
                  ),
                  Text(
                    'CRITIC DISPATCH // CANON RECOM',
                    style: AppTypography.monoLabel(
                      color: AppColors.acidLime,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 2.0, color: AppColors.pureBlack),

            // 2. Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Physical Vinyl Slipcase Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Vinyl Record + Sleeve Jacket Stack
                        SizedBox(
                          width: 145,
                          height: 110,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              // Peeking Vinyl Disc
                              Positioned(
                                left: 35,
                                child: _VinylRecordDisc(
                                  size: 100,
                                  formatLabel: item.typeBadgeLabel,
                                ),
                              ),
                              // Album Jacket on top
                              Positioned(
                                left: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.pureBlack, width: 2.0),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.pureBlack,
                                        offset: Offset(3, 3),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: AlbumArtCard(
                                    imageUrl: item.coverUrl,
                                    musicItem: item,
                                    width: 100,
                                    height: 100,
                                    showShadow: false,
                                    heroTag: heroTag,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Title, Artist, Year & Format Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name.toUpperCase(),
                                style: AppTypography.displaySmall(fontSize: 16),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.artist.toUpperCase(),
                                style: AppTypography.bodyMedium(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceCard,
                                      border: Border.all(color: AppColors.border, width: 1.0),
                                    ),
                                    child: Text(
                                      item.typeBadgeLabel,
                                      style: AppTypography.monoBadge(
                                        color: AppColors.acidLime,
                                        fontSize: 8.5,
                                      ),
                                    ),
                                  ),
                                  if (item.formattedYear.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      item.formattedYear,
                                      style: AppTypography.monoLabel(
                                        color: AppColors.textSecondary,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Genre Chips Strip
                    if (displayGenres.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: displayGenres.map((g) {
                          final cleanTag = g.trim().toUpperCase();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              border: Border.all(color: AppColors.border, width: 1.0),
                            ),
                            child: Text(
                              '#$cleanTag',
                              style: AppTypography.monoBadge(
                                color: AppColors.cyberCyan,
                                fontSize: 9.0,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(height: 1, thickness: 1.0, color: AppColors.border),
                    const SizedBox(height: 12),

                    // 3. Analog CRT Teletype Monitor Box
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF06080A),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Terminal Status Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            color: const Color(0xFF101418),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.acidLime,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '> GROOVD_AI // TASTE_DECODE_LOG',
                                  style: AppTypography.monoLabel(
                                    color: AppColors.acidLime,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 1, thickness: 1.0, color: AppColors.border),

                          // Terminal Screen Scramble Text
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: ScrambleText(
                              text: recommendation.reasoning,
                              duration: const Duration(milliseconds: 2000),
                              style: AppTypography.monoLabel(
                                color: AppColors.textPrimary,
                                fontSize: 11.5,
                              ).copyWith(height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 4. Split Action Buttons
                    Row(
                      children: [
                        // Primary Inspect Button
                        Expanded(
                          flex: 7,
                          child: BrutalistButton(
                            label: 'INSPECT RECORD IN ARCHIVE →',
                            backgroundColor: AppColors.acidLime,
                            textColor: AppColors.pureBlack,
                            onPressed: () {
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => MusicDetailScreen(
                                    item: item,
                                    heroTag: 'detail_${item.id}',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Secondary Dismiss Button
                        Expanded(
                          flex: 3,
                          child: BrutalistButton(
                            label: 'DISMISS ✕',
                            backgroundColor: AppColors.surfaceCard,
                            textColor: AppColors.textPrimary,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stylized vinyl record disc peeking out with concentric physical grooves.
class _VinylRecordDisc extends StatelessWidget {
  final double size;
  final String formatLabel;

  const _VinylRecordDisc({
    required this.size,
    required this.formatLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0E1012),
        border: Border.all(color: AppColors.pureBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(2, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Center(
        // Outer concentric groove
        child: Container(
          width: size * 0.82,
          height: size * 0.82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
          ),
          child: Center(
            // Mid groove
            child: Container(
              width: size * 0.64,
              height: size * 0.64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.0),
              ),
              child: Center(
                // Center Spindle Label
                child: Container(
                  width: size * 0.36,
                  height: size * 0.36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.acidLime,
                  ),
                  child: Center(
                    // Center Spindle Hole
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.pureBlack,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
