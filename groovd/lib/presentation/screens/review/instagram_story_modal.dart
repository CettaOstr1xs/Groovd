import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/review.dart';
import '../../../state/user_profile_provider.dart';
import '../../widgets/brutalist_button.dart';
import 'critique_story_card.dart';

class InstagramStoryModal extends ConsumerStatefulWidget {
  final Review review;

  const InstagramStoryModal({super.key, required this.review});

  static Future<void> show(BuildContext context, Review review) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstagramStoryModal(review: review),
    );
  }

  @override
  ConsumerState<InstagramStoryModal> createState() => _InstagramStoryModalState();
}

class _InstagramStoryModalState extends ConsumerState<InstagramStoryModal> {
  final GlobalKey _repaintKey = GlobalKey();
  StoryTheme _currentTheme = StoryTheme.darkMatrix;
  StoryLayout _currentLayout = StoryLayout.fullCritique;
  bool _isExporting = false;

  Future<File?> _captureStoryImage() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/groovd_story_${widget.review.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturing story image: $e');
      return null;
    }
  }

  static const MethodChannel _storyChannel = MethodChannel('com.example.groovd/instagram_stories');

  Future<void> _shareToInstagramStories() async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();

    try {
      final file = await _captureStoryImage();
      if (!mounted) return;

      if (file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('UNABLE TO GENERATE STORY IMAGE', style: AppTypography.monoBadge(color: AppColors.electricPink)),
          ),
        );
        return;
      }

      bool directSuccess = false;

      if (Platform.isAndroid) {
        try {
          final result = await _storyChannel.invokeMethod<bool>('shareToInstagramStories', {
            'filePath': file.path,
          });
          directSuccess = result == true;
        } on PlatformException catch (e) {
          debugPrint('Instagram Stories direct share error: $e');
          directSuccess = false;
        }
      }

      if (directSuccess) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Fallback: If Instagram not installed or failed, notify user and open system share
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text(
                'INSTAGRAM APP NOT DETECTED — OPENING SHARE SHEET',
                style: AppTypography.monoBadge(color: AppColors.electricPink),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }

        final shareText = '“${widget.review.headline}”\n'
            '${widget.review.musicItemName} by ${widget.review.artistName} — Scored ${widget.review.scoreFormatted}/10 on Groovd';

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'image/png')],
            text: shareText,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('SHARE FAILED: $e', style: AppTypography.monoBadge(color: AppColors.electricPink)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _saveStoryImage() async {
    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();

    try {
      final file = await _captureStoryImage();
      if (!mounted) return;

      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'STORY IMAGE EXPORTED READY TO SHARE',
              style: AppTypography.monoBadge(color: AppColors.acidLime),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('FAILED TO SAVE: $e', style: AppTypography.monoBadge(color: AppColors.electricPink)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _copyCritiqueText() {
    final text = '“${widget.review.headline}”\n'
        '${widget.review.musicItemName} by ${widget.review.artistName} — Scored ${widget.review.scoreFormatted}/10 on Groovd\n'
        '${widget.review.body}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('CRITIQUE COPIED TO CLIPBOARD', style: AppTypography.monoBadge(color: AppColors.acidLime)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isCurrentUser = widget.review.userId == profile.userId || widget.review.userId == 'user_me';
    final customAvatarPath = isCurrentUser ? profile.avatarPath : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 2.5),
        ),
      ),
      child: Column(
        children: [
          // Top Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHARE CRITIQUE',
                      style: AppTypography.displaySmall(fontSize: 16),
                    ),
                    Text(
                      'INSTANT 9:16 STORY DESIGNER',
                      style: AppTypography.monoLabel(
                        color: AppColors.acidLime,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Designer Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  // 9:16 Visual Preview
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 380,
                      ),
                      decoration: BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _repaintKey,
                          child: CritiqueStoryCard(
                            review: widget.review,
                            theme: _currentTheme,
                            layout: _currentLayout,
                            avatarPath: customAvatarPath,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Theme Selection Pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STORY THEME',
                        style: AppTypography.monoLabel(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _currentTheme.name.toUpperCase(),
                        style: AppTypography.monoBadge(
                          fontSize: 9,
                          color: AppColors.acidLime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ThemeOption(
                        label: 'DARK',
                        color: const Color(0xFF0C0D0E),
                        accentColor: AppColors.acidLime,
                        isSelected: _currentTheme == StoryTheme.darkMatrix,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentTheme = StoryTheme.darkMatrix);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'ACID',
                        color: AppColors.acidLime,
                        accentColor: Colors.black,
                        isSelected: _currentTheme == StoryTheme.acidBrutal,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentTheme = StoryTheme.acidBrutal);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'CYBER',
                        color: const Color(0xFF07181F),
                        accentColor: AppColors.cyberCyan,
                        isSelected: _currentTheme == StoryTheme.cyberCyan,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentTheme = StoryTheme.cyberCyan);
                        },
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'ZINE',
                        color: const Color(0xFFF4EFE6),
                        accentColor: Colors.black,
                        isSelected: _currentTheme == StoryTheme.zinePaper,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentTheme = StoryTheme.zinePaper);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Layout Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LAYOUT MODE',
                        style: AppTypography.monoLabel(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          _LayoutPill(
                            label: 'FULL CRITIQUE',
                            isSelected: _currentLayout == StoryLayout.fullCritique,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _currentLayout = StoryLayout.fullCritique);
                            },
                          ),
                          const SizedBox(width: 8),
                          _LayoutPill(
                            label: 'POSTER CARD',
                            isSelected: _currentLayout == StoryLayout.posterCard,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _currentLayout = StoryLayout.posterCard);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Primary Action: Share to Instagram Stories
                  SizedBox(
                    width: double.infinity,
                    child: BrutalistButton(
                      label: _isExporting ? 'EXPORTING STORY...' : 'SHARE TO INSTAGRAM STORIES',
                      icon: Icons.auto_stories,
                      backgroundColor: AppColors.acidLime,
                      textColor: AppColors.pureBlack,
                      onPressed: _isExporting ? () {} : _shareToInstagramStories,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Actions: Save Image & Copy Text
                  Row(
                    children: [
                      Expanded(
                        child: BrutalistButton(
                          label: 'SAVE STORY',
                          icon: Icons.download,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: AppColors.textPrimary,
                          isSmall: true,
                          onPressed: _isExporting ? () {} : _saveStoryImage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BrutalistButton(
                          label: 'COPY TEXT',
                          icon: Icons.copy,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: AppColors.textPrimary,
                          isSmall: true,
                          onPressed: _copyCritiqueText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final Color color;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.color,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isSelected ? accentColor : AppColors.borderBold,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.35),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.monoBadge(
              color: color == const Color(0xFFF4EFE6) || color == AppColors.acidLime ? Colors.black : Colors.white,
              fontSize: 9,
            ),
          ),
        ),
      ),
    );
  }
}

class _LayoutPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayoutPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.acidLime : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: isSelected ? AppColors.acidLime : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.monoBadge(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
