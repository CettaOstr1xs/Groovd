import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/friend_profile.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/lists/user_lists_screen.dart';
import 'package:groovd/presentation/screens/profile/all_rated_releases_screen.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/critic_followers_stats_row.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/state/friends_provider.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_lists_provider.dart';
import 'package:groovd/state/wishlist_provider.dart';

class FriendProfileScreen extends ConsumerWidget {
  final FriendProfile initialProfile;

  const FriendProfileScreen({
    super.key,
    required this.initialProfile,
  });

  static Route<void> route(FriendProfile profile) {
    return MaterialPageRoute(
      builder: (_) => FriendProfileScreen(initialProfile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(friendProfileProvider(initialProfile.userId));
    final profile = profileAsync.value ?? initialProfile;
    final isFollowing = ref.watch(isFollowingProvider(profile.userId));
    final followsYou = ref.watch(isFollowerOfCurrentUserProvider(profile.userId));
    final followLabel = isFollowing
        ? '✓ FOLLOWING'
        : (followsYou ? '+ FOLLOW BACK' : '+ FOLLOW');
    final headerFollowLabel = isFollowing
        ? '✓ FOLLOWING'
        : (followsYou ? '+ FOLLOW BACK' : '+ FOLLOW CRITIC');
    final liveFollowers = ref.watch(userFollowersCountProvider(profile.userId)).value;
    final followersCount = liveFollowers != null && liveFollowers > 0
        ? liveFollowers
        : (profile.followersCount +
                (isFollowing && !profile.isFollowing
                    ? 1
                    : (!isFollowing && profile.isFollowing ? -1 : 0)))
            .clamp(0, 9999999);
    final followingCount = profile.followingCount;
    final reviewsAsync = ref.watch(friendReviewsProvider(profile.userId));
    final reviews = reviewsAsync.asData?.value ?? [];

    final friendWishlistAsync = ref.watch(userWishlistProvider(profile.userId));
    final friendListsAsync = ref.watch(userCuratedListsProvider(profile.userId));

    final liveWantlistCount =
        friendWishlistAsync.asData?.value.length ?? profile.wantlistCount;
    final liveListsCount =
        friendListsAsync.asData?.value.length ?? profile.listsCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('CRITIC DOSSIER', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_outlined, color: AppColors.cyberCyan),
            tooltip: 'Curated Lists',
            onPressed: () => Navigator.of(context).push(
              UserListsScreen.route(
                targetUserId: profile.userId,
                targetUserName: profile.userName.toUpperCase(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: AppColors.textPrimary),
            tooltip: 'Wantlist // Wishlist',
            onPressed: () => Navigator.of(context).push(
              WishlistScreen.route(
                targetUserId: profile.userId,
                targetUserName: profile.userName.toUpperCase(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: BrutalistButton(
              label: followLabel,
              isSmall: true,
              backgroundColor: isFollowing ? AppColors.surfaceElevated : AppColors.acidLime,
              textColor: isFollowing ? AppColors.acidLime : AppColors.pureBlack,
              borderColor: isFollowing ? AppColors.acidLime : AppColors.pureBlack,
              onPressed: () {
                ref.read(followingListProvider.notifier).toggleFollow(profile);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Backdrop Banner (Clean & Full Bleed)
            if (profile.backdropPath != null && profile.backdropPath!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 165,
                decoration: const BoxDecoration(
                  color: AppColors.pureBlack,
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderBold, width: 2.0),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    (profile.backdropPath!.startsWith('http://') ||
                            profile.backdropPath!.startsWith('https://'))
                        ? Image.network(
                            profile.backdropPath!,
                            width: double.infinity,
                            height: 165,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                          )
                        : Image.file(
                            File(profile.backdropPath!),
                            width: double.infinity,
                            height: 165,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                          ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.transparent,
                            AppColors.pureBlack.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // User Persona Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Avatar
                      Container(
                        width: 71,
                        height: 71,
                        decoration: BoxDecoration(
                          color: AppColors.acidLime,
                          border: Border.all(color: AppColors.pureBlack, width: 2.0),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.pureBlack,
                              offset: Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: (profile.avatarPath != null && profile.avatarPath!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(1),
                                child: (profile.avatarPath!.startsWith('http://') ||
                                        profile.avatarPath!.startsWith('https://'))
                                    ? Image.network(
                                        profile.avatarPath!,
                                        width: 71,
                                        height: 71,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Center(
                                          child: Text(
                                            profile.userName.isNotEmpty
                                                ? profile.userName[0].toUpperCase()
                                                : 'C',
                                            style: AppTypography.monoBadge(
                                              color: AppColors.pureBlack,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(profile.avatarPath!),
                                        width: 71,
                                        height: 71,
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => Center(
                                          child: Text(
                                            profile.userName.isNotEmpty
                                                ? profile.userName[0].toUpperCase()
                                                : 'C',
                                            style: AppTypography.monoBadge(
                                              color: AppColors.pureBlack,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                              )
                            : Center(
                                child: Text(
                                  profile.userName.isNotEmpty
                                      ? profile.userName[0].toUpperCase()
                                      : 'C',
                                  style: AppTypography.monoBadge(
                                    color: AppColors.pureBlack,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      // Critic name & handle vertically centered on the middle side of avatar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile.userName.toUpperCase(),
                              style: AppTypography.displayMedium(fontSize: 20),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.formattedHandle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.monoLabel(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (followsYou) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      border: Border.all(color: AppColors.acidLime.withValues(alpha: 0.7), width: 0.8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      'FOLLOWS YOU',
                                      style: AppTypography.monoLabel(
                                        fontSize: 8,
                                        color: AppColors.acidLime,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            BrutalistButton(
                              label: headerFollowLabel,
                              isSmall: true,
                              backgroundColor:
                                  isFollowing ? AppColors.surfaceElevated : AppColors.acidLime,
                              textColor:
                                  isFollowing ? AppColors.acidLime : AppColors.pureBlack,
                              borderColor:
                                  isFollowing ? AppColors.acidLime : AppColors.pureBlack,
                              onPressed: () {
                                ref
                                    .read(followingListProvider.notifier)
                                    .toggleFollow(profile);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Critic Bio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard.withValues(alpha: 0.7),
                      border: Border.all(color: AppColors.border, width: 1.0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      profile.bio.isNotEmpty
                          ? profile.bio
                          : 'Sonic explorer & music enthusiast.',
                      style: AppTypography.bodySmall(
                        color: profile.bio.isNotEmpty
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Followers & Following Counters
                  CriticFollowersStatsRow(
                    followersCount: followersCount,
                    followingCount: followingCount,
                  ),
                ],
              ),
            ),

            // Statistics Grid
            reviewsAsync.when(
              data: (revs) {
                final totalLogged = revs.length;
                final avgScore = totalLogged > 0
                    ? (revs.fold<double>(0.0, (acc, r) => acc + r.rating) / totalLogged)
                    : 0.0;
                final perfectTens = revs.where((r) => r.rating >= 10.0).length;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            AllRatedReleasesScreen.route(
                              targetUserId: profile.userId,
                              targetUserName: profile.userName.toUpperCase(),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(2),
                          child: _StatBox(
                            label: 'LOGGED',
                            value: '$totalLogged',
                            accentColor: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatBox(
                          label: 'AVG SCORE',
                          value: avgScore > 0 ? avgScore.toStringAsFixed(1) : '—',
                          accentColor: AppColors.acidLime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            AllRatedReleasesScreen.route(
                              targetUserId: profile.userId,
                              targetUserName: profile.userName.toUpperCase(),
                              initialFilter: RatedFilter.perfect10s,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(2),
                          child: _StatBox(
                            label: 'PERFECT 10s',
                            value: '$perfectTens',
                            accentColor: AppColors.electricPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 80),
              error: (err, stack) => const SizedBox.shrink(),
            ),

            const Divider(),

            // Section: CRITIC'S CANON // TOP 3 ALBUMS & SONGS
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CRITIC\'S CANON',
                        style: AppTypography.displaySmall(),
                      ),
                      Text(
                        'CRITIC\'S HIGHEST RATED & PINNED RELEASES',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Top 3 Albums Podium
            _TopPicksPodiumSection(
              title: 'TOP 3 ALBUMS',
              badgeLabel: 'LP ARCHIVE',
              badgeColor: AppColors.acidLime,
              isAlbum: true,
              items: [
                profile.topAlbums.isNotEmpty ? profile.topAlbums[0] : null,
                profile.topAlbums.length > 1 ? profile.topAlbums[1] : null,
                profile.topAlbums.length > 2 ? profile.topAlbums[2] : null,
              ],
            ),

            const SizedBox(height: 24),

            // Top 3 Songs Podium
            _TopPicksPodiumSection(
              title: 'TOP 3 SONGS // SINGLES',
              badgeLabel: 'HEAVY ROTATION',
              badgeColor: AppColors.cyberCyan,
              isAlbum: false,
              items: [
                profile.topSongs.isNotEmpty ? profile.topSongs[0] : null,
                profile.topSongs.length > 1 ? profile.topSongs[1] : null,
                profile.topSongs.length > 2 ? profile.topSongs[2] : null,
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Section: RECENT ACTIVITY (Chronological Timeline of Scored Releases)
            _RecentActivitySection(
              reviews: reviews,
              userId: profile.userId,
              userName: profile.userName.toUpperCase(),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Logged Written Reviews Header & Navigation
            InkWell(
              onTap: () => Navigator.of(context).push(
                LoggedReviewsScreen.route(
                  targetUserId: profile.userId,
                  targetUserName: profile.userName.toUpperCase(),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CRITIC\'S LOGGED REVIEWS',
                      style: AppTypography.displaySmall(),
                    ),
                    reviewsAsync.when(
                      data: (r) {
                        final count = r.where((review) => review.hasWrittenReview).length;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count CRITIQUES',
                              style: AppTypography.monoLabel(
                                fontSize: 10,
                                color: AppColors.acidLime,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.acidLime,
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            reviewsAsync.when(
              data: (revs) {
                final writtenReviews = revs.where((r) => r.hasWrittenReview).toList();
                if (writtenReviews.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'NO WRITTEN REVIEWS LOGGED YET',
                            style: AppTypography.monoBadge(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This critic has not filed any written impressions yet.',
                            style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _ReviewStackDeck(reviews: writtenReviews.take(10).toList());
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.acidLime),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading reviews: $err'),
              ),
            ),

            const SizedBox(height: 24),

            // Critic Wantlist / Wishlist Shortcut Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WishlistShortcutBanner(
                count: liveWantlistCount,
                onTap: () => Navigator.of(context).push(
                  WishlistScreen.route(
                    targetUserId: profile.userId,
                    targetUserName: profile.userName.toUpperCase(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Curated Lists Shortcut Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ListsShortcutBanner(
                count: liveListsCount,
                onTap: () => Navigator.of(context).push(
                  UserListsScreen.route(
                    targetUserId: profile.userId,
                    targetUserName: profile.userName.toUpperCase(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TopPicksPodiumSection extends StatelessWidget {
  final String title;
  final String badgeLabel;
  final Color badgeColor;
  final bool isAlbum;
  final List<MusicItem?> items;

  const _TopPicksPodiumSection({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.isAlbum,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTypography.monoBadge(color: badgeColor, fontSize: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(
                  child: _PodiumCard(
                    rank: i + 1,
                    item: i < items.length ? items[i] : null,
                    isAlbum: isAlbum,
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int rank;
  final MusicItem? item;
  final bool isAlbum;

  const _PodiumCard({
    required this.rank,
    required this.item,
    required this.isAlbum,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return AppColors.acidLime;
      case 2:
        return AppColors.cyberCyan;
      case 3:
      default:
        return AppColors.electricPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item != null
          ? () {
              final target = item!.copyWith(
                type: isAlbum ? MusicType.album : MusicType.song,
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MusicDetailScreen(item: target),
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(
            color: item != null ? AppColors.border : AppColors.borderSubtle,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rank Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              decoration: BoxDecoration(
                color: _rankColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0$rank',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 10,
                    ),
                  ),
                  Icon(
                    isAlbum ? Icons.album : Icons.music_note,
                    size: 11,
                    color: AppColors.pureBlack,
                  ),
                ],
              ),
            ),

            if (item != null) ...[
              // Artwork
              AspectRatio(
                aspectRatio: 1.0,
                child: AlbumArtCard(
                  imageUrl: item!.coverUrl,
                  showShadow: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item!.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displaySmall(fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item!.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Empty Slot
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: AppColors.surfaceElevated,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.album_outlined,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'UNPINNED',
                        style: AppTypography.monoBadge(
                          color: AppColors.textSecondary,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'EMPTY // NO PICK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatBox({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.scoreLarge(color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  final List<Review> reviews;
  final String userId;
  final String userName;

  const _RecentActivitySection({
    required this.reviews,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 14,
                    color: AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RECENT ACTIVITY',
                    style: AppTypography.monoLabel(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  AllRatedReleasesScreen.route(
                    targetUserId: userId,
                    targetUserName: userName,
                  ),
                ),
                borderRadius: BorderRadius.circular(2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.acidLime.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ALL ${reviews.length} RATED',
                        style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 8),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right, size: 12, color: AppColors.acidLime),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (reviews.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppColors.textMuted, size: 24),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NO RECENT ACTIVITY RECORDED',
                        style: AppTypography.monoBadge(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'This critic has not scored any albums or tracks yet.',
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: reviews.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _RecentActivityCard(review: review);
              },
            ),
          ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final Review review;

  const _RecentActivityCard({required this.review});

  Color get _scoreColor {
    if (review.rating >= 9.0) return AppColors.acidLime;
    if (review.rating >= 8.0) return AppColors.cyberCyan;
    if (review.rating >= 6.5) return AppColors.electricPink;
    if (review.rating >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  @override
  Widget build(BuildContext context) {
    final isAlbum = review.itemType == 'album';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(review: review),
          ),
        );
      },
      borderRadius: BorderRadius.circular(2),
      child: Container(
        width: 255,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Row(
          children: [
            AlbumArtCard(
              imageUrl: review.coverUrl,
              size: 54,
              showShadow: false,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _scoreColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: Text(
                          review.rating.toStringAsFixed(1),
                          style: AppTypography.monoBadge(
                            color: AppColors.pureBlack,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAlbum ? 'LP' : 'TRACK',
                        style: AppTypography.monoLabel(
                          color: AppColors.textMuted,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    review.musicItemName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displaySmall(fontSize: 11),
                  ),
                  Text(
                    review.artistName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoLabel(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewStackDeck extends StatefulWidget {
  final List<Review> reviews;

  const _ReviewStackDeck({required this.reviews});

  @override
  State<_ReviewStackDeck> createState() => _ReviewStackDeckState();
}

class _ReviewStackDeckState extends State<_ReviewStackDeck> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _ReviewStackDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reviews.length != oldWidget.reviews.length) {
      if (_currentIndex >= widget.reviews.length) {
        _currentIndex = 0;
      }
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.reviews.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isHolding && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.reviews.length;
        });
      }
    });
  }

  void _pauseTimer() {
    if (!_isHolding) {
      setState(() => _isHolding = true);
    }
  }

  void _resumeTimer() {
    if (_isHolding) {
      setState(() => _isHolding = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openDetail(Review review) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(review: review),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return const SizedBox.shrink();

    final activeReview = widget.reviews[_currentIndex % widget.reviews.length];
    final hasMultiple = widget.reviews.length > 1;
    final stackDepth = hasMultiple ? 3 : 0;

    const double stepX = 4.0;
    const double stepY = 5.0;
    final totalExtraX = stackDepth * stepX;
    final totalExtraY = stackDepth * stepY;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Deck Meta Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'CARD ${(_currentIndex + 1).toString().padLeft(2, '0')} / ${widget.reviews.length.toString().padLeft(2, '0')}',
                      style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
                    ),
                  ),
                  if (hasMultiple) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isHolding ? AppColors.electricPink.withValues(alpha: 0.15) : AppColors.surface,
                        border: Border.all(color: _isHolding ? AppColors.electricPink : AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isHolding ? Icons.pause_circle_outline : Icons.autorenew,
                            size: 10,
                            color: _isHolding ? AppColors.electricPink : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isHolding ? 'HOLDING // PAUSED' : 'AUTO-CYCLE 5S',
                            style: AppTypography.monoBadge(
                              color: _isHolding ? AppColors.electricPink : AppColors.textMuted,
                              fontSize: 7.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (hasMultiple)
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentIndex = (_currentIndex - 1 + widget.reviews.length) % widget.reviews.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.chevron_left, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _currentIndex = (_currentIndex + 1) % widget.reviews.length;
                        });
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.chevron_right, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Stacked Card Pile Container with Acid Lime Illusion Behind Front Card
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20 + totalExtraX, totalExtraY + 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 3 illusion backdrop card layers stacked underneath with acid-lime neon borders
              if (stackDepth > 0)
                for (int i = stackDepth; i >= 1; i--)
                  Positioned.fill(
                    top: i * stepY,
                    left: i * stepX,
                    right: -(i * stepX),
                    bottom: -(i * stepY),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(
                          color: AppColors.acidLime.withValues(alpha: (1.0 - (i - 1) * 0.22).clamp(0.45, 1.0)),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),

              // Front Top Active Review Card with Line Limits
              GestureDetector(
                onTapDown: (_) => _pauseTimer(),
                onTapUp: (_) => _resumeTimer(),
                onTapCancel: () => _resumeTimer(),
                onLongPressStart: (_) => _pauseTimer(),
                onLongPressEnd: (_) => _resumeTimer(),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  transitionBuilder: (child, animation) {
                    final slideIn = Tween<Offset>(
                      begin: const Offset(0.04, 0.03),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideIn,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>('${activeReview.id}_$_currentIndex'),
                    child: Consumer(
                      builder: (context, ref, _) {
                        return ReviewCard(
                          review: activeReview,
                          showItemHeader: true,
                          maxHeadlineLines: 2,
                          maxBodyLines: 3,
                          onLike: () {
                            ref.read(reviewControllerProvider).likeReview(activeReview.id);
                          },
                          onTap: () => _openDetail(activeReview),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WishlistShortcutBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _WishlistShortcutBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.acidLime, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.acidLime,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(
                Icons.bookmark_outline,
                color: AppColors.pureBlack,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CRITIC WANTLIST // QUEUE',
                    style: AppTypography.displaySmall(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ALBUMS & TRACKS QUEUED TO SPIN',
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count QUEUED',
                    style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right, size: 12, color: AppColors.acidLime),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListsShortcutBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _ListsShortcutBanner({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          border: Border.all(color: AppColors.cyberCyan, width: 1.5),
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.pureBlack,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cyberCyan,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Icon(
                Icons.queue_music_outlined,
                color: AppColors.pureBlack,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURATED LISTS // ARCHIVE',
                    style: AppTypography.displaySmall(fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CUSTOM COLLECTION PLAYLISTS',
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count LISTS',
                    style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 9),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.chevron_right, size: 12, color: AppColors.cyberCyan),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
