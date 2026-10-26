import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/wishlist_item.dart';
import 'package:groovd/presentation/screens/detail/music_detail_screen.dart';
import 'package:groovd/presentation/screens/review/write_review_modal.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';

/// Interactive Neo-Brutalist Sonic Roulette / Roll Modal for the Critic Wantlist.
/// Features a horizontal game-style case opening / roulette reel scrolling from RIGHT to LEFT.
class WishlistRollModal extends StatefulWidget {
  final List<WishlistItem> items;

  const WishlistRollModal({
    super.key,
    required this.items,
  });

  static Future<void> show(BuildContext context, {required List<WishlistItem> items}) {
    if (items.isEmpty) return Future.value();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WishlistRollModal(items: items),
    );
  }

  @override
  State<WishlistRollModal> createState() => _WishlistRollModalState();
}

class _WishlistRollModalState extends State<WishlistRollModal>
    with TickerProviderStateMixin {
  late final AnimationController _reelController;
  late final CurvedAnimation _reelCurveAnimation;
  late final AnimationController _revealController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isRolling = true;
  List<WishlistItem> _tapeItems = const [];
  late WishlistItem _winnerItem;
  final math.Random _random = math.Random();

  static const int _tapeLength = 48;
  static const int _winnerIndex = 36;
  static const double _cardWidth = 110.0;
  static const double _cardMargin = 12.0;
  static const double _slotWidth = _cardWidth + _cardMargin; // 122.0

  int _lastTickIndex = -1;

  @override
  void initState() {
    super.initState();

    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _reelCurveAnimation = CurvedAnimation(
      parent: _reelController,
      curve: Curves.easeOutCubic,
    );

    _reelController.addListener(_onReelTick);
    _reelController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _isRolling = false;
          });
          _revealController.forward();
        }
      }
    });

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealController,
        curve: Curves.easeOut,
      ),
    );

    _startRollSequence();
  }

  @override
  void dispose() {
    _reelController.dispose();
    _revealController.dispose();
    super.dispose();
  }

  void _onReelTick() {
    if (!mounted || !_isRolling || _tapeItems.isEmpty) return;
    final progress = _reelCurveAnimation.value;
    final centerCardIndex = (progress * _winnerIndex).floor();

    if (centerCardIndex != _lastTickIndex && centerCardIndex >= 0 && centerCardIndex < _tapeItems.length) {
      _lastTickIndex = centerCardIndex;
      if (centerCardIndex >= _winnerIndex - 3) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  void _startRollSequence() {
    if (widget.items.isEmpty) return;
    final winner = widget.items[_random.nextInt(widget.items.length)];
    _winnerItem = winner;

    // Generate 48 items tape with designated winner locked at index 36
    _tapeItems = List.generate(_tapeLength, (index) {
      if (index == _winnerIndex) {
        return winner;
      }
      if (widget.items.length > 1) {
        WishlistItem candidate;
        do {
          candidate = widget.items[_random.nextInt(widget.items.length)];
        } while (candidate == winner && widget.items.length > 1);
        return candidate;
      }
      return widget.items.first;
    });

    _reelController.reset();
    _revealController.reset();
    _lastTickIndex = -1;

    setState(() {
      _isRolling = true;
    });

    _reelController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      margin: const EdgeInsets.only(top: 36),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 2.5),
          left: BorderSide(color: AppColors.borderBold, width: 2.0),
          right: BorderSide(color: AppColors.borderBold, width: 2.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(0, -6),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle Indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.borderBold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isRolling ? AppColors.cyberCyan : AppColors.acidLime,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.pureBlack, width: 1.5),
                        ),
                        child: Icon(
                          _isRolling ? Icons.shuffle_rounded : Icons.casino,
                          size: 16,
                          color: AppColors.pureBlack,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isRolling
                                ? 'SONIC ROULETTE // SHUFFLING...'
                                : "TONIGHT'S CRITIC SPIN",
                            style: AppTypography.displaySmall(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isRolling
                                ? 'CYCLING THROUGH ${widget.items.length} QUEUED RELEASES'
                                : 'RANDOM PICK LOCKED FROM YOUR WANTLIST',
                            style: AppTypography.monoLabel(
                              color: _isRolling ? AppColors.cyberCyan : AppColors.acidLime,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const Divider(color: AppColors.border, height: 20, thickness: 1.5),

              // Horizontal Game Roulette Reel (Right to Left)
              LayoutBuilder(
                builder: (context, constraints) {
                  return _buildReelViewport(constraints.maxWidth);
                },
              ),

              const SizedBox(height: 14),

              // Bottom Viewport: Progress Bar during roll vs. Grand Winner Card
              if (_isRolling) ...[
                AnimatedBuilder(
                  animation: _reelCurveAnimation,
                  builder: (context, _) {
                    final percent = (_reelCurveAnimation.value * 100).toInt();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        border: Border.all(color: AppColors.cyberCyan, width: 1.5),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.cyberCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'DECIDING YOUR DESTINY [$percent%]...',
                              style: AppTypography.monoLabel(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ] else ...[
                // Winner Dossier Card
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildWinnerCard(_winnerItem.musicItem),
                  ),
                ),

                const SizedBox(height: 14),

                // Reveal Action Buttons
                Row(
                  children: [
                    // Reroll Button
                    Expanded(
                      flex: 4,
                      child: BrutalistButton(
                        label: 'REROLL [↻]',
                        icon: Icons.refresh,
                        isSmall: false,
                        backgroundColor: AppColors.surfaceElevated,
                        textColor: AppColors.cyberCyan,
                        borderColor: AppColors.cyberCyan,
                        onPressed: _startRollSequence,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Listen Now Button
                    Expanded(
                      flex: 6,
                      child: BrutalistButton(
                        label: 'LISTEN NOW // ARCHIVE',
                        icon: Icons.play_arrow,
                        isSmall: false,
                        backgroundColor: AppColors.acidLime,
                        textColor: AppColors.pureBlack,
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MusicDetailScreen(item: _winnerItem.musicItem),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BrutalistButton(
                  label: 'RATE & REVIEW NOW [★]',
                  icon: Icons.star_outline,
                  isSmall: true,
                  backgroundColor: AppColors.surfaceCard,
                  textColor: AppColors.textPrimary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    WriteReviewModal.show(context, _winnerItem.musicItem);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal Game Roulette Reel moving from Right to Left
  Widget _buildReelViewport(double viewportWidth) {
    final targetOffset = (_winnerIndex * _slotWidth) - (viewportWidth / 2) + (_cardWidth / 2);

    return Container(
      height: 185,
      decoration: const BoxDecoration(
        color: AppColors.pureBlack,
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 2.0),
          bottom: BorderSide(color: AppColors.borderBold, width: 2.0),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          // 1. Horizontal Tape of Candidate Cards (moves from Right to Left)
          Positioned.fill(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: 0,
                maxWidth: double.infinity,
                minHeight: 0,
                maxHeight: 185,
                child: AnimatedBuilder(
                  animation: _reelCurveAnimation,
                  builder: (context, _) {
                    final currentOffset = _reelCurveAnimation.value * targetOffset;
                    return Transform.translate(
                      offset: Offset(-currentOffset, 0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_tapeItems.length, (index) {
                          final item = _tapeItems[index];
                          final isWinningSlot = !_isRolling && index == _winnerIndex;
                          return _buildTapeCard(item, isWinningSlot: isWinningSlot);
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Left Edge Fade Vignette
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.pureBlack,
                      AppColors.pureBlack.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Right Edge Fade Vignette
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppColors.pureBlack,
                      AppColors.pureBlack.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Center Needle / Selector Crosshair Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Downward Needle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.acidLime,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.pureBlack, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.acidLime,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: AppColors.pureBlack,
                        ),
                      ),

                      // Center Vertical Guideline
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.acidLime.withValues(alpha: 0.75),
                        ),
                      ),

                      // Bottom Upward Needle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.acidLime,
                          borderRadius: BorderRadius.zero,
                          border: Border.all(color: AppColors.pureBlack, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.acidLime,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_drop_up,
                          size: 16,
                          color: AppColors.pureBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual card slot inside the horizontal right-to-left reel
  Widget _buildTapeCard(WishlistItem wishlistItem, {required bool isWinningSlot}) {
    final item = wishlistItem.musicItem;

    return Container(
      width: _cardWidth,
      height: 165,
      margin: const EdgeInsets.only(right: _cardMargin),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isWinningSlot ? AppColors.surfaceElevated : AppColors.surfaceCard,
        borderRadius: BorderRadius.zero, // blocky shape
        border: Border.all(
          color: isWinningSlot ? AppColors.acidLime : AppColors.border,
          width: isWinningSlot ? 2.5 : 1.5,
        ),
        boxShadow: isWinningSlot
            ? const [
                BoxShadow(
                  color: AppColors.acidLime,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: AppColors.pureBlack,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ]
            : const [
                BoxShadow(
                  color: AppColors.pureBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Album Art Frame
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.pureBlack,
              border: Border.all(color: AppColors.borderBold, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: item.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.album, size: 28, color: AppColors.textMuted),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceElevated,
                        child: const Icon(Icons.album, size: 28, color: AppColors.textMuted),
                      ),
                    )
                  : const Icon(Icons.album, size: 36, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 6),

          // Format Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: item.typeColor.withValues(alpha: 0.18),
              border: Border.all(color: item.typeColor, width: 1.0),
            ),
            child: Text(
              item.typeBadgeLabel,
              style: AppTypography.monoBadge(color: item.typeColor, fontSize: 8),
            ),
          ),
          const SizedBox(height: 4),

          // Title
          Text(
            item.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.displaySmall(fontSize: 10.5),
          ),
          const SizedBox(height: 2),

          // Artist
          Text(
            item.artist.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  /// Grand Reveal Card once roll finishes
  Widget _buildWinnerCard(MusicItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.acidLime, width: 2.5),
        borderRadius: BorderRadius.zero, // blocky shape
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album Cover Artwork
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.pureBlack,
              border: Border.all(color: AppColors.pureBlack, width: 2.0),
              borderRadius: BorderRadius.zero,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.pureBlack,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.zero,
              child: item.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceCard,
                        child: const Icon(Icons.album, size: 36, color: AppColors.textMuted),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceCard,
                        child: const Icon(Icons.album, size: 36, color: AppColors.textMuted),
                      ),
                    )
                  : const Icon(Icons.album, size: 40, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Format badge + Year tag row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.typeColor,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        item.typeBadgeLabel,
                        style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 9),
                      ),
                    ),
                    if (item.formattedYear.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• ${item.formattedYear}',
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9.5),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Title with adaptive font sizing
                Text(
                  item.name.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displaySmall(
                    fontSize: item.name.length > 25 ? 13.0 : 15.0,
                  ).copyWith(height: 1.15),
                ),
                const SizedBox(height: 4),

                // Artist
                Text(
                  item.artist.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoBadge(
                    color: AppColors.acidLime,
                    fontSize: 10,
                  ),
                ),
                if (item.trackCount > 1 || item.formattedDuration.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (item.trackCount > 1) '${item.trackCount} CUTS',
                      if (item.formattedDuration.isNotEmpty) item.formattedDuration,
                    ].join(' • '),
                    style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 8.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
