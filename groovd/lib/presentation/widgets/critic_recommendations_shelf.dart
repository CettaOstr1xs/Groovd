import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/critic_recommendation_item.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/critic_recommendation_modal.dart';
import 'package:groovd/state/critic_recommendations_provider.dart';

/// Neo-brutalist horizontal recommendations shelf on the Dispatch dashboard.
/// Completely hidden until the user has logged at least 5 album/EP reviews.
class CriticRecommendationsShelf extends ConsumerWidget {
  const CriticRecommendationsShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(criticRecommendationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CRITIC\'S RADAR',
                        style: AppTypography.displaySmall(),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: 6),
                        color: AppColors.acidLime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI PICKS // BASED ON YOUR CANON',
                    style: AppTypography.monoLabel(
                      color: AppColors.acidLime,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: recState.isLoading
                    ? null
                    : () {
                        ref
                            .read(criticRecommendationsProvider.notifier)
                            .refreshRecommendations(forceReroll: true);
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.border, width: 1.5),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.pureBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (recState.isLoading)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.acidLime,
                          ),
                        )
                      else
                        const Icon(Icons.refresh, size: 12, color: AppColors.acidLime),
                      const SizedBox(width: 4),
                      Text(
                        'REROLL',
                        style: AppTypography.monoBadge(
                          color: AppColors.acidLime,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal Shelf Cards
        SizedBox(
          height: 275,
          child: Builder(
            builder: (context) {
              if (recState.items.isEmpty) {
                final isBusy = recState.isLoading;
                final statusMessage = isBusy
                    ? '> GROOVD_AI // GENERATING PICKS...'
                    : '> GROOVD_AI // ${recState.errorMessage ?? 'OFFLINE'} // TAP REROLL TO RETRY';

                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.pureBlack,
                          offset: Offset(3, 3),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isBusy)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.acidLime,
                            ),
                          )
                        else
                          const Icon(
                            Icons.signal_cellular_connected_no_internet_4_bar,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            statusMessage,
                            style: AppTypography.monoLabel(
                              color: isBusy ? AppColors.textPrimary : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recState.items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final rec = recState.items[index];
                  return _RecommendationCard(rec: rec)
                      .animate()
                      .fadeIn(
                        duration: 350.ms,
                        delay: (index * 50).ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideX(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 28),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CriticRecommendationItem rec;

  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final heroTag = 'radar_${rec.item.id}';

    return InkWell(
      onTap: () {
        CriticRecommendationModal.show(context, recommendation: rec);
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(2),
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
            AlbumArtCard(
              imageUrl: rec.item.coverUrl,
              musicItem: rec.item,
              width: 155,
              height: 155,
              showShadow: false,
              heroTag: heroTag,
            ),
            const SizedBox(height: 8),
            Text(
              rec.item.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.displaySmall(fontSize: 13),
            ),
            Text(
              rec.item.artist.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (rec.reasoning.isNotEmpty)
              Text(
                rec.reasoning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.monoLabel(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
