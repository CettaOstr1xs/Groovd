import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';

class MusicDetailScreen extends ConsumerWidget {
  final MusicItem item;

  const MusicDetailScreen({super.key, required this.item});

  Future<void> _launchSpotify(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(musicItemDetailProvider(item.id));
    final activeItem = detailAsync.asData?.value ?? item;

    final reviewsAsync = ref.watch(itemReviewsProvider(item.id));
    final avgScoreAsync = ref.watch(itemAverageScoreProvider(item.id));
    final reviewCountAsync = ref.watch(itemReviewCountProvider(item.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          item.isAlbum ? 'ALBUM ARCHIVE' : 'TRACK ARCHIVE',
          style: AppTypography.monoLabel(fontSize: 11),
        ),
        actions: [
          if (item.externalSpotifyUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 20),
              tooltip: 'Open in Spotify',
              onPressed: () => _launchSpotify(item.externalSpotifyUrl),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: BrutalistButton(
                  label: '+ LOG YOUR REVIEW',
                  icon: Icons.rate_review_outlined,
                  backgroundColor: AppColors.acidLime,
                  textColor: AppColors.pureBlack,
                  isFullWidth: true,
                  onPressed: () => WriteReviewModal.show(context, activeItem),
                ),
              ),
              if ((activeItem.externalSpotifyUrl.isNotEmpty ? activeItem.externalSpotifyUrl : item.externalSpotifyUrl).isNotEmpty) ...[
                const SizedBox(width: 12),
                BrutalistButton(
                  label: 'SPOTIFY',
                  icon: Icons.play_arrow,
                  backgroundColor: AppColors.surfaceElevated,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.border,
                  onPressed: () => _launchSpotify(activeItem.externalSpotifyUrl.isNotEmpty ? activeItem.externalSpotifyUrl : item.externalSpotifyUrl),
                ),
              ],
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Typographic Hero Poster Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta zine breadcrumb
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeItem.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          activeItem.isAlbum ? 'LP // ALBUM' : 'SINGLE // TRACK',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'REL. ${activeItem.formattedYear}',
                        style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                      ),
                      if (activeItem.trackCount > 1) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${activeItem.trackCount} TRACKS',
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                      if (activeItem.formattedDuration.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${activeItem.formattedDuration}',
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Giant Exaggerated Album / Song Title
                  Text(
                    activeItem.name.toUpperCase(),
                    style: AppTypography.displayMassive(),
                  ),

                  const SizedBox(height: 6),

                  // Artist Name
                  Text(
                    'BY ${activeItem.artist.toUpperCase()}',
                    style: AppTypography.headline(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 20),

                  // Album Artwork with Brutalist framing
                  Center(
                    child: AlbumArtCard(
                      imageUrl: activeItem.coverUrl,
                      size: 240,
                    ),
                  ),

                  if (activeItem.genres.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: activeItem.genres.map((g) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            g.toUpperCase(),
                            style: AppTypography.monoBadge(color: AppColors.textSecondary, fontSize: 9),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Giant Community Score Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: avgScoreAsync.when(
                data: (score) {
                  final count = reviewCountAsync.value ?? 0;
                  return GiantScoreBadge(score: score, reviewCount: count);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.acidLime),
                ),
                error: (err, stack) => const GiantScoreBadge(score: 0.0),
              ),
            ),

            // Tracklist Section (for Albums)
            if (activeItem.tracks.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TRACKLIST [${activeItem.tracks.length}]',
                      style: AppTypography.monoLabel(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'DURATION',
                      style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeItem.tracks.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.borderSubtle,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final track = activeItem.tracks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            track.trackNumber.toString().padLeft(2, '0'),
                            style: AppTypography.monoBadge(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.name,
                                style: AppTypography.bodyLarge(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (track.artist.isNotEmpty && track.artist != activeItem.artist)
                                Text(
                                  track.artist,
                                  style: AppTypography.bodySmall(),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          track.formattedDuration,
                          style: AppTypography.monoLabel(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else if (item.isAlbum && detailAsync.isLoading) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: AppColors.acidLime, strokeWidth: 2.5),
                  ),
                ),
              ),
            ],

            // Community Reviews Section
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CRITICAL REVIEWS',
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  InkWell(
                    onTap: () => WriteReviewModal.show(context, item),
                    child: Text(
                      '+ WRITE YOURS',
                      style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            reviewsAsync.when(
              data: (reviews) {
                if (reviews.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.rate_review_outlined, size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'NO REVIEWS LOGGED YET',
                          style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Be the first critic to leave your mark and score this release.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        BrutalistButton(
                          label: 'BE THE FIRST TO REVIEW',
                          onPressed: () => WriteReviewModal.show(context, item),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ReviewCard(
                      review: review,
                      showItemHeader: false,
                      onLike: () {
                        ref.read(reviewControllerProvider).likeReview(review.id);
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.acidLime),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Failed to load reviews: $err'),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
