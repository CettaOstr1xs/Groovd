import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/artist.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
import 'package:groovd/presentation/screens/artist/artist_detail_screen.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).updateQuery(val);
      }
    });
  }

  void _submitSearch(String val) {
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).updateQuery(val);
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = ref.watch(searchCategoryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final artistsAsync = ref.watch(artistSearchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SEARCH CATALOG',
          style: AppTypography.displaySmall(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.headline(color: AppColors.textPrimary),
                  cursorColor: AppColors.acidLime,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search songs, albums, artists...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                            onPressed: () {
                              _debounceTimer?.cancel();
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).updateQuery('');
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() {});
                    _onSearchChanged(val);
                  },
                  onSubmitted: _submitSearch,
                ),
              ),

              // Filter Tabs: ALL, ARTISTS, ALBUMS, TRACKS (left-aligned)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildFilterChip('ALL', SearchCategory.all, activeCategory),
                        const SizedBox(width: 8),
                        _buildFilterChip('ARTISTS', SearchCategory.artists, activeCategory),
                        const SizedBox(width: 8),
                        _buildFilterChip('ALBUMS', SearchCategory.albums, activeCategory),
                        const SizedBox(width: 8),
                        _buildFilterChip('TRACKS', SearchCategory.tracks, activeCategory),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
      body: _buildContent(
        activeCategory: activeCategory,
        resultsAsync: resultsAsync,
        artistsAsync: artistsAsync,
        query: query,
      ),
    );
  }

  Widget _buildContent({
    required SearchCategory activeCategory,
    required AsyncValue<List<MusicItem>> resultsAsync,
    required AsyncValue<List<Artist>> artistsAsync,
    required String query,
  }) {
    if (activeCategory == SearchCategory.artists) {
      if (query.trim().isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_search_outlined, size: 48, color: AppColors.acidLime),
                const SizedBox(height: 16),
                Text(
                  'SEARCH ARTIST DOSSIERS',
                  style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type an artist name in the search bar above to inspect their profile, discography, and career critique.',
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return artistsAsync.when(
        data: (artists) {
          if (artists.isEmpty) {
            return _buildEmptyState(
              'NO ARTISTS FOUND',
              'No catalog artist found matching "$query".',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: artists.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return _ArtistSearchCard(artist: artist)
                  .animate()
                  .fadeIn(
                    duration: 250.ms,
                    delay: (index * 35).ms,
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.acidLime),
        ),
        error: (err, _) => Center(
          child: Text('Error loading artists: $err', style: AppTypography.bodyMedium()),
        ),
      );
    }

    // When viewing ALBUMS or TRACKS specific categories
    if (activeCategory == SearchCategory.albums || activeCategory == SearchCategory.tracks) {
      return resultsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(
              'NO MATCHES FOUND',
              'No ${activeCategory == SearchCategory.albums ? 'albums' : 'tracks'} found.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _SearchItemTile(item: item)
                  .animate()
                  .fadeIn(
                    duration: 250.ms,
                    delay: (index * 35).ms,
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.acidLime),
        ),
        error: (err, _) => Center(
          child: Text('Search error: $err', style: AppTypography.bodyMedium()),
        ),
      );
    }

    // Default: ALL Category
    return resultsAsync.when(
      data: (items) {
        final matchingArtists = artistsAsync.asData?.value ?? [];
        final hasArtistMatch = query.trim().isNotEmpty && matchingArtists.isNotEmpty;

        if (items.isEmpty && !hasArtistMatch) {
          return _buildEmptyState(
            'NO MATCHES FOUND',
            'Try searching for an album, song, or artist name.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Prominent Matching Artist Dossier Card at top if query matches an artist
            if (hasArtistMatch) ...[
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.acidLime),
                  const SizedBox(width: 6),
                  Text(
                    'MATCHING ARTIST DOSSIER',
                    style: AppTypography.monoBadge(
                      color: AppColors.acidLime,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ArtistSearchCard(
                artist: matchingArtists.first,
                isFeatured: true,
              )
                  .animate()
                  .fadeIn(duration: 250.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 20),
              if (items.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'CATALOG RELEASES & TRACKS',
                      style: AppTypography.monoBadge(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],

            // Catalog Items (LPs & Tracks)
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SearchItemTile(item: item)
                    .animate()
                    .fadeIn(
                      duration: 250.ms,
                      delay: (index * 25).ms,
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              );
            }),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.acidLime),
      ),
      error: (err, _) => Center(
        child: Text('Search error: $err', style: AppTypography.bodyMedium()),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: AppTypography.bodyMedium(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchCategory category, SearchCategory current) {
    final isSelected = current == category;
    return GestureDetector(
      onTap: () {
        ref.read(searchCategoryProvider.notifier).updateCategory(category);
        switch (category) {
          case SearchCategory.all:
          case SearchCategory.artists:
            ref.read(searchFilterProvider.notifier).updateFilter(null);
            break;
          case SearchCategory.albums:
            ref.read(searchFilterProvider.notifier).updateFilter(MusicType.album);
            break;
          case SearchCategory.tracks:
            ref.read(searchFilterProvider.notifier).updateFilter(MusicType.song);
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.acidLime : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppColors.acidLime : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoBadge(
            color: isSelected ? AppColors.pureBlack : AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

/// Neo-Brutalist Artist Dossier Card for Search Catalog
class _ArtistSearchCard extends StatelessWidget {
  final Artist artist;
  final bool isFeatured;

  const _ArtistSearchCard({
    required this.artist,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtistDetailScreen(
              artistIdOrName: artist.id.isNotEmpty ? artist.id : artist.name,
              initialArtistName: artist.name,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isFeatured ? AppColors.acidLime : AppColors.border,
            width: isFeatured ? 2 : 1.5,
          ),
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
            // Top Badge Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.acidLime,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.pureBlack, width: 1.2),
                  ),
                  child: Text(
                    'ARTIST // DOSSIER',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 8.5,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OPEN DOSSIER',
                      style: AppTypography.monoBadge(
                        color: AppColors.cyberCyan,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 13,
                      color: AppColors.cyberCyan,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Artist Info Row
            Row(
              children: [
                // Artist Avatar with Neo-Brutalist Frame
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.pureBlack, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: artist.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: artist.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(color: AppColors.surfaceElevated),
                            errorWidget: (_, _, _) => const Icon(
                              Icons.person,
                              size: 32,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                // Artist Name & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        artist.name.toUpperCase(),
                        style: AppTypography.displaySmall().copyWith(
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (artist.shortDescription != null && artist.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          artist.shortDescription!.toUpperCase(),
                          style: AppTypography.monoLabel(
                            color: AppColors.cyberCyan,
                            fontSize: 9.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Genres & Followers Badges
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          if (artist.followers > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: AppColors.border, width: 1),
                              ),
                              child: Text(
                                artist.formattedFollowers,
                                style: AppTypography.monoBadge(
                                  color: AppColors.textSecondary,
                                  fontSize: 8,
                                ),
                              ),
                            ),
                          ...artist.genres.take(2).map(
                                (g) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: AppColors.border, width: 1),
                                  ),
                                  child: Text(
                                    g,
                                    style: AppTypography.monoBadge(
                                      color: AppColors.textMuted,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                        ],
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

class _SearchItemTile extends ConsumerWidget {
  final MusicItem item;

  const _SearchItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoreAsync = ref.watch(itemAverageScoreProvider(item.id));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MusicDetailScreen(
              item: item,
              heroTag: 'search_${item.id}',
            ),
          ),
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
            // Artwork Thumbnail
            AlbumArtCard(
              imageUrl: item.coverUrl,
              size: 64,
              showShadow: false,
              heroTag: 'search_${item.id}',
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: item.typeColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.formattedYear,
                        style: AppTypography.monoLabel(fontSize: 9, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.headline(color: AppColors.textPrimary),
                  ),
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
                    child: Text(
                      item.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: AppColors.cyberCyan),
                    ),
                  ),
                ],
              ),
            ),

            // Score
            scoreAsync.when(
              data: (score) => score > 0
                  ? GiantScoreBadge(score: score, compact: true)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
