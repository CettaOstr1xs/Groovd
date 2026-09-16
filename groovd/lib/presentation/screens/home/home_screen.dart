import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
import 'package:groovd/presentation/widgets/marquee_banner.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/search/search_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAlbumsAsync = ref.watch(trendingAlbumsProvider);
    final hotTracksAsync = ref.watch(hotTracksProvider);
    final recentReviewsAsync = ref.watch(recentReviewsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.acidLime,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(trendingAlbumsProvider);
            ref.invalidate(hotTracksProvider);
            ref.invalidate(recentReviewsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial Zine Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GROOVD // ARCHIVE',
                            style: AppTypography.monoLabel(
                              color: AppColors.acidLime,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'ISS. 2026 // VOL. 01',
                            style: AppTypography.monoLabel(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'GROOVD',
                        style: AppTypography.displayMassive(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RATE SONGS & ALBUMS. UNCOMPROMISING CRITIQUE.',
                        style: AppTypography.monoLabel(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.06, end: 0, curve: Curves.easeOutCubic),

                // Marquee Banner
                const MarqueeBanner(
                  text: 'EXAGGERATED SOUNDS ★ HONEST REVIEWS ★ COMMUNITY RATINGS ★ SPOTIFY SYNC ★ 10/10 MASTERPIECES',
                ),

                const SizedBox(height: 18),

                // Hero Featured Album Banner
                trendingAlbumsAsync.when(
                  data: (albums) {
                    if (albums.isEmpty) return const SizedBox.shrink();
                    final featured = albums.first;
                    return _FeaturedHeroBanner(item: featured)
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                        .scale(
                          begin: const Offset(0.97, 0.97),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                        );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.acidLime),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 24),

                // Trending Albums Header & Shelf
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRENDING ALBUMS',
                        style: AppTypography.displaySmall(),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                        child: Text(
                          'EXPLORE ALL →',
                          style: AppTypography.monoBadge(
                            color: AppColors.acidLime,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Album Scroll
                SizedBox(
                  height: 245,
                  child: trendingAlbumsAsync.when(
                    data: (albums) {
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: albums.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return _AlbumPosterCard(item: album)
                              .animate()
                              .fadeIn(
                                duration: 350.ms,
                                delay: (index * 60).ms,
                                curve: Curves.easeOutCubic,
                              )
                              .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.acidLime),
                    ),
                    error: (err, stack) => const SizedBox.shrink(),
                  ),
                ),

                const SizedBox(height: 28),

                // Hot Tracks Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'HOT TRACKS IN ROTATION',
                    style: AppTypography.displaySmall(),
                  ),
                ),
                const SizedBox(height: 12),

                hotTracksAsync.when(
                  data: (tracks) {
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tracks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return _HotTrackTile(track: track, rank: index + 1)
                            .animate()
                            .fadeIn(
                              duration: 300.ms,
                              delay: (index * 45).ms,
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.acidLime),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 32),

                // Recent Community Reviews Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'COMMUNITY DISPATCH',
                        style: AppTypography.displaySmall(),
                      ),
                      Text(
                        'LIVE CRITIQUE',
                        style: AppTypography.monoLabel(
                          color: AppColors.electricPink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                recentReviewsAsync.when(
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No reviews yet.'),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: reviews.take(5).length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return ReviewCard(
                          review: review,
                          showItemHeader: true,
                          onLike: () {
                            ref.read(reviewControllerProvider).likeReview(review.id);
                          },
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReviewDetailScreen(review: review),
                              ),
                            );
                          },
                        )
                            .animate()
                            .fadeIn(
                              duration: 350.ms,
                              delay: (index * 50).ms,
                              curve: Curves.easeOutCubic,
                            )
                            .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.acidLime),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedHeroBanner extends ConsumerWidget {
  final MusicItem item;

  const _FeaturedHeroBanner({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(itemAverageScoreProvider(item.id));
    final tag = 'featured_${item.id}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MusicDetailScreen(item: item, heroTag: tag),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.borderBold, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.acidLime,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'FEATURED OF THE WEEK',
                    style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                  ),
                ),
                scoreAsync.when(
                  data: (s) => s > 0 ? GiantScoreBadge(score: s, compact: true) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                AlbumArtCard(
                  imageUrl: item.coverUrl,
                  size: 110,
                  heroTag: tag,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.displayHero(),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BY ${item.artist.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      BrutalistButton(
                        label: 'REVIEW // VIEW',
                        isSmall: true,
                        backgroundColor: AppColors.acidLime,
                        textColor: AppColors.pureBlack,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MusicDetailScreen(item: item, heroTag: tag),
                            ),
                          );
                        },
                      ),
                    ],
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

class _AlbumPosterCard extends ConsumerWidget {
  final MusicItem item;

  const _AlbumPosterCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(itemAverageScoreProvider(item.id));
    final tag = 'poster_${item.id}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item, heroTag: tag)),
        );
      },
      child: Container(
        width: 145,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtCard(
              imageUrl: item.coverUrl,
              width: 125,
              height: 125,
              showShadow: false,
              heroTag: tag,
            ),
            const SizedBox(height: 8),
            Text(
              item.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.displaySmall(fontSize: 14),
            ),
            Text(
              item.artist.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: AppColors.textMuted),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.formattedYear,
                  style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
                ),
                scoreAsync.when(
                  data: (s) => s > 0 ? GiantScoreBadge(score: s, compact: true) : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HotTrackTile extends ConsumerWidget {
  final MusicItem track;
  final int rank;

  const _HotTrackTile({required this.track, required this.rank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(itemAverageScoreProvider(track.id));
    final tag = 'track_${track.id}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: track, heroTag: tag)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              rank.toString().padLeft(2, '0'),
              style: AppTypography.scoreMedium(color: AppColors.acidLime),
            ),
            const SizedBox(width: 14),
            AlbumArtCard(
              imageUrl: track.coverUrl,
              size: 48,
              showShadow: false,
              heroTag: tag,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline(color: AppColors.textPrimary),
                  ),
                  Text(
                    track.artist.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            scoreAsync.when(
              data: (s) => s > 0 ? GiantScoreBadge(score: s, compact: true) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
