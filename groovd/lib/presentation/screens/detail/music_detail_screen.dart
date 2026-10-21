import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/presentation/widgets/artwork_zoom_viewer.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/presentation/screens/artist/artist_detail_screen.dart';
import 'package:groovd/presentation/screens/lists/create_edit_list_modal.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
import 'package:groovd/presentation/widgets/rating_spike_sign.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/review/instagram_story_modal.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'package:groovd/state/user_profile_provider.dart';
import 'package:groovd/state/wishlist_provider.dart';

class MusicDetailScreen extends ConsumerWidget {
  final MusicItem item;
  final String? heroTag;
  final Review? initialReview;

  const MusicDetailScreen({
    super.key,
    required this.item,
    this.heroTag,
    this.initialReview,
  });

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
                          final inList = list.items.any((i) => i.id == musicItem.id || i.isSameWork(musicItem));

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


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(musicItemDetailProvider(ItemQuery(
      id: item.id,
      type: item.type,
      name: item.name,
      artist: item.artist,
    )));
    final fetched = detailAsync.asData?.value;
    final activeItem = fetched != null
        ? fetched.copyWith(
            coverUrl: fetched.coverUrl.isNotEmpty ? fetched.coverUrl : item.coverUrl,
            genres: fetched.genres.length > 1
                ? fetched.genres
                : (item.genres.isNotEmpty ? item.genres : fetched.genres),
          )
        : item;

    final reviewQuery = ItemReviewQuery.fromItem(activeItem);
    final reviewsAsync = ref.watch(itemReviewsProvider(reviewQuery));
    final currentUserId = ref.watch(currentUserIdProvider);

    final userReviews = ref.watch(userReviewsProvider(currentUserId)).asData?.value ?? const [];
    final fallbackUserReviews = currentUserId != 'user_me'
        ? (ref.watch(userReviewsProvider('user_me')).asData?.value ?? const [])
        : const <Review>[];
    final allUserReviews = [
      ?initialReview,
      ...userReviews,
      ...fallbackUserReviews,
    ];

    // 1. Resolve existing user review matching this music release
    // Check user's personal review archive first (instant & resilient across cross-catalog IDs)
    final userMatches = allUserReviews.where((r) {
      if ((r.musicItemId.isNotEmpty && r.musicItemId == activeItem.id) ||
          (r.musicItemId.isNotEmpty && r.musicItemId == item.id)) {
        return true;
      }
      return r.matchesItem(
            id: activeItem.id,
            name: activeItem.name,
            artist: activeItem.artist,
            type: activeItem.type.name,
          ) ||
          r.matchesItem(
            id: item.id,
            name: item.name,
            artist: item.artist,
            type: item.type.name,
          );
    }).toList();

    Review? existingUserReview = initialReview;
    if (existingUserReview == null && userMatches.isNotEmpty) {
      userMatches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      existingUserReview = userMatches.first;
    }
    existingUserReview ??= reviewsAsync.asData?.value
        .where((r) => r.userId == currentUserId || r.userId == 'user_me')
        .firstOrNull;

    final computedLogCount = userMatches.isNotEmpty
        ? userMatches.length
        : (initialReview != null ? 1 : 0);
    final providerLogCount = ref.watch(currentUserItemLogCountProvider(reviewQuery));
    final userLogCount = providerLogCount > computedLogCount ? providerLogCount : computedLogCount;
    final avgScoreAsync = ref.watch(itemAverageScoreProvider(reviewQuery));
    final reviewCountAsync = ref.watch(itemReviewCountProvider(reviewQuery));
    final isWishlisted = ref.watch(isItemInWishlistProvider(activeItem));
    final autoOverallScore = ref.watch(albumAutomaticOverallScoreProvider(activeItem));

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
          item.isEp ? 'EP ARCHIVE' : (item.isAlbum ? 'ALBUM ARCHIVE' : 'TRACK ARCHIVE'),
          style: AppTypography.monoLabel(fontSize: 11),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_stories,
              color: AppColors.acidLime,
              size: 20,
            ),
            tooltip: 'Share Scorecard to Story',
            onPressed: () {
              HapticFeedback.lightImpact();
              final profile = ref.read(userProfileProvider);
              final effectiveRating = autoOverallScore ?? existingUserReview?.rating ?? 8.5;
              final reviewToShare = existingUserReview ??
                  Review(
                    id: 'scorecard_${activeItem.id}',
                    musicItemId: activeItem.id,
                    musicItemName: activeItem.name,
                    artistName: activeItem.artist,
                    coverUrl: activeItem.coverUrl,
                    itemType: activeItem.isEp ? 'ep' : (activeItem.isSong ? 'song' : 'album'),
                    userId: profile.userId,
                    userName: profile.userName,
                    userHandle: profile.userHandle,
                    userAvatarUrl: profile.avatarPath,
                    rating: effectiveRating,
                    headline: '',
                    body: '',
                    createdAt: DateTime.now(),
                  );
              InstagramStoryModal.show(context, reviewToShare, musicItem: activeItem);
            },
          ),
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
              if (existingUserReview != null) ...[
                Expanded(
                  flex: 3,
                  child: BrutalistButton(
                    label: '+ LOG AGAIN',
                    icon: Icons.repeat,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    isFullWidth: true,
                    onPressed: () => WriteReviewModal.show(
                      context,
                      activeItem,
                      isLogAgain: true,
                      previousLogCount: userLogCount,
                      autoOverallScore: autoOverallScore,
                      initialRating: autoOverallScore ?? existingUserReview?.rating,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: BrutalistButton(
                    label: 'EDIT [${existingUserReview.rating.toStringAsFixed(1)}]',
                    icon: Icons.edit_note,
                    leading: RatingSpikeSign(
                      rating: existingUserReview.rating,
                      size: 14,
                      color: AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.textPrimary,
                    borderColor: AppColors.borderBold,
                    isFullWidth: true,
                    onPressed: () => WriteReviewModal.show(
                      context,
                      activeItem,
                      existingReview: existingUserReview,
                      autoOverallScore: autoOverallScore,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: BrutalistButton(
                    label: '+ LOG YOUR REVIEW',
                    icon: Icons.rate_review_outlined,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    isFullWidth: true,
                    onPressed: () => WriteReviewModal.show(
                      context,
                      activeItem,
                      autoOverallScore: autoOverallScore,
                      initialRating: autoOverallScore,
                    ),
                  ),
                ),
              ],
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
                          color: activeItem.typeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          activeItem.fullTypeLabel,
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                        ),
                      ),
                      if (activeItem.formattedReleaseDate.isNotEmpty)
                        Text(
                          'REL. ${activeItem.formattedReleaseDate}',
                          style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted),
                        )
                      else if (activeItem.formattedYear.isNotEmpty)
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

                  // Artist Name (Interactive Dossier Link)
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArtistDetailScreen(
                            artistIdOrName: activeItem.artist,
                            initialArtistName: activeItem.artist,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BY ${activeItem.artist.toUpperCase()}',
                            style: AppTypography.headline(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 14, color: AppColors.acidLime),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Album Artwork with Brutalist framing & Interactive Zoom
                  Center(
                    child: AlbumArtCard(
                      imageUrl: activeItem.coverUrl,
                      musicItem: activeItem,
                      size: 240,
                      heroTag: heroTag ?? 'cover_${item.id}',
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        ArtworkZoomViewer.show(
                          context,
                          imageUrl: activeItem.coverUrl,
                          title: activeItem.name,
                          artist: activeItem.artist,
                          heroTag: heroTag ?? 'cover_${item.id}',
                          year: activeItem.formattedYear,
                          typeLabel: activeItem.fullTypeLabel,
                        );
                      },
                    ),
                  ),

                  _EnrichedGenreTagsSection(item: activeItem),
                ],
              ),
            ),

            // Giant Community Score Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: avgScoreAsync.when(
                data: (score) {
                  final rawCount = reviewCountAsync.value ?? 0;
                  final effectiveScore = (score > 0 || existingUserReview == null)
                      ? score
                      : existingUserReview.rating;
                  final effectiveCount = (rawCount > 0 || existingUserReview == null)
                      ? rawCount
                      : (computedLogCount > 0 ? computedLogCount : 1);
                  return GiantScoreBadge(score: effectiveScore, reviewCount: effectiveCount)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOutCubic)
                      .scale(
                        begin: const Offset(0.97, 0.97),
                        end: const Offset(1.0, 1.0),
                        curve: Curves.easeOutBack,
                      );
                },
                loading: () {
                  if (existingUserReview != null) {
                    return GiantScoreBadge(
                      score: existingUserReview.rating,
                      reviewCount: computedLogCount > 0 ? computedLogCount : 1,
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.acidLime),
                  );
                },
                error: (err, stack) {
                  if (existingUserReview != null) {
                    return GiantScoreBadge(
                      score: existingUserReview.rating,
                      reviewCount: computedLogCount > 0 ? computedLogCount : 1,
                    );
                  }
                  return const GiantScoreBadge(score: 0.0);
                },
              ),
            ),

            // Tracklist Section (for Albums & EPs)
            if (activeItem.isRelease) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detailAsync.isLoading && activeItem.tracks.isEmpty
                              ? 'LOADING TRACKLIST...'
                              : 'TRACKLIST [${activeItem.tracks.length}]',
                          style: AppTypography.monoLabel(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (autoOverallScore != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyberCyan,
                              border: Border.all(color: AppColors.pureBlack, width: 1.0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RatingSpikeSign(
                                  rating: autoOverallScore,
                                  size: 11,
                                  color: AppColors.pureBlack,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'OVERALL ${autoOverallScore.toStringAsFixed(1)}',
                                  style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (activeItem.tracks.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 90,
                            child: Text(
                              'DURATION',
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 58,
                            child: Text(
                              'RATING',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTypography.monoLabel(fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(width: 22),
                        ],
                      ),
                  ],
                ),
              ),
              if (detailAsync.isLoading && activeItem.tracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.acidLime),
                    ),
                  ),
                )
              else if (activeItem.tracks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'NO TRACKLIST DATA AVAILABLE',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ),
                  ),
                )
              else
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
                    final trackRating = ref.watch(
                      trackUserRatingProvider((track: track, albumArtist: activeItem.artist)),
                    );
                    final bool hasDuplicatedTrackNumbers = activeItem.tracks.length > 1 &&
                        activeItem.tracks[0].trackNumber == activeItem.tracks[1].trackNumber;
                    final trackNumber = (track.trackNumber > 0 && !hasDuplicatedTrackNumbers)
                        ? track.trackNumber
                        : (index + 1);

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
                          externalSpotifyUrl: track.id.isNotEmpty ? 'https://www.deezer.com/track/${track.id}' : '',
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
                              trackNumber.toString().padLeft(2, '0'),
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
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: Text(
                              track.formattedDuration,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              softWrap: false,
                              style: AppTypography.monoLabel(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 58,
                            child: Center(
                              child: trackRating != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.acidLime.withValues(alpha: 0.15),
                                        border: Border.all(color: AppColors.acidLime, width: 1.0),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          RatingSpikeSign(
                                            rating: trackRating,
                                            size: 10,
                                            color: AppColors.acidLime,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            trackRating.toStringAsFixed(1),
                                            style: AppTypography.monoBadge(
                                              color: AppColors.acidLime,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Text(
                                      '-',
                                      style: AppTypography.monoBadge(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 6),
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
            ] else if ((item.isAlbum || item.isEp) && detailAsync.isLoading) ...[
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
                    onTap: () => WriteReviewModal.show(
                      context,
                      activeItem,
                      existingReview: null,
                      isLogAgain: existingUserReview != null,
                      previousLogCount: userLogCount,
                      autoOverallScore: autoOverallScore,
                      initialRating: autoOverallScore ?? existingUserReview?.rating,
                    ),
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
                final combinedReviews = <Review>[];
                final seenReviewIds = <String>{};
                if (existingUserReview != null) {
                  combinedReviews.add(existingUserReview);
                  seenReviewIds.add(existingUserReview.id);
                }
                for (final r in reviews) {
                  if (seenReviewIds.add(r.id)) {
                    combinedReviews.add(r);
                  }
                }

                if (combinedReviews.isEmpty) {
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
                          onPressed: () => WriteReviewModal.show(
                            context,
                            activeItem,
                            existingReview: existingUserReview,
                            autoOverallScore: autoOverallScore,
                            initialRating: autoOverallScore,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: combinedReviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final review = combinedReviews[index];
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
              loading: () {
                if (existingUserReview != null) {
                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      ReviewCard(
                        review: existingUserReview,
                        showItemHeader: false,
                        onLike: () {},
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReviewDetailScreen(review: existingUserReview!),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.acidLime),
                  ),
                );
              },
              error: (err, _) {
                if (existingUserReview != null) {
                  return ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      ReviewCard(
                        review: existingUserReview,
                        showItemHeader: false,
                        onLike: () {},
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReviewDetailScreen(review: existingUserReview!),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Failed to load reviews: $err'),
                );
              },
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
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(
                          artistIdOrName: item.artist,
                          initialArtistName: item.artist,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Flexible(
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
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 12, color: AppColors.acidLime),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArtistDetailScreen(
                        artistIdOrName: item.artist,
                        initialArtistName: item.artist,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.acidLime,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.pureBlack),
                  ),
                  child: Text(
                    'DOSSIER',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 8.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
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
              height: 242,
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
    final scoreAsync = ref.watch(itemAverageScoreProvider(ItemReviewQuery.fromItem(item)));
    final tag = 'more_${item.id}';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item, heroTag: tag)),
        );
      },
      child: Container(
        width: 148,
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
              musicItem: item,
              width: 124,
              height: 124,
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
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.typeColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: item.typeColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                        child: Text(
                          item.typeBadgeLabel,
                          style: AppTypography.monoBadge(
                            color: item.typeColor,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      if (item.formattedYear.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.formattedYear,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel(fontSize: 8.5, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                scoreAsync.when(
                  data: (s) {
                    if (s <= 0) return const SizedBox.shrink();
                    final scoreColor = s >= 9.0
                        ? AppColors.acidLime
                        : (s >= 8.0
                            ? AppColors.cyberCyan
                            : (s >= 6.5 ? AppColors.electricPink : const Color(0xFFFFB800)));
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: scoreColor,
                        borderRadius: BorderRadius.circular(1.5),
                        border: Border.all(color: AppColors.pureBlack, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RatingSpikeSign(
                            rating: s,
                            size: 9,
                            color: AppColors.pureBlack,
                          ),
                          const SizedBox(width: 2.5),
                          Text(
                            s.toStringAsFixed(1),
                            style: AppTypography.monoBadge(
                              color: AppColors.pureBlack,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

/// Dedicated isolated widget that renders enriched community genre tags.
/// Scoping tag observation to this widget guarantees that MusicDetailScreen's
/// heavy layout (scores, tracklists, critique lists) does not rebuild or lag.
class _EnrichedGenreTagsSection extends ConsumerWidget {
  final MusicItem item;

  const _EnrichedGenreTagsSection({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If the item already has resolved sub-genres, display them immediately with 0 lag
    if (item.genres.length > 1) {
      return _buildGenreWrap(item.genres);
    }

    // Synchronous curated or cached lookup (0ms)
    final syncTags = ref.watch(genreTagServiceProvider).getTagsSync(
          artist: item.artist,
          title: item.name,
          isAlbum: item.isAlbum || item.isEp,
        );
    if (syncTags.isNotEmpty) {
      return _buildGenreWrap(syncTags);
    }

    final queryKey = '${item.artist.trim().toLowerCase()}:::${item.name.trim().toLowerCase()}:::${item.isAlbum || item.isEp}';
    final enrichedAsync = ref.watch(itemEnrichedGenresByKeyProvider(queryKey));

    final tags = enrichedAsync.asData?.value ?? enrichedAsync.value;
    final displayGenres = (tags != null && tags.isNotEmpty) ? tags : item.genres;

    if (displayGenres.isNotEmpty) {
      return _buildGenreWrap(displayGenres);
    }

    if (enrichedAsync.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: List.generate(
            3,
            (index) => Container(
              width: 55.0 + (index * 14),
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildGenreWrap(List<String> genres) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: genres.map((g) {
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
    );
  }
}


