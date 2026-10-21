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
import '../../../data/models/music_item.dart';
import '../../../data/models/review.dart';
import '../../../data/services/spotify_repository.dart';
import '../../../state/music_providers.dart';
import '../../../state/user_profile_provider.dart';
import '../../../state/auth_providers.dart';
import '../../../state/review_providers.dart';
import '../../widgets/brutalist_button.dart';
import 'critique_story_card.dart';
import 'track_scorecard_story_card.dart';

class InstagramStoryModal extends ConsumerStatefulWidget {
  final Review review;
  final MusicItem? musicItem;

  const InstagramStoryModal({
    super.key,
    required this.review,
    this.musicItem,
  });

  static Future<void> show(BuildContext context, Review review, {MusicItem? musicItem}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InstagramStoryModal(review: review, musicItem: musicItem),
    );
  }

  @override
  ConsumerState<InstagramStoryModal> createState() => _InstagramStoryModalState();
}

class _InstagramStoryModalState extends ConsumerState<InstagramStoryModal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  StoryTheme _currentTheme = StoryTheme.darkMatrix;
  StoryLayout _currentLayout = StoryLayout.trackScorecard;
  bool _isAnimatedMode = true;
  bool _isExporting = false;
  String? _exportStatusText;

  late AnimationController _animController;
  double _previewProgress = 0.0;

  List<StoryTrackRating> _tracks = [];
  bool _isLoadingTracks = true;
  String? _releaseYear;

  static const MethodChannel _storyChannel = MethodChannel('com.example.groovd/instagram_stories');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..addListener(() {
        if (!_isExporting) {
          setState(() {
            _previewProgress = _animController.value;
          });
        }
      });

    _animController.forward();
    _loadTracksAndRatings();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTracksAndRatings() async {
    try {
      MusicItem? item = widget.musicItem;
      if (item == null || item.tracks.isEmpty) {
        final itemType = widget.review.itemType == 'song'
            ? MusicType.song
            : (widget.review.itemType == 'ep' ? MusicType.ep : MusicType.album);

        item = await ref.read(spotifyRepositoryProvider).getItemById(
              widget.review.musicItemId,
              type: itemType,
              name: widget.review.musicItemName,
              artist: widget.review.artistName,
            );
      }

      if (item != null && item.releaseDate.isNotEmpty) {
        final parsed = DateTime.tryParse(item.releaseDate);
        if (parsed != null) {
          _releaseYear = parsed.year.toString();
        } else {
          final yearMatch = RegExp(r'\b(19\d\d|20\d\d)\b').firstMatch(item.releaseDate);
          if (yearMatch != null) {
            _releaseYear = yearMatch.group(1);
          }
        }
      }

      final trackList = <StoryTrackRating>[];

      if (item != null && item.tracks.isNotEmpty) {
        for (int i = 0; i < item.tracks.length; i++) {
          final t = item.tracks[i];
          final rating = ref.read(trackUserRatingProvider((track: t, albumArtist: item.artist)));
          final bool hasDuplicatedTrackNumbers = item.tracks.length > 1 &&
              item.tracks[0].trackNumber == item.tracks[1].trackNumber;
          final trackNum = (t.trackNumber > 0 && !hasDuplicatedTrackNumbers)
              ? t.trackNumber
              : (i + 1);

          trackList.add(
            StoryTrackRating(
              trackNumber: trackNum,
              title: t.name,
              rating: rating,
              durationMs: t.durationMs,
            ),
          );
        }
      } else {
        // Fallback for standalone single song
        trackList.add(
          StoryTrackRating(
            trackNumber: 1,
            title: widget.review.musicItemName,
            rating: widget.review.rating,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _tracks = trackList;
          _isLoadingTracks = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading track ratings for story: $e');
      if (mounted) {
        setState(() {
          _tracks = [
            StoryTrackRating(
              trackNumber: 1,
              title: widget.review.musicItemName,
              rating: widget.review.rating,
            )
          ];
          _isLoadingTracks = false;
        });
      }
    }
  }

  void _togglePlayPause() {
    HapticFeedback.selectionClick();
    if (_animController.isAnimating) {
      _animController.stop();
    } else {
      if (_animController.isCompleted) {
        _animController.forward(from: 0.0);
      } else {
        _animController.forward();
      }
    }
    setState(() {});
  }

  void _replayAnimation() {
    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);
    setState(() {});
  }

  Future<File?> _captureStoryImage({double pixelRatio = 3.0}) async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/groovd_story_${widget.review.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('Error capturing story image: $e');
      return null;
    }
  }

  Future<void> _shareToInstagramStories() async {
    if (_isAnimatedMode) {
      await _shareAsVideoToInstagram();
      return;
    }

    setState(() {
      _isExporting = true;
      _exportStatusText = 'EXPORTING STORY IMAGE...';
    });
    HapticFeedback.mediumImpact();

    try {
      final file = await _captureStoryImage(pixelRatio: 3.0);
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
            'mimeType': 'image/png',
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

        final shareText = '${widget.review.musicItemName} by ${widget.review.artistName} — Track Scorecard on Groovd (${widget.review.scoreFormatted}/10)';

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
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatusText = null;
        });
      }
    }
  }

  Future<void> _shareAsVideoToInstagram() async {
    setState(() {
      _isExporting = true;
      _exportStatusText = 'RENDERING ANIMATION...';
    });
    HapticFeedback.mediumImpact();

    Directory? framesDir;
    try {
      final tempDir = await getTemporaryDirectory();
      framesDir = Directory('${tempDir.path}/groovd_story_frames_${DateTime.now().millisecondsSinceEpoch}');
      await framesDir.create(recursive: true);

      final framePaths = <String>[];
      const int totalFrames = 18; // 18 keyframes across 3.5 seconds

      if (_animController.isAnimating) {
        _animController.stop();
      }

      for (int i = 0; i <= totalFrames; i++) {
        final progress = i / totalFrames;
        setState(() {
          _previewProgress = progress;
          _exportStatusText = 'RENDERING FRAME ${i + 1}/${totalFrames + 1}...';
        });

        await WidgetsBinding.instance.endOfFrame;

        final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;

        final ui.Image image = await boundary.toImage(pixelRatio: 1.8);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) continue;

        final frameFile = File('${framesDir.path}/frame_${i.toString().padLeft(4, '0')}.png');
        await frameFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        framePaths.add(frameFile.path);
      }

      setState(() => _exportStatusText = 'ENCODING MP4 VIDEO...');

      final videoPath = '${tempDir.path}/groovd_story_${widget.review.id}_${DateTime.now().millisecondsSinceEpoch}.mp4';

      bool directSuccess = false;

      if (Platform.isAndroid && framePaths.isNotEmpty) {
        try {
          final encodeResult = await _storyChannel.invokeMethod<bool>('encodeVideoFromFrames', {
            'framePaths': framePaths,
            'outputPath': videoPath,
            'fps': 6,
            'width': 720,
            'height': 1280,
          });

          if (encodeResult == true) {
            setState(() => _exportStatusText = 'OPENING INSTAGRAM STORIES...');
            final shareResult = await _storyChannel.invokeMethod<bool>('shareToInstagramStories', {
              'filePath': videoPath,
              'mimeType': 'video/mp4',
            });
            directSuccess = shareResult == true;
          }
        } on PlatformException catch (e) {
          debugPrint('Video encoding / share error: $e');
          directSuccess = false;
        }
      }

      if (directSuccess) {
        if (mounted) Navigator.of(context).pop();
      } else {
        final videoFile = File(videoPath);
        if (await videoFile.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceElevated,
                content: Text(
                  'INSTAGRAM APP NOT DETECTED — OPENING SYSTEM SHARE',
                  style: AppTypography.monoBadge(color: AppColors.acidLime),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(videoFile.path, mimeType: 'video/mp4')],
              text: '${widget.review.musicItemName} by ${widget.review.artistName} — Track Scorecard on Groovd',
            ),
          );
        } else {
          // If video encoding failed, fallback to static image
          await _captureAndShareStaticFallback();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('VIDEO EXPORT FAILED: $e', style: AppTypography.monoBadge(color: AppColors.electricPink)),
          ),
        );
      }
    } finally {
      if (framesDir != null && await framesDir.exists()) {
        try {
          await framesDir.delete(recursive: true);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatusText = null;
          _previewProgress = _animController.value;
        });
        _animController.forward(from: 0.0);
      }
    }
  }

  Future<void> _captureAndShareStaticFallback() async {
    setState(() => _previewProgress = 1.0);
    await WidgetsBinding.instance.endOfFrame;
    final file = await _captureStoryImage(pixelRatio: 3.0);
    if (file != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '${widget.review.musicItemName} by ${widget.review.artistName} — Track Scorecard on Groovd',
        ),
      );
    }
  }

  Future<void> _saveStoryImage() async {
    setState(() {
      _isExporting = true;
      _exportStatusText = 'SAVING STORY IMAGE...';
    });
    HapticFeedback.lightImpact();

    try {
      // Temporarily set to full rest state for the static capture
      final prevVal = _previewProgress;
      setState(() => _previewProgress = 1.0);
      await WidgetsBinding.instance.endOfFrame;

      final file = await _captureStoryImage(pixelRatio: 3.0);
      setState(() => _previewProgress = prevVal);

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
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportStatusText = null;
        });
      }
    }
  }

  void _copyCritiqueText() {
    final trackSummary = _tracks.isNotEmpty
        ? '\n\nTrack Ratings:\n' +
            _tracks.map((t) => '${t.trackNumber}. ${t.title}: ${t.scoreFormatted}/10').join('\n')
        : '';

    final text = '“${widget.review.musicItemName}” by ${widget.review.artistName}\n'
        'Overall Score: ${widget.review.scoreFormatted}/10 on Groovd'
        '$trackSummary';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('SCORECARD COPIED TO CLIPBOARD', style: AppTypography.monoBadge(color: AppColors.acidLime)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;
    final isCurrentUser = widget.review.userId == profile.userId ||
        (authUser != null && widget.review.userId == authUser.uid) ||
        widget.review.userId == 'user_me' ||
        (profile.userHandle != '@groovd_me' &&
            widget.review.userHandle.isNotEmpty &&
            widget.review.userHandle.toLowerCase() == profile.userHandle.toLowerCase());

    final customAvatarPath = isCurrentUser
        ? (profile.avatarPath ?? widget.review.userAvatarUrl)
        : widget.review.userAvatarUrl;

    final displayReview = isCurrentUser
        ? widget.review.copyWith(
            userName: profile.userName,
            userHandle: profile.userHandle,
            userAvatarUrl: customAvatarPath,
          )
        : widget.review;

    final double effectiveProgress = _isAnimatedMode ? _previewProgress : 1.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.94,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: AppColors.borderBold, width: 2.5),
        ),
      ),
      child: Column(
        children: [
          // Top Header Bar
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // 9:16 Visual Preview Canvas
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 380,
                      ),
                      decoration: const BoxDecoration(
                        boxShadow: [
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
                            review: displayReview,
                            theme: _currentTheme,
                            layout: _currentLayout,
                            avatarPath: customAvatarPath,
                            tracks: _tracks,
                            animationProgress: effectiveProgress,
                            releaseYear: _releaseYear,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Interactive Animation Player Controls (Animated Mode only)
                  if (_isAnimatedMode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _animController.isAnimating ? Icons.pause : Icons.play_arrow,
                              color: AppColors.acidLime,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            iconSize: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.replay,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _replayAnimation,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                activeTrackColor: AppColors.acidLime,
                                inactiveTrackColor: AppColors.border,
                                thumbColor: AppColors.acidLime,
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                              ),
                              child: Slider(
                                value: _previewProgress.clamp(0.0, 1.0),
                                onChanged: (val) {
                                  if (_animController.isAnimating) {
                                    _animController.stop();
                                  }
                                  setState(() {
                                    _previewProgress = val;
                                    _animController.value = val;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(_previewProgress * 3.5).toStringAsFixed(1)}s',
                            style: AppTypography.monoLabel(
                              color: AppColors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    const SizedBox(height: 6),
                  ],

                  // Mode Selector: ANIMATED (VIDEO) vs STATIC (PHOTO)
                  Row(
                    children: [
                      Expanded(
                        child: _LayoutPill(
                          label: 'ANIMATED (VIDEO)',
                          isSelected: _isAnimatedMode,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isAnimatedMode = true;
                              _animController.forward(from: 0.0);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _LayoutPill(
                          label: 'STATIC (PHOTO)',
                          isSelected: !_isAnimatedMode,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _isAnimatedMode = false;
                              if (_animController.isAnimating) {
                                _animController.stop();
                              }
                              _previewProgress = 1.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

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

                  const SizedBox(height: 14),

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
                      Text(
                        _currentLayout == StoryLayout.trackScorecard
                            ? 'SCORECARD'
                            : (_currentLayout == StoryLayout.posterCard ? 'POSTER' : 'FULL'),
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
                      Expanded(
                        child: _LayoutPill(
                          label: 'SCORECARD',
                          isSelected: _currentLayout == StoryLayout.trackScorecard,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentLayout = StoryLayout.trackScorecard);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _LayoutPill(
                          label: 'POSTER',
                          isSelected: _currentLayout == StoryLayout.posterCard,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentLayout = StoryLayout.posterCard);
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _LayoutPill(
                          label: 'FULL',
                          isSelected: _currentLayout == StoryLayout.fullCritique,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _currentLayout = StoryLayout.fullCritique);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Primary Action: Share to Instagram Stories
                  SizedBox(
                    width: double.infinity,
                    child: BrutalistButton(
                      label: _isExporting
                          ? (_exportStatusText ?? 'EXPORTING STORY...')
                          : 'SHARE TO INSTAGRAM STORIES',
                      icon: _isAnimatedMode ? Icons.movie_creation_outlined : Icons.auto_stories,
                      backgroundColor: AppColors.acidLime,
                      textColor: AppColors.pureBlack,
                      onPressed: _isExporting ? () {} : _shareToInstagramStories,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary Actions: Save Image / Video & Copy Text
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.monoBadge(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontSize: 8.5,
          ),
        ),
      ),
    );
  }
}
