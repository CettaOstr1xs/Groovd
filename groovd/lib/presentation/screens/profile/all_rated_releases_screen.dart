import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/review.dart';
import '../../../state/review_providers.dart';
import '../../widgets/album_art_card.dart';
import '../../widgets/brutalist_button.dart';
import '../review/review_detail_screen.dart';

enum RatedFilter { all, albums, eps, songs, perfect10s }
enum _RatedSort { newest, oldest, highestScore, lowestScore, titleAZ, artistAZ }
enum _RatedViewMode { grid, list }

class AllRatedReleasesScreen extends ConsumerStatefulWidget {
  final RatedFilter initialFilter;
  final String? targetUserId;
  final String? targetUserName;

  const AllRatedReleasesScreen({
    super.key,
    this.initialFilter = RatedFilter.all,
    this.targetUserId,
    this.targetUserName,
  });

  /// Custom neo-brutalist smooth slide and fade route transition
  static Route<T> route<T>({
    RatedFilter initialFilter = RatedFilter.all,
    String? targetUserId,
    String? targetUserName,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          AllRatedReleasesScreen(
        initialFilter: initialFilter,
        targetUserId: targetUserId,
        targetUserName: targetUserName,
      ),
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<AllRatedReleasesScreen> createState() => _AllRatedReleasesScreenState();
}

class _AllRatedReleasesScreenState extends ConsumerState<AllRatedReleasesScreen>
    with SingleTickerProviderStateMixin {
  late RatedFilter _filter;
  _RatedSort _sort = _RatedSort.newest;
  _RatedViewMode _viewMode = _RatedViewMode.grid;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(_headerFade);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Review> _applyFiltersAndSort(List<Review> reviews) {
    var filtered = List<Review>.from(reviews);

    // Filter by type or perfect 10
    if (_filter == RatedFilter.albums) {
      filtered = filtered.where((r) => r.itemType == 'album').toList();
    } else if (_filter == RatedFilter.eps) {
      filtered = filtered.where((r) => r.itemType == 'ep').toList();
    } else if (_filter == RatedFilter.songs) {
      filtered = filtered.where((r) => r.itemType == 'song').toList();
    } else if (_filter == RatedFilter.perfect10s) {
      filtered = filtered.where((r) => r.rating >= 10.0).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((r) {
        final title = r.musicItemName.toLowerCase();
        final artist = r.artistName.toLowerCase();
        final headline = r.headline.toLowerCase();
        final tags = r.tags.map((t) => t.toLowerCase()).join(' ');
        return title.contains(q) || artist.contains(q) || headline.contains(q) || tags.contains(q);
      }).toList();
    }

    // Sort
    switch (_sort) {
      case _RatedSort.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _RatedSort.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _RatedSort.highestScore:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _RatedSort.lowestScore:
        filtered.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case _RatedSort.titleAZ:
        filtered.sort((a, b) => a.musicItemName.compareTo(b.musicItemName));
        break;
      case _RatedSort.artistAZ:
        filtered.sort((a, b) => a.artistName.compareTo(b.artistName));
        break;
    }

    return filtered;
  }

  Color _getScoreColor(double score) {
    if (score >= 9.0) return AppColors.acidLime;
    if (score >= 8.0) return AppColors.cyberCyan;
    if (score >= 6.5) return AppColors.electricPink;
    if (score >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final isMe = widget.targetUserId == null || widget.targetUserId == currentUserId;
    final effectiveUserId = widget.targetUserId ?? currentUserId;
    final reviewsAsync = ref.watch(userReviewsProvider(effectiveUserId));
    final headerTitle = isMe
        ? 'ALL RATED RELEASES'
        : (widget.targetUserName != null
            ? '${widget.targetUserName}\'S RATED'
            : 'RATED RELEASES');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text(headerTitle, style: AppTypography.displaySmall()),
            const SizedBox(width: 8),
            reviewsAsync.when(
              data: (reviews) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${reviews.length}',
                  style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: reviewsAsync.when(
        data: (allReviews) {
          final displayedReleases = _applyFiltersAndSort(allReviews);

          final albumCount = allReviews.where((r) => r.itemType == 'album').length;
          final epCount = allReviews.where((r) => r.itemType == 'ep').length;
          final songCount = allReviews.where((r) => r.itemType == 'song').length;
          final perfectTenCount = allReviews.where((r) => r.rating >= 10.0).length;

          if (allReviews.isEmpty) {
            return FadeTransition(
              opacity: _headerFade,
              child: Center(
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
                          Icons.album_outlined,
                          size: 48,
                          color: AppColors.acidLime,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isMe ? 'NO RELEASES RATED YET' : 'NO RELEASES RATED',
                        textAlign: TextAlign.center,
                        style: AppTypography.displaySmall(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMe
                            ? 'Whenever you score an album or single, it will automatically populate your comprehensive music archive here.'
                            : 'This critic has not rated any releases yet.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      BrutalistButton(
                        label: isMe ? 'DISCOVER MUSIC' : 'GO BACK',
                        icon: isMe ? Icons.search : Icons.arrow_back,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final avgScore = allReviews.isNotEmpty
              ? allReviews.map((r) => r.rating).reduce((a, b) => a + b) / allReviews.length
              : 0.0;

          return Column(
            children: [
              // Header Controls (Search, Filters, View Mode)
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
                    ),
                    child: Column(
                      children: [
                        // Quick Stats Strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            border: Border.all(color: AppColors.borderSubtle),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _MiniStat(
                                label: 'TOTAL RATED',
                                value: '${allReviews.length}',
                                accentColor: AppColors.textPrimary,
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              _MiniStat(
                                label: 'AVG SCORE',
                                value: avgScore.toStringAsFixed(1),
                                accentColor: AppColors.acidLime,
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              _MiniStat(
                                label: 'LPS',
                                value: '$albumCount',
                                accentColor: AppColors.acidLime,
                              ),
                              Container(width: 1, height: 24, color: AppColors.border),
                              _MiniStat(
                                label: 'TRACKS',
                                value: '$songCount',
                                accentColor: AppColors.cyberCyan,
                              ),
                            ],
                          ),
                        ),

                        // Search Box
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
                              hintText: 'SEARCH BY TITLE, ARTIST, OR TAGS...',
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

                        // Filter Pills & View Switcher Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Filter Pills
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _FilterPill(
                                      label: 'ALL (${allReviews.length})',
                                      isSelected: _filter == RatedFilter.all,
                                      accentColor: AppColors.textPrimary,
                                      onTap: () => setState(() => _filter = RatedFilter.all),
                                    ),
                                    const SizedBox(width: 6),
                                    _FilterPill(
                                      label: 'LPS ($albumCount)',
                                      isSelected: _filter == RatedFilter.albums,
                                      accentColor: AppColors.acidLime,
                                      onTap: () => setState(() => _filter = RatedFilter.albums),
                                    ),
                                    if (epCount > 0) ...[
                                      const SizedBox(width: 6),
                                      _FilterPill(
                                        label: 'EPS ($epCount)',
                                        isSelected: _filter == RatedFilter.eps,
                                        accentColor: AppColors.electricPink,
                                        onTap: () => setState(() => _filter = RatedFilter.eps),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                    _FilterPill(
                                      label: 'TRACKS ($songCount)',
                                      isSelected: _filter == RatedFilter.songs,
                                      accentColor: AppColors.cyberCyan,
                                      onTap: () => setState(() => _filter = RatedFilter.songs),
                                    ),
                                    if (perfectTenCount > 0) ...[
                                      const SizedBox(width: 6),
                                      _FilterPill(
                                        label: '10S ($perfectTenCount)',
                                        isSelected: _filter == RatedFilter.perfect10s,
                                        accentColor: AppColors.electricPink,
                                        onTap: () => setState(() => _filter = RatedFilter.perfect10s),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Sort dropdown
                            PopupMenuButton<_RatedSort>(
                              tooltip: 'Sort Options',
                              color: AppColors.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              onSelected: (sort) => setState(() => _sort = sort),
                              itemBuilder: (context) => [
                                _buildSortItem(_RatedSort.newest, 'NEWEST RATED'),
                                _buildSortItem(_RatedSort.oldest, 'OLDEST RATED'),
                                _buildSortItem(_RatedSort.highestScore, 'HIGHEST SCORE'),
                                _buildSortItem(_RatedSort.lowestScore, 'LOWEST SCORE'),
                                _buildSortItem(_RatedSort.titleAZ, 'TITLE (A-Z)'),
                                _buildSortItem(_RatedSort.artistAZ, 'ARTIST (A-Z)'),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceCard,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      _sortLabel,
                                      style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // View Mode Toggle (Grid vs List)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _viewMode = _RatedViewMode.grid),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: _viewMode == _RatedViewMode.grid
                                          ? AppColors.surfaceElevated
                                          : Colors.transparent,
                                      child: Icon(
                                        Icons.grid_view,
                                        size: 16,
                                        color: _viewMode == _RatedViewMode.grid
                                            ? AppColors.acidLime
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() => _viewMode = _RatedViewMode.list),
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      color: _viewMode == _RatedViewMode.list
                                          ? AppColors.surfaceElevated
                                          : Colors.transparent,
                                      child: Icon(
                                        Icons.view_agenda_outlined,
                                        size: 16,
                                        color: _viewMode == _RatedViewMode.list
                                            ? AppColors.acidLime
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Releases Display (Grid or List)
              Expanded(
                child: displayedReleases.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 14),
                              Text(
                                'NO MATCHING RELEASES FOUND',
                                style: AppTypography.displaySmall(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Try clearing your search query or switching filters.',
                                style: AppTypography.bodySmall(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 18),
                              BrutalistButton(
                                label: 'RESET SEARCH',
                                icon: Icons.refresh,
                                isSmall: true,
                                backgroundColor: AppColors.surfaceElevated,
                                textColor: AppColors.textPrimary,
                                borderColor: AppColors.border,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _filter = RatedFilter.all;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : _viewMode == _RatedViewMode.grid
                        ? GridView.builder(
                            key: ValueKey('grid_${_filter.name}_${_sort.name}_${_searchQuery.isNotEmpty}'),
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: displayedReleases.length,
                            itemBuilder: (context, index) {
                              final review = displayedReleases[index];
                              return _RatedPosterCard(
                                review: review,
                                scoreColor: _getScoreColor(review.rating),
                                onTap: () => _navigateToReview(context, review),
                              );
                            },
                          )
                        : ListView.separated(
                            key: ValueKey('list_${_filter.name}_${_sort.name}_${_searchQuery.isNotEmpty}'),
                            padding: const EdgeInsets.all(16),
                            itemCount: displayedReleases.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final review = displayedReleases[index];
                              return _RatedListCard(
                                review: review,
                                scoreColor: _getScoreColor(review.rating),
                                onTap: () => _navigateToReview(context, review),
                              );
                            },
                          ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.acidLime),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load rated releases: $err'),
        ),
      ),
    );
  }

  void _navigateToReview(BuildContext context, Review review) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(review: review),
      ),
    );
  }

  PopupMenuItem<_RatedSort> _buildSortItem(_RatedSort value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(
        label,
        style: AppTypography.monoLabel(
          color: _sort == value ? AppColors.acidLime : AppColors.textPrimary,
          fontSize: 10,
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case _RatedSort.newest:
        return 'NEWEST';
      case _RatedSort.oldest:
        return 'OLDEST';
      case _RatedSort.highestScore:
        return 'TOP SCORE';
      case _RatedSort.lowestScore:
        return 'LOW SCORE';
      case _RatedSort.titleAZ:
        return 'TITLE A-Z';
      case _RatedSort.artistAZ:
        return 'ARTIST A-Z';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.monoBadge(
            color: accentColor,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: AppTypography.monoLabel(fontSize: 7.5, color: AppColors.textMuted),
        ),
      ],
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

class _RatedPosterCard extends StatelessWidget {
  final Review review;
  final Color scoreColor;
  final VoidCallback onTap;

  const _RatedPosterCard({
    required this.review,
    required this.scoreColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAlbum = review.itemType == 'album';
    final isEp = review.itemType == 'ep';
    final badgeColor = isEp
        ? AppColors.electricPink
        : (isAlbum ? AppColors.acidLime : AppColors.cyberCyan);
    final badgeText = isEp ? 'EP' : (isAlbum ? 'LP' : 'TRACK');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border.all(color: AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with Score Overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: AlbumArtCard(
                    imageUrl: review.coverUrl,
                    showShadow: false,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: scoreColor,
                      border: Border.all(color: AppColors.pureBlack, width: 1.2),
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: const [
                        BoxShadow(color: AppColors.pureBlack, offset: Offset(1.5, 1.5), blurRadius: 0),
                      ],
                    ),
                    child: Text(
                      review.rating.toStringAsFixed(1),
                      style: AppTypography.monoBadge(
                        color: AppColors.pureBlack,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review.musicItemName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.displaySmall(fontSize: 11),
            ),
            const SizedBox(height: 1),
            Text(
              review.artistName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 8.5),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: badgeColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(1),
              ),
              child: Text(
                badgeText,
                style: AppTypography.monoBadge(
                  color: badgeColor,
                  fontSize: 7.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatedListCard extends StatelessWidget {
  final Review review;
  final Color scoreColor;
  final VoidCallback onTap;

  const _RatedListCard({
    required this.review,
    required this.scoreColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAlbum = review.itemType == 'album';
    final isEp = review.itemType == 'ep';
    final badgeColor = isEp
        ? AppColors.electricPink
        : (isAlbum ? AppColors.acidLime : AppColors.cyberCyan);
    final badgeText = isEp ? 'EP' : (isAlbum ? 'LP' : 'TRACK');
    final formattedDate = DateFormat('MMM d, yyyy').format(review.createdAt).toUpperCase();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
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
              size: 68,
              showShadow: false,
            ),
            const SizedBox(width: 12),
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
                          color: badgeColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: badgeColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTypography.monoBadge(
                            color: badgeColor,
                            fontSize: 7.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 8.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    review.musicItemName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.displaySmall(fontSize: 13),
                  ),
                  Text(
                    review.artistName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.monoLabel(color: AppColors.textSecondary, fontSize: 9.5),
                  ),
                  if (review.headline.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '“${review.headline}”',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: scoreColor,
                border: Border.all(color: AppColors.pureBlack, width: 1.5),
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(color: AppColors.pureBlack, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    review.rating.toStringAsFixed(1),
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '/10',
                    style: AppTypography.monoBadge(
                      color: AppColors.pureBlack.withValues(alpha: 0.7),
                      fontSize: 7,
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
