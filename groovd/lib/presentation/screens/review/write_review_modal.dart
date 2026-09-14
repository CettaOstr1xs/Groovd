import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/presentation/widgets/brutalist_button.dart';

class WriteReviewModal extends ConsumerStatefulWidget {
  final MusicItem musicItem;

  const WriteReviewModal({super.key, required this.musicItem});

  static Future<void> show(BuildContext context, MusicItem musicItem) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WriteReviewModal(musicItem: musicItem),
    );
  }

  @override
  ConsumerState<WriteReviewModal> createState() => _WriteReviewModalState();
}

class _WriteReviewModalState extends ConsumerState<WriteReviewModal> {
  double _rating = 8.5;
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;
  bool _isDragging = false;

  final List<String> _availableTags = [
    '#AOTY',
    '#MASTERPIECE',
    '#TIMELESS',
    '#PRODUCTION_GOD',
    '#HEAVY_ROTATION',
    '#LYRICS_MATTER',
    '#REPEAT_ONE',
    '#OVERRATED',
    '#SKIP',
    '#GROWER',
  ];

  Color get _scoreColor {
    if (_rating >= 9.0) return AppColors.acidLime;
    if (_rating >= 8.0) return AppColors.cyberCyan;
    if (_rating >= 6.5) return AppColors.electricPink;
    if (_rating >= 5.0) return const Color(0xFFFFB800);
    return AppColors.vermillion;
  }

  String get _descriptor {
    if (_rating >= 9.5) return 'MASTERPIECE';
    if (_rating >= 8.5) return 'CRITIC\'S ESSENTIAL';
    if (_rating >= 7.5) return 'UNIVERSAL ACCLAIM';
    if (_rating >= 6.0) return 'SOLID LISTEN';
    if (_rating >= 4.5) return 'DIVISIVE';
    return 'CRITICAL SKIP';
  }

  @override
  void dispose() {
    _headlineController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_headlineController.text.trim().isEmpty && _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PLEASE WRITE A HEADLINE OR REVIEW',
            style: AppTypography.monoBadge(color: AppColors.white),
          ),
          backgroundColor: AppColors.vermillion,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final userId = ref.read(currentUserIdProvider);
    final userName = ref.read(currentUserNameProvider);
    final userHandle = ref.read(currentUserHandleProvider);

    final newReview = Review(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      musicItemId: widget.musicItem.id,
      musicItemName: widget.musicItem.name,
      artistName: widget.musicItem.artist,
      coverUrl: widget.musicItem.coverUrl,
      itemType: widget.musicItem.isAlbum ? 'album' : 'song',
      userId: userId,
      userName: userName,
      userHandle: userHandle,
      rating: _rating,
      headline: _headlineController.text.trim(),
      body: _bodyController.text.trim(),
      tags: _selectedTags,
      createdAt: DateTime.now(),
      likesCount: 0,
    );

    try {
      await ref.read(reviewControllerProvider).submitReview(newReview);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'REVIEW DISPATCHED TO ARCHIVE',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
            backgroundColor: AppColors.acidLime,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: $e'),
            backgroundColor: AppColors.vermillion,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: bottomInset > 0 ? bottomInset : 16,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.borderBold, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.pureBlack,
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderBold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOG YOUR REVIEW',
                      style: AppTypography.displaySmall(),
                    ),
                    Text(
                      '${widget.musicItem.name} — ${widget.musicItem.artist}'.toUpperCase(),
                      style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Giant Score Live Display with bounce
            Center(
              child: Column(
                children: [
                  AnimatedScale(
                    scale: _isDragging ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: _scoreColor,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.pureBlack, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: _scoreColor.withValues(alpha: _isDragging ? 0.6 : 0.0),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                          const BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _rating.toStringAsFixed(1),
                            style: AppTypography.scoreGiant(color: AppColors.pureBlack),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '/10',
                            style: AppTypography.monoBadge(
                              color: AppColors.pureBlack.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      _descriptor,
                      style: AppTypography.monoBadge(color: _scoreColor, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rating Slider with tactile interaction
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _scoreColor,
                inactiveTrackColor: AppColors.surfaceElevated,
                thumbColor: _scoreColor,
                overlayColor: _scoreColor.withValues(alpha: 0.2),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _rating,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                onChangeStart: (_) {
                  setState(() => _isDragging = true);
                },
                onChangeEnd: (_) {
                  setState(() => _isDragging = false);
                },
                onChanged: (val) {
                  setState(() {
                    _rating = double.parse(val.toStringAsFixed(1));
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // Headline Input
            Text(
              'HEADLINE // ONE-LINER',
              style: AppTypography.monoLabel(fontSize: 10),
            ),
              const SizedBox(height: 6),
              TextField(
                controller: _headlineController,
                style: AppTypography.headline(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Sum up your thoughts in one punchy line...',
                  hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 16),

              // Body Input
              Text(
                'CRITICAL TAKE // IN-DEPTH REVIEW',
                style: AppTypography.monoLabel(fontSize: 10),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                style: AppTypography.bodyLarge(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Production highlights, standout lyricism, emotional impact, soundscapes...',
                  hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
                ),
              ),

              const SizedBox(height: 16),

              // Tags
              Text(
                'VIBES & TAGS',
                style: AppTypography.monoLabel(fontSize: 10),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    labelStyle: AppTypography.monoBadge(
                      color: isSelected ? AppColors.pureBlack : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.acidLime,
                    backgroundColor: AppColors.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? AppColors.acidLime : AppColors.border,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    showCheckmark: false,
                    onSelected: (selected) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Submit Button
              BrutalistButton(
                label: _isSubmitting ? 'PUBLISHING...' : 'PUBLISH REVIEW',
                icon: Icons.check,
                isFullWidth: true,
                backgroundColor: AppColors.acidLime,
                textColor: AppColors.pureBlack,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      );
    }
  }
