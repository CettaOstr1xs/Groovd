import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/review.dart';
import '../../../state/review_providers.dart';
import '../../widgets/brutalist_button.dart';
import '../../widgets/review_card.dart';
import '../review/review_detail_screen.dart';

enum _LoggedReviewsFilter { all, albums, songs }
enum _LoggedReviewsSort { newest, oldest, highestScore, lowestScore }

class LoggedReviewsScreen extends ConsumerStatefulWidget {
  const LoggedReviewsScreen({super.key});

  /// Custom neo-brutalist smooth slide and fade route transition
  static Route<T> route<T>() {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => const LoggedReviewsScreen(),
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
  ConsumerState<LoggedReviewsScreen> createState() => _LoggedReviewsScreenState();
}

class _LoggedReviewsScreenState extends ConsumerState<LoggedReviewsScreen>
    with SingleTickerProviderStateMixin {
  _LoggedReviewsFilter _filter = _LoggedReviewsFilter.all;
  _LoggedReviewsSort _sort = _LoggedReviewsSort.newest;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
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
    var filtered = reviews.where((r) => r.hasWrittenReview).toList();

    // Filter by type
    if (_filter == _LoggedReviewsFilter.albums) {
      filtered = filtered.where((r) => r.itemType == 'album').toList();
    } else if (_filter == _LoggedReviewsFilter.songs) {
      filtered = filtered.where((r) => r.itemType == 'song').toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((r) {
        final title = r.musicItemName.toLowerCase();
        final artist = r.artistName.toLowerCase();
        final headline = r.headline.toLowerCase();
        final body = r.body.toLowerCase();
        final tags = r.tags.map((t) => t.toLowerCase()).join(' ');
        return title.contains(q) ||
            artist.contains(q) ||
            headline.contains(q) ||
            body.contains(q) ||
            tags.contains(q);
      }).toList();
    }

    // Sort
    final sorted = List<Review>.from(filtered);
    switch (_sort) {
      case _LoggedReviewsSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _LoggedReviewsSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _LoggedReviewsSort.highestScore:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _LoggedReviewsSort.lowestScore:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }

    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Text('MY LOGGED REVIEWS', style: AppTypography.displaySmall()),
            const SizedBox(width: 8),
            reviewsAsync.when(
              data: (reviews) {
                final count = reviews.where((r) => r.hasWrittenReview).length;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 10),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: reviewsAsync.when(
        data: (allReviews) {
          final writtenReviews = allReviews.where((r) => r.hasWrittenReview).toList();
          final displayedReviews = _applyFiltersAndSort(writtenReviews);

          final albumCount = writtenReviews.where((r) => r.itemType == 'album').length;
          final songCount = writtenReviews.where((r) => r.itemType == 'song').length;

          if (writtenReviews.isEmpty) {
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
                          Icons.rate_review_outlined,
                          size: 48,
                          color: AppColors.acidLime,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'NO WRITTEN CRITIQUES YET',
                        textAlign: TextAlign.center,
                        style: AppTypography.displaySmall(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When you write detailed commentary and log critiques for albums or tracks, they will be archived here.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      BrutalistButton(
                        label: 'DISCOVER MUSIC',
                        icon: Icons.search,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Search & Filter Header Container (Smooth Slide & Fade In)
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
                        // Search box
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
                              hintText: 'SEARCH IN REVIEWS, TAGS, HEADLINES...',
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

                        // Filter and Sort row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Filter Pills
                            Row(
                              children: [
                                _FilterPill(
                                  label: 'ALL (${writtenReviews.length})',
                                  isSelected: _filter == _LoggedReviewsFilter.all,
                                  accentColor: AppColors.textPrimary,
                                  onTap: () => setState(() => _filter = _LoggedReviewsFilter.all),
                                ),
                                const SizedBox(width: 6),
                                _FilterPill(
                                  label: 'LPS ($albumCount)',
                                  isSelected: _filter == _LoggedReviewsFilter.albums,
                                  accentColor: AppColors.acidLime,
                                  onTap: () => setState(() => _filter = _LoggedReviewsFilter.albums),
                                ),
                                const SizedBox(width: 6),
                                _FilterPill(
                                  label: 'SONGS ($songCount)',
                                  isSelected: _filter == _LoggedReviewsFilter.songs,
                                  accentColor: AppColors.cyberCyan,
                                  onTap: () => setState(() => _filter = _LoggedReviewsFilter.songs),
                                ),
                              ],
                            ),

                            // Sort dropdown
                            PopupMenuButton<_LoggedReviewsSort>(
                              tooltip: 'Sort Options',
                              color: AppColors.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              onSelected: (sort) => setState(() => _sort = sort),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: _LoggedReviewsSort.newest,
                                  child: Text(
                                    'NEWEST FIRST',
                                    style: AppTypography.monoLabel(
                                      color: _sort == _LoggedReviewsSort.newest ? AppColors.acidLime : AppColors.textPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _LoggedReviewsSort.oldest,
                                  child: Text(
                                    'OLDEST FIRST',
                                    style: AppTypography.monoLabel(
                                      color: _sort == _LoggedReviewsSort.oldest ? AppColors.acidLime : AppColors.textPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _LoggedReviewsSort.highestScore,
                                  child: Text(
                                    'HIGHEST SCORE',
                                    style: AppTypography.monoLabel(
                                      color: _sort == _LoggedReviewsSort.highestScore ? AppColors.acidLime : AppColors.textPrimary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _LoggedReviewsSort.lowestScore,
                                  child: Text(
                                    'LOWEST SCORE',
                                    style: AppTypography.monoLabel(
                                      color: _sort == _LoggedReviewsSort.lowestScore ? AppColors.acidLime : AppColors.textPrimary,
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
                                      _sortLabel,
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
                ),
              ),

              // Reviews Feed List or Empty Search State with AnimatedSwitcher
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: displayedReviews.isEmpty
                      ? Center(
                          key: const ValueKey('empty_search'),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 40, color: AppColors.textMuted),
                                const SizedBox(height: 14),
                                Text(
                                  'NO MATCHING REVIEWS FOUND',
                                  style: AppTypography.displaySmall(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try clearing your search query or switching category filters.',
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
                                      _filter = _LoggedReviewsFilter.all;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          key: ValueKey('list_${_filter.name}_${_sort.name}_${_searchQuery.isNotEmpty}'),
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedReviews.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final review = displayedReviews[index];
                            return _StaggeredCardEntrance(
                              controller: _entranceController,
                              index: index,
                              child: ReviewCard(
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
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.acidLime),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load reviews: $err'),
        ),
      ),
    );
  }

  String get _sortLabel {
    switch (_sort) {
      case _LoggedReviewsSort.newest:
        return 'NEWEST';
      case _LoggedReviewsSort.oldest:
        return 'OLDEST';
      case _LoggedReviewsSort.highestScore:
        return 'TOP SCORE';
      case _LoggedReviewsSort.lowestScore:
        return 'LOW SCORE';
    }
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

class _StaggeredCardEntrance extends StatelessWidget {
  final Animation<double> controller;
  final int index;
  final Widget child;

  const _StaggeredCardEntrance({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final clampedIndex = index.clamp(0, 6);
    final start = (0.10 + (clampedIndex * 0.07)).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

