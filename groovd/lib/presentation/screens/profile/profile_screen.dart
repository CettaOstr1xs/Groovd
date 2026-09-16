import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/data/services/spotify_mock_data.dart';
import 'package:groovd/state/dossier_top_picks_provider.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/settings_provider.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';
import 'package:groovd/presentation/widgets/review_card.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/review/review_detail_screen.dart';
import 'package:groovd/presentation/screens/profile/logged_reviews_screen.dart';
import 'package:groovd/presentation/screens/wishlist/wishlist_screen.dart';
import 'package:groovd/state/wishlist_provider.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSpotifySettings(BuildContext context, WidgetRef ref) {
    final settings = ref.read(spotifySettingsProvider);
    final idController = TextEditingController(text: settings.clientId);
    final secretController = TextEditingController(text: settings.clientSecret);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.borderBold, width: 2.0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SPOTIFY API CONFIG', style: AppTypography.displaySmall()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your Spotify Developer Client ID and Secret to stream live Spotify search and catalog data.',
                style: AppTypography.bodySmall(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Text('SPOTIFY CLIENT ID', style: AppTypography.monoLabel(fontSize: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: idController,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(hintText: 'Enter Client ID...'),
              ),
              const SizedBox(height: 14),
              Text('SPOTIFY CLIENT SECRET', style: AppTypography.monoLabel(fontSize: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: secretController,
                obscureText: true,
                style: AppTypography.bodyLarge(),
                decoration: const InputDecoration(hintText: 'Enter Client Secret...'),
              ),
              const SizedBox(height: 20),
              BrutalistButton(
                label: 'SAVE & SYNC SPOTIFY',
                icon: Icons.save,
                isFullWidth: true,
                onPressed: () async {
                  await ref.read(spotifySettingsProvider.notifier).saveCredentials(
                        idController.text,
                        secretController.text,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'SPOTIFY CONFIGURATION SAVED',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack),
                        ),
                        backgroundColor: AppColors.acidLime,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTopPickSelector(
    BuildContext context,
    WidgetRef ref, {
    required bool isAlbum,
    required int slotIndex,
  }) {
    final searchController = TextEditingController();
    List<MusicItem> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final userId = ref.read(currentUserIdProvider);
            final userReviews = ref.read(userReviewsProvider(userId)).value ?? [];

            // Reviewed items
            final reviewedCandidates = userReviews
                .where((r) => isAlbum ? r.itemType == 'album' : r.itemType == 'song')
                .map((r) => MusicItem(
                      id: r.musicItemId,
                      name: r.musicItemName,
                      artist: r.artistName,
                      type: isAlbum ? MusicType.album : MusicType.song,
                      coverUrl: r.coverUrl,
                      releaseDate: '',
                    ))
                .toList();

            // Curated catalogue candidates
            final curatedCandidates = isAlbum
                ? SpotifyMockData.trendingAlbums
                : SpotifyMockData.hotTracks;

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.borderBold, width: 2.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PIN RANK 0${slotIndex + 1} // ${isAlbum ? "ALBUM" : "SONG"}',
                            style: AppTypography.displaySmall(fontSize: 16),
                          ),
                          Text(
                            'CHOOSE FROM LOGGED REVIEWS OR CATALOG',
                            style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input
                  TextField(
                    controller: searchController,
                    style: AppTypography.headline(fontSize: 14),
                    cursorColor: AppColors.acidLime,
                    decoration: InputDecoration(
                      hintText: 'Search ${isAlbum ? "album" : "song"} to pin...',
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                searchController.clear();
                                setModalState(() {
                                  searchResults = [];
                                });
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (val) async {
                      if (val.trim().isEmpty) return;
                      setModalState(() => isSearching = true);
                      final res = await ref.read(spotifyRepositoryProvider).search(
                            val,
                            type: isAlbum ? MusicType.album : MusicType.song,
                          );
                      setModalState(() {
                        isSearching = false;
                        searchResults = res;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Selection list
                  Expanded(
                    child: isSearching
                        ? const Center(child: CircularProgressIndicator(color: AppColors.acidLime))
                        : searchResults.isNotEmpty
                            ? ListView.separated(
                                itemCount: searchResults.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final item = searchResults[idx];
                                  return _CandidateTile(
                                    item: item,
                                    onSelect: () async {
                                      await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                            isAlbum: isAlbum,
                                            slotIndex: slotIndex,
                                            item: item,
                                          );
                                      if (context.mounted) Navigator.of(context).pop();
                                    },
                                  );
                                },
                              )
                            : ListView(
                                children: [
                                  if (reviewedCandidates.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'FROM YOUR RECENT CRITIQUES',
                                        style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
                                      ),
                                    ),
                                    ...reviewedCandidates.map((item) => _CandidateTile(
                                          item: item,
                                          onSelect: () async {
                                            await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                                  isAlbum: isAlbum,
                                                  slotIndex: slotIndex,
                                                  item: item,
                                                );
                                            if (context.mounted) Navigator.of(context).pop();
                                          },
                                        )),
                                    const Divider(height: 24),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'SUGGESTED CANON',
                                      style: AppTypography.monoBadge(color: AppColors.cyberCyan, fontSize: 10),
                                    ),
                                  ),
                                  ...curatedCandidates.map((item) => _CandidateTile(
                                        item: item,
                                        onSelect: () async {
                                          await ref.read(dossierTopPicksProvider.notifier).pinItem(
                                                isAlbum: isAlbum,
                                                slotIndex: slotIndex,
                                                item: item,
                                              );
                                          if (context.mounted) Navigator.of(context).pop();
                                        },
                                      )),
                                ],
                              ),
                  ),

                  const SizedBox(height: 8),
                  BrutalistButton(
                    label: 'CLEAR / UNPIN SLOT',
                    icon: Icons.delete_outline,
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.vermillion,
                    borderColor: AppColors.border,
                    isFullWidth: true,
                    onPressed: () async {
                      await ref.read(dossierTopPicksProvider.notifier).unpinItem(
                            isAlbum: isAlbum,
                            slotIndex: slotIndex,
                          );
                      if (context.mounted) Navigator.of(context).pop();
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
    final userId = ref.watch(currentUserIdProvider);
    final userName = ref.watch(currentUserNameProvider);
    final userHandle = ref.watch(currentUserHandleProvider);
    final userReviewsAsync = ref.watch(userReviewsProvider(userId));
    final spotifySettings = ref.watch(spotifySettingsProvider);
    final topPicks = ref.watch(resolvedTopPicksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('CRITIC DOSSIER', style: AppTypography.displaySmall()),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline, color: AppColors.textPrimary),
            tooltip: 'Wantlist // Wishlist',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WishlistScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textPrimary),
            tooltip: 'Spotify Settings',
            onPressed: () => _showSpotifySettings(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    children: [
                      Container(
                        width: 60,
                        height: 60,
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
                        alignment: Alignment.center,
                        child: Text(
                          'YOU',
                          style: AppTypography.monoBadge(
                            color: AppColors.pureBlack,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.toUpperCase(),
                              style: AppTypography.displayMedium(fontSize: 20),
                            ),
                            Text(
                              userHandle,
                              style: AppTypography.monoLabel(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Data source status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: spotifySettings.isLiveMode ? AppColors.acidLime : AppColors.cyberCyan,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          spotifySettings.isLiveMode
                              ? 'DATA SOURCE: LIVE SPOTIFY API'
                              : 'DATA SOURCE: CURATED CATALOG (DEMO)',
                          style: AppTypography.monoBadge(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Grid
            userReviewsAsync.when(
              data: (reviews) {
                final totalLogged = reviews.length;
                final avgScore = totalLogged > 0
                    ? (reviews.fold<double>(0.0, (acc, r) => acc + r.rating) / totalLogged)
                    : 0.0;
                final perfectTens = reviews.where((r) => r.rating >= 9.5).length;

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: 'LOGGED',
                          value: '$totalLogged',
                          accentColor: AppColors.textPrimary,
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
                        child: _StatBox(
                          label: 'PERFECT 10s',
                          value: '$perfectTens',
                          accentColor: AppColors.electricPink,
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
                        'YOUR HIGHEST RATED & PINNED RELEASES',
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
              items: topPicks.topAlbums,
              onSelectSlot: (slot) => _showTopPickSelector(context, ref, isAlbum: true, slotIndex: slot),
            ),

            const SizedBox(height: 24),

            // Top 3 Songs Podium
            _TopPicksPodiumSection(
              title: 'TOP 3 SONGS // SINGLES',
              badgeLabel: 'HEAVY ROTATION',
              badgeColor: AppColors.cyberCyan,
              isAlbum: false,
              items: topPicks.topSongs,
              onSelectSlot: (slot) => _showTopPickSelector(context, ref, isAlbum: false, slotIndex: slot),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Section: RECENT ACTIVITY (Chronological Timeline of Scored Releases)
            _RecentActivitySection(
              reviews: userReviewsAsync.asData?.value ?? [],
            ),

            const SizedBox(height: 20),

            // Wantlist / Wishlist Shortcut Button (Below Recent Activity)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _WishlistShortcutBanner(
                count: ref.watch(wishlistCountProvider),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WishlistScreen()),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Logged Written Reviews Header & Redirect Button
            InkWell(
              onTap: () => Navigator.of(context).push(
                LoggedReviewsScreen.route(),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MY LOGGED REVIEWS',
                      style: AppTypography.displaySmall(),
                    ),
                    userReviewsAsync.when(
                      data: (r) {
                        final count = r.where((review) => review.hasWrittenReview).length;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$count CRITIQUES',
                              style: AppTypography.monoLabel(fontSize: 10, color: AppColors.acidLime),
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
                      loading: () => const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            userReviewsAsync.when(
              data: (reviews) {
                final writtenReviews = reviews.where((r) => r.hasWrittenReview).toList();
                if (writtenReviews.isEmpty) {
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
                          'NO WRITTEN REVIEWS LOGGED YET',
                          style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drop your in-depth written impressions on any album or track to file it here.',
                          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return _ReviewStackDeck(reviews: writtenReviews);
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
  final ValueChanged<int> onSelectSlot;

  const _TopPicksPodiumSection({
    required this.title,
    required this.badgeLabel,
    required this.badgeColor,
    required this.isAlbum,
    required this.items,
    required this.onSelectSlot,
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
                  child: _PodiumSlotCard(
                    rank: i + 1,
                    item: i < items.length ? items[i] : null,
                    isAlbum: isAlbum,
                    onTap: () {
                      final item = i < items.length ? items[i] : null;
                      if (item != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
                        );
                      } else {
                        onSelectSlot(i);
                      }
                    },
                    onLongPress: () => onSelectSlot(i),
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

class _PodiumSlotCard extends StatelessWidget {
  final int rank;
  final MusicItem? item;
  final bool isAlbum;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PodiumSlotCard({
    required this.rank,
    required this.item,
    required this.isAlbum,
    required this.onTap,
    required this.onLongPress,
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
      onTap: onTap,
      onLongPress: onLongPress,
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
                      style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
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
                        Icons.add_circle_outline,
                        color: _rankColor,
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '+ PIN ${isAlbum ? "LP" : "SONG"}',
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
                  'EMPTY // TAP TO PIN',
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

class _CandidateTile extends StatelessWidget {
  final MusicItem item;
  final VoidCallback onSelect;

  const _CandidateTile({
    required this.item,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: AlbumArtCard(
        imageUrl: item.coverUrl,
        size: 44,
        showShadow: false,
      ),
      title: Text(
        item.name.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.headline(fontSize: 13),
      ),
      subtitle: Text(
        item.artist.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall(color: AppColors.textMuted, fontSize: 10),
      ),
      trailing: BrutalistButton(
        label: 'PIN',
        isSmall: true,
        backgroundColor: AppColors.acidLime,
        textColor: AppColors.pureBlack,
        onPressed: onSelect,
      ),
      onTap: onSelect,
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

  const _RecentActivitySection({required this.reviews});

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${reviews.length} SCORED',
                  style: AppTypography.monoBadge(color: AppColors.textSecondary, fontSize: 8),
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
                        style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rate any album or single to start building your chronological timeline.',
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

class _RecentActivityCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isAlbum = review.itemType == 'album';

    return InkWell(
      onTap: () async {
        MusicItem? item = await ref.read(spotifyRepositoryProvider).getItemById(
              review.musicItemId,
              type: isAlbum ? MusicType.album : MusicType.song,
            );
        item ??= MusicItem(
          id: review.musicItemId,
          name: review.musicItemName,
          artist: review.artistName,
          type: isAlbum ? MusicType.album : MusicType.song,
          coverUrl: review.coverUrl,
          releaseDate: '',
        );
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item!)),
          );
        }
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
              size: 74,
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
                          color: isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          isAlbum ? 'LP' : 'SONG',
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 7.5),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        review.timeAgo,
                        style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _scoreColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          review.scoreFormatted,
                          style: AppTypography.monoBadge(
                            color: AppColors.pureBlack,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                    style: AppTypography.monoLabel(fontSize: 8, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      review.hasWrittenReview ? 'CRITIQUE' : 'RATING ONLY',
                      style: AppTypography.monoBadge(
                        color: review.hasWrittenReview ? AppColors.electricPink : AppColors.textMuted,
                        fontSize: 7.5,
                      ),
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
              child: Text(
                '$count QUEUED',
                style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
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
    // Illusion: exactly 3 cards stacked behind front card ONLY if user has more than 1 logged review
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

        // Stacked Card Pile Container with Illusion Behind Front Card
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20 + totalExtraX, totalExtraY + 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 3 illusion backdrop card layers stacked underneath
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

              // Front Top Active Review Card
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

