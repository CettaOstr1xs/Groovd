import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/state/music_providers.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/presentation/widgets/album_art_card.dart';
import 'package:groovd/presentation/widgets/giant_score_badge.dart';
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
    final activeFilter = ref.watch(searchFilterProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

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

              // Filter Tabs: ALL, ALBUMS, TRACKS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', null, activeFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('ALBUMS', MusicType.album, activeFilter),
                    const SizedBox(width: 8),
                    _buildFilterChip('TRACKS', MusicType.song, activeFilter),
                  ],
                ),
              ),
              const Divider(),
            ],
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'NO MATCHES FOUND',
                      style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try searching for an album, song, or artist name.',
                      style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
      ),
    );
  }

  Widget _buildFilterChip(String label, MusicType? type, MusicType? current) {
    final isSelected = current == type;
    return GestureDetector(
      onTap: () {
        ref.read(searchFilterProvider.notifier).updateFilter(type);
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
                          color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          item.isAlbum ? 'LP' : 'SONG',
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
                  Text(
                    item.artist.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: AppColors.textSecondary),
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
