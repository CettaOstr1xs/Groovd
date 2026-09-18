import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/data/models/music_item.dart';
import 'package:groovd/data/models/review.dart';
import 'package:groovd/state/review_providers.dart';
import 'package:groovd/state/user_profile_provider.dart';
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
  static const String _customTagsKey = 'groovd_custom_tags_v1';

  double _rating = 8.5;
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _customTags = [];
  bool _isSubmitting = false;
  bool _isDragging = false;

  final List<String> _defaultTags = [
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

  @override
  void initState() {
    super.initState();
    _loadCustomTags();
    _headlineController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  Future<void> _loadCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_customTagsKey) ?? [];
      if (saved.isNotEmpty && mounted) {
        setState(() {
          _customTags.addAll(saved);
        });
      }
    } catch (_) {}
  }

  Future<void> _addCustomTag(String raw) async {
    final clean = raw.trim();
    if (clean.isEmpty) return;

    // Format tag: prepend # if missing, replace spaces with underscores, uppercase
    String tag = clean.toUpperCase().replaceAll(' ', '_');
    if (!tag.startsWith('#')) {
      tag = '#$tag';
    }

    if (!_customTags.contains(tag) && !_defaultTags.contains(tag)) {
      _customTags.add(tag);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_customTagsKey, _customTags);
      } catch (_) {}
    }

    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
    }

    _customTagController.clear();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  Future<void> _removeCustomTag(String tag) async {
    _customTags.remove(tag);
    _selectedTags.remove(tag);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customTagsKey, _customTags);
    } catch (_) {}
    setState(() {});
  }

  bool get _hasWrittenText =>
      _headlineController.text.trim().isNotEmpty || _bodyController.text.trim().isNotEmpty;

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
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final profile = ref.read(userProfileProvider);
    final userId = profile.userId;
    final userName = profile.userName;
    final userHandle = profile.userHandle;

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
      await ref
          .read(reviewControllerProvider)
          .submitReview(newReview)
          .timeout(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newReview.hasWrittenReview
                  ? 'CRITIQUE DISPATCHED TO ARCHIVE'
                  : 'RATING LOGGED TO DOSSIER',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
            backgroundColor: AppColors.acidLime,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SAVED TO LOCAL LOG',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
            backgroundColor: AppColors.cyberCyan,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final profile = ref.watch(userProfileProvider);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LOG YOUR REVIEW',
                        style: AppTypography.displaySmall(),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.musicItem.name} — ${widget.musicItem.artist}'.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Critic Posting Persona Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: profile.avatarPath != null ? AppColors.pureBlack : AppColors.acidLime,
                      border: Border.all(color: AppColors.acidLime, width: 1.0),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                    alignment: Alignment.center,
                    child: profile.avatarPath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(1),
                            child: Image.file(
                              File(profile.avatarPath!),
                              width: 22,
                              height: 22,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                profile.userName.isNotEmpty ? profile.userName[0].toUpperCase() : 'C',
                                style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 10),
                              ),
                            ),
                          )
                        : Text(
                            profile.userName.isNotEmpty ? profile.userName[0].toUpperCase() : 'C',
                            style: AppTypography.monoBadge(color: AppColors.pureBlack, fontSize: 10),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'POSTING AS ',
                    style: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9),
                  ),
                  Expanded(
                    child: Text(
                      '${profile.userName.toUpperCase()} (${profile.userHandle})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoBadge(color: AppColors.acidLime, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ),

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

              // Vibes & Custom Tags Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'VIBES & TAGS',
                    style: AppTypography.monoLabel(fontSize: 10),
                  ),
                  Flexible(
                    child: Text(
                      'CREATE OR SELECT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.monoBadge(color: AppColors.textMuted, fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Custom Tag Input Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customTagController,
                      style: AppTypography.monoBadge(color: AppColors.textPrimary, fontSize: 11),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'CREATE TAG (e.g. SHOEGAZE_GRAIL)...',
                        hintStyle: AppTypography.monoLabel(color: AppColors.textMuted, fontSize: 9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.tag, size: 16, color: AppColors.acidLime),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      onSubmitted: (val) => _addCustomTag(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BrutalistButton(
                    label: '+ ADD',
                    isSmall: true,
                    backgroundColor: AppColors.surfaceElevated,
                    textColor: AppColors.acidLime,
                    borderColor: AppColors.acidLime,
                    onPressed: () => _addCustomTag(_customTagController.text),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tags Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...{..._defaultTags, ..._customTags}.map((tag) {
                    final isSelected = _selectedTags.contains(tag);
                    final isCustom = _customTags.contains(tag);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tag),
                          if (isCustom) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeCustomTag(tag),
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: isSelected ? AppColors.pureBlack : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
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
                  }),
                ],
              ),

              const SizedBox(height: 24),

              // Submit Button (Dynamic for written review vs quick rating)
              BrutalistButton(
                label: _isSubmitting
                    ? 'PUBLISHING...'
                    : _hasWrittenText
                        ? 'PUBLISH CRITIQUE'
                        : 'LOG SCORE [${_rating.toStringAsFixed(1)}] // QUICK RATE',
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
