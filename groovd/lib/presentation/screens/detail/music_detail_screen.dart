import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/presentation/screens/lists/create_edit_list_modal.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'package:groovd/state/wishlist_provider.dart';

class MusicDetailScreen extends ConsumerWidget {
  final MusicItem item;
  final String? heroTag;

  const MusicDetailScreen({super.key, required this.item, this.heroTag});

  void _showAddToListModal(BuildContext context, WidgetRef ref, MusicItem musicItem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final lists = ref.watch(userListsProvider);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.cyberCyan, width: 2.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ADD TO CURATED LIST', style: AppTypography.displaySmall()),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a list to save "${musicItem.name.toUpperCase()}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  if (lists.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'YOU HAVE NO CURATED LISTS YET',
                          style: AppTypography.monoBadge(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lists.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          final inList = list.items.any((i) => i.id == musicItem.id);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              list.title.toUpperCase(),
                              style: AppTypography.bodyLarge(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              list.summaryLabel.toUpperCase(),
                              style: AppTypography.monoLabel(fontSize: 10, color: AppColors.cyberCyan),
                            ),
                            trailing: inList
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'IN LIST',
                                      style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 9),
                                    ),
                                  )
                                : BrutalistButton(
                                    label: '+ ADD',
                                    isSmall: true,
                                    backgroundColor: AppColors.cyberCyan,
                                    textColor: AppColors.pureBlack,
                                    borderColor: AppColors.pureBlack,
                                    onPressed: () async {
                                      Navigator.of(ctx).pop();
                                      final added = await ref
                                          .read(userListsProvider.notifier)
                                          .addItemToList(list.id, musicItem);
                                      if (context.mounted && added) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'ADDED TO "${list.title.toUpperCase()}"',
                                              style: AppTypography.monoBadge(color: AppColors.pureBlack),
                                            ),
                                            backgroundColor: AppColors.cyberCyan,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  BrutalistButton(
                    label: '+ CREATE NEW LIST & ADD',
                    icon: Icons.add,
                    isFullWidth: true,
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.cyberCyan,
                    borderColor: AppColors.cyberCyan,
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      final created = await CreateEditListModal.show(context);
                      if (created != null && context.mounted) {
                        await ref.read(userListsProvider.notifier).addItemToList(created.id, musicItem);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'CREATED & ADDED TO "${created.title.toUpperCase()}"',
                                style: AppTypography.monoBadge(color: AppColors.pureBlack),
                              ),
                              backgroundColor: AppColors.cyberCyan,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchSpotify(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('NO SPOTIFY LINK AVAILABLE', style: AppTypography.monoLabel(color: AppColors.textPrimary)),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallback && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text('COULD NOT OPEN SPOTIFY', style: AppTypography.monoLabel(color: AppColors.vermillion)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text('FAILED TO OPEN SPOTIFY: $err', style: AppTypography.monoLabel(color: AppColors.vermillion)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(musicItemDetailProvider(ItemQuery(id: item.id, type: item.type)));
    final fetched = detailAsync.asData?.value;
    final activeItem = fetched != null
        ? fetched.copyWith(
            coverUrl: fetched.coverUrl.isNotEmpty ? fetched.coverUrl : item.coverUrl,
          )
        : item;

    final reviewsAsync = ref.watch(itemReviewsProvider(item.id));
    final avgScoreAsync = ref.watch(itemAverageScoreProvider(item.id));
    final reviewCountAsync = ref.watch(itemReviewCountProvider(item.id));
    final isWishlisted = ref.watch(isInWishlistProvider(activeItem.id));

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
          IconButton(
            icon: const Icon(
              Icons.playlist_add,
              color: AppColors.cyberCyan,
              size: 22,
            ),
            tooltip: 'Add to custom list',
            onPressed: () => _showAddToListModal(context, ref, activeItem),
          ),
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.bookmark : Icons.bookmark_border,
              color: isWishlisted ? AppColors.acidLime : AppColors.textSecondary,
              size: 22,
            ),
            tooltip: isWishlisted ? 'Remove from wantlist' : 'Add to wantlist',
            onPressed: () async {
              HapticFeedback.lightImpact();
              final added = await ref.read(wishlistProvider.notifier).toggleItem(activeItem);
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      added ? 'ADDED TO CRITIC WANTLIST' : 'REMOVED FROM WANTLIST',
                      style: AppTypography.monoLabel(
                        color: added ? AppColors.acidLime : AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          if (item.externalSpotifyUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppColors.textSecondary, size: 20),
              tooltip: 'Open in Spotify',
              onPressed: () => _launchSpotify(context, item.externalSpotifyUrl),
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
              const SizedBox(width: 10),
              // Tactile Wishlist Bookmark Button
              InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final added = await ref.read(wishlistProvider.notifier).toggleItem(activeItem);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          added ? 'ADDED TO CRITIC WANTLIST' : 'REMOVED FROM WANTLIST',
                          style: AppTypography.monoLabel(
                            color: added ? AppColors.acidLime : AppColors.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isWishlisted ? AppColors.acidLime.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                    border: Border.all(
                      color: isWishlisted ? AppColors.acidLime : AppColors.border,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Icon(
                      isWishlisted ? Icons.bookmark : Icons.bookmark_border,
                      color: isWishlisted ? AppColors.acidLime : AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if ((activeItem.externalSpotifyUrl.isNotEmpty ? activeItem.externalSpotifyUrl : item.externalSpotifyUrl).isNotEmpty) ...[
                const SizedBox(width: 10),
                BrutalistButton(
                  label: 'SPOTIFY',
                  icon: Icons.play_arrow,
                  backgroundColor: AppColors.surfaceElevated,
                  textColor: AppColors.textPrimary,
                  borderColor: AppColors.border,
                  onPressed: () => _launchSpotify(context, activeItem.externalSpotifyUrl.isNotEmpty ? activeItem.externalSpotifyUrl : item.externalSpotifyUrl),
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
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
                      Text(
                        'REL. ${activeItem.formattedYear}',
                        style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                      ),
                      if (activeItem.trackCount > 1)
                        Text(
                          '• ${activeItem.trackCount} TRACKS',
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                        ),
                      if (activeItem.formattedDuration.isNotEmpty)
                        Text(
                          '• ${activeItem.formattedDuration}',
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                        ),
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
                      heroTag: heroTag ?? 'cover_${item.id}',
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
                  return GiantScoreBadge(score: score, reviewCount: count)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                      );
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
                  return InkWell(
                    onTap: () {
                      final trackItem = MusicItem(
                        id: track.id,
                        name: track.name,
                        artist: track.artist.isNotEmpty ? track.artist : activeItem.artist,
                        type: MusicType.song,
                        coverUrl: activeItem.coverUrl,
                        releaseDate: activeItem.releaseDate,
                        genres: activeItem.genres,
                        durationMs: track.durationMs,
                        previewUrl: track.previewUrl,
                        externalSpotifyUrl: track.id.isNotEmpty ? 'https://open.spotify.com/track/${track.id}' : '',
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MusicDetailScreen(
                            item: trackItem,
                            heroTag: 'track_${track.id}',
                          ),
                        ),
                      );
                    },
                    child: Padding(
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
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: 250.ms,
                        delay: (index * 30).ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
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
                          duration: 300.ms,
                          delay: (index * 45).ms,
                          curve: Curves.easeOutCubic,
                        )
                        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
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

            // More by Artist Exploration Section
            _MoreByArtistSection(item: item),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MoreByArtistSection extends ConsumerWidget {
  final MusicItem item;

  const _MoreByArtistSection({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moreByArtistAsync = ref.watch(
      moreByArtistProvider(
        MoreByArtistQuery(artist: item.artist, currentItemId: item.id),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MORE BY ${item.artist.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoLabel(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              moreByArtistAsync.when(
                data: (items) => items.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${items.length} ${items.length == 1 ? 'PIECE' : 'PIECES'}',
                          style: AppTypography.monoBadge(
                            color: AppColors.cyberCyan,
                            fontSize: 9,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        moreByArtistAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.album_outlined, size: 20, color: AppColors.textMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'NO OTHER RELEASES ARCHIVED YET',
                        style: AppTypography.monoBadge(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final moreItem = items[index];
                  return _MoreByArtistCard(item: moreItem)
                      .animate()
                      .fadeIn(
                        duration: 300.ms,
                        delay: (index * 45).ms,
                        curve: Curves.easeOutCubic,
                      )
                      .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.cyberCyan, strokeWidth: 2),
              ),
            ),
          ),
          error: (err, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MoreByArtistCard extends ConsumerWidget {
  final MusicItem item;

  const _MoreByArtistCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(itemAverageScoreProvider(item.id));
    final tag = 'more_${item.id}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item, heroTag: tag)),
        );
      },
      child: Container(
        width: 142,
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
              width: 122,
              height: 122,
              showShadow: false,
              heroTag: tag,
            ),
            const SizedBox(height: 8),
            Text(
              item.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.displaySmall(fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              item.artist.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: AppColors.textMuted, fontSize: 10),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: item.isAlbum
                        ? AppColors.acidLime.withValues(alpha: 0.15)
                        : AppColors.cyberCyan.withValues(alpha: 0.15),
                    border: Border.all(
                      color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: Text(
                    item.isAlbum ? 'LP' : 'TRACK',
                    style: AppTypography.monoBadge(
                      color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                      fontSize: 8,
                    ),
                  ),
                ),
                if (item.formattedYear.isNotEmpty)
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

