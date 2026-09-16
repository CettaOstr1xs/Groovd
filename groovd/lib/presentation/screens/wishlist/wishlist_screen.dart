import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/wishlist_item.dart';
import '../../../state/wishlist_provider.dart';
import '../../../state/review_providers.dart';
import '../../widgets/album_art_card.dart';
import '../../widgets/brutalist_button.dart';
import '../detail/music_detail_screen.dart';
import '../review/write_review_modal.dart';

enum _WishlistFilter { all, albums, songs }
enum _WishlistSort { recent, title, artist }

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  _WishlistFilter _filter = _WishlistFilter.all;
  _WishlistSort _sort = _WishlistSort.recent;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmClearWishlist() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        title: Text('CLEAR WANTLIST?', style: AppTypography.displaySmall(fontSize: 16)),
        content: Text(
          'Are you sure you want to purge all queued releases from your wantlist?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCEL', style: AppTypography.monoLabel(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermillion,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(wishlistProvider.notifier).clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Text('WANTLIST PURGED', style: AppTypography.monoLabel(color: AppColors.vermillion)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text('PURGE ALL', style: AppTypography.monoBadge(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  List<WishlistItem> _applyFiltersAndSort(List<WishlistItem> items) {
    var filtered = items;

    // Filter by type
    if (_filter == _WishlistFilter.albums) {
      filtered = filtered.where((item) => item.musicItem.isAlbum).toList();
    } else if (_filter == _WishlistFilter.songs) {
      filtered = filtered.where((item) => item.musicItem.isSong).toList();
    }

    // Filter by query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((item) {
        final name = item.musicItem.name.toLowerCase();
        final artist = item.musicItem.artist.toLowerCase();
        return name.contains(q) || artist.contains(q);
      }).toList();
    }

    // Sort
    final sorted = List<WishlistItem>.from(filtered);
    switch (_sort) {
      case _WishlistSort.recent:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case _WishlistSort.title:
        sorted.sort((a, b) => a.musicItem.name.toLowerCase().compareTo(b.musicItem.name.toLowerCase()));
        break;
      case _WishlistSort.artist:
        sorted.sort((a, b) => a.musicItem.artist.toLowerCase().compareTo(b.musicItem.artist.toLowerCase()));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final userReviewsAsync = ref.watch(userReviewsProvider(userId));
    final userReviews = userReviewsAsync.asData?.value ?? [];
    if (userReviews.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(wishlistProvider.notifier).removeReviewedItems(userReviews);
      });
    }

    final allWishlistItems = ref.watch(wishlistProvider);
    final displayedItems = _applyFiltersAndSort(allWishlistItems);

    final albumCount = allWishlistItems.where((i) => i.musicItem.isAlbum).length;
    final songCount = allWishlistItems.where((i) => i.musicItem.isSong).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('CRITIC WANTLIST', style: AppTypography.displaySmall()),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '${allWishlistItems.length}',
                style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          if (allWishlistItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary, size: 22),
              tooltip: 'Clear Wantlist',
              onPressed: _confirmClearWishlist,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Search Header Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
            ),
            child: Column(
              children: [
                // Search field within wishlist
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: AppTypography.bodySmall(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'SEARCH IN WANTLIST...',
                      hintStyle: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filters and Sort row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Segmented Filter Pills
                    Row(
                      children: [
                        _FilterPill(
                          label: 'ALL (${allWishlistItems.length})',
                          isSelected: _filter == _WishlistFilter.all,
                          accentColor: AppColors.textPrimary,
                          onTap: () => setState(() => _filter = _WishlistFilter.all),
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: 'LPS ($albumCount)',
                          isSelected: _filter == _WishlistFilter.albums,
                          accentColor: AppColors.acidLime,
                          onTap: () => setState(() => _filter = _WishlistFilter.albums),
                        ),
                        const SizedBox(width: 6),
                        _FilterPill(
                          label: 'SONGS ($songCount)',
                          isSelected: _filter == _WishlistFilter.songs,
                          accentColor: AppColors.cyberCyan,
                          onTap: () => setState(() => _filter = _WishlistFilter.songs),
                        ),
                      ],
                    ),

                    // Sort dropdown/button
                    PopupMenuButton<_WishlistSort>(
                      tooltip: 'Sort Options',
                      color: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      onSelected: (sort) => setState(() => _sort = sort),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: _WishlistSort.recent,
                          child: Text(
                            'RECENTLY ADDED',
                            style: AppTypography.monoLabel(
                              color: _sort == _WishlistSort.recent ? AppColors.acidLime : AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: _WishlistSort.title,
                          child: Text(
                            'TITLE (A-Z)',
                            style: AppTypography.monoLabel(
                              color: _sort == _WishlistSort.title ? AppColors.acidLime : AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        PopupMenuItem(
                          value: _WishlistSort.artist,
                          child: Text(
                            'ARTIST (A-Z)',
                            style: AppTypography.monoLabel(
                              color: _sort == _WishlistSort.artist ? AppColors.acidLime : AppColors.textPrimary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              _sort == _WishlistSort.recent
                                  ? 'RECENT'
                                  : _sort == _WishlistSort.title
                                      ? 'TITLE'
                                      : 'ARTIST',
                              style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main List or Empty State
          Expanded(
            child: displayedItems.isEmpty
                ? _EmptyWishlistView(
                    hasFilter: allWishlistItems.isNotEmpty,
                    onResetSearch: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _filter = _WishlistFilter.all;
                      });
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: displayedItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = displayedItems[index];
                      return _WishlistCard(
                        wishlistItem: item,
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          final removed = item;
                          ref.read(wishlistProvider.notifier).removeItem(item.musicItem.id);
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surfaceElevated,
                              content: Text(
                                'REMOVED "${removed.musicItem.name.toUpperCase()}"',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.monoLabel(color: AppColors.textPrimary, fontSize: 11),
                              ),
                              action: SnackBarAction(
                                label: 'UNDO',
                                textColor: AppColors.acidLime,
                                onPressed: () {
                                  ref.read(wishlistProvider.notifier).addItem(removed.musicItem);
                                },
                              ),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : AppColors.surfaceCard,
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          label,
          style: AppTypography.monoBadge(
            color: isSelected ? AppColors.pureBlack : AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem wishlistItem;
  final VoidCallback onRemove;

  const _WishlistCard({
    required this.wishlistItem,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final item = wishlistItem.musicItem;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MusicDetailScreen(item: item)),
          );
        },
        borderRadius: BorderRadius.circular(2),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Artwork
              SizedBox(
                width: 72,
                height: 72,
                child: AlbumArtCard(
                  imageUrl: item.coverUrl,
                  showShadow: false,
                ),
              ),
              const SizedBox(width: 14),

              // Info & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isAlbum ? AppColors.acidLime : AppColors.cyberCyan,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            item.isAlbum ? 'LP' : 'SONG',
                            style: AppTypography.monoBadge(
                              color: AppColors.pureBlack,
                              fontSize: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ADDED ${wishlistItem.timeAgo.toUpperCase()}',
                          style: AppTypography.monoLabel(
                            color: AppColors.textMuted,
                            fontSize: 8,
                          ),
                        ),
                        if (item.formattedYear.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${item.formattedYear}',
                            style: AppTypography.monoLabel(
                              color: AppColors.textMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.displaySmall(fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    // Artist
                    Text(
                      item.artist.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoLabel(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick Action Row
                    Row(
                      children: [
                        // Quick Rate / Review button
                        InkWell(
                          onTap: () => WriteReviewModal.show(context, item),
                          borderRadius: BorderRadius.circular(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_outline, size: 12, color: AppColors.acidLime),
                                const SizedBox(width: 4),
                                Text(
                                  '+ RATE RELEASE',
                                  style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Remove from Wishlist
                        IconButton(
                          icon: const Icon(Icons.bookmark_remove_outlined, size: 18, color: AppColors.textMuted),
                          tooltip: 'Remove from wantlist',
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          onPressed: onRemove,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWishlistView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback onResetSearch;

  const _EmptyWishlistView({
    required this.hasFilter,
    required this.onResetSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.border, width: 2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pureBlack,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark_border,
                size: 48,
                color: AppColors.acidLime,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilter ? 'NO MATCHING RELEASES FOUND' : 'CRITIC WANTLIST IS EMPTY',
              textAlign: TextAlign.center,
              style: AppTypography.displaySmall(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'Try changing your search keywords or switching filter categories.'
                  : 'Bookmark albums and tracks while exploring the catalog to build your backlog queue of music to critique.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (hasFilter)
              BrutalistButton(
                label: 'RESET FILTERS',
                icon: Icons.refresh,
                backgroundColor: AppColors.surfaceElevated,
                textColor: AppColors.textPrimary,
                borderColor: AppColors.border,
                onPressed: onResetSearch,
              )
            else
              BrutalistButton(
                label: 'DISCOVER MUSIC',
                icon: Icons.search,
                backgroundColor: AppColors.acidLime,
                textColor: AppColors.pureBlack,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}
