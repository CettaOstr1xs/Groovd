import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class ArtworkZoomViewer extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String artist;
  final String heroTag;
  final String? year;
  final String? typeLabel;

  const ArtworkZoomViewer({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    required this.heroTag,
    this.year,
    this.typeLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String artist,
    required String heroTag,
    String? year,
    String? typeLabel,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.94),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ArtworkZoomViewer(
            imageUrl: imageUrl,
            title: title,
            artist: artist,
            heroTag: heroTag,
            year: year,
            typeLabel: typeLabel,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<ArtworkZoomViewer> createState() => _ArtworkZoomViewerState();
}

class _ArtworkZoomViewerState extends State<ArtworkZoomViewer>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  Offset? _doubleTapPosition;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.04) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    if (_animController.isAnimating) _animController.stop();

    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    Matrix4 endMatrix;

    if (currentScale > 1.2) {
      endMatrix = Matrix4.identity();
    } else {
      final position = _doubleTapPosition ?? Offset.zero;
      const targetScale = 2.6;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      endMatrix = Matrix4.identity()
        ..translateByDouble(x, y, 0.0, 1.0)
        ..scaleByDouble(targetScale, targetScale, 1.0, 1.0);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0.0);
  }

  void _resetZoom() {
    HapticFeedback.lightImpact();
    if (_animController.isAnimating) _animController.stop();

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isZoomed = _currentScale > 1.05;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background tap to dismiss
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (!isZoomed) {
                  Navigator.of(context).pop();
                } else {
                  _resetZoom();
                }
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),

          // Zoomable Interactive Artwork
          Center(
            child: GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 5.0,
                clipBehavior: Clip.none,
                onInteractionStart: (_) {
                  if (_animController.isAnimating) {
                    _animController.stop();
                  }
                },
                child: Hero(
                  tag: widget.heroTag,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: screenSize.width * 0.90,
                        maxHeight: screenSize.height * 0.65,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.borderBold, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.pureBlack,
                            offset: Offset(6, 6),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: widget.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceElevated,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.acidLime,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceElevated,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.broken_image_outlined,
                                        color: AppColors.textMuted,
                                        size: 40,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'NO ARTWORK AVAILABLE',
                                        style: AppTypography.monoBadge(
                                          color: AppColors.textMuted,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                color: AppColors.surfaceElevated,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.music_note,
                                  color: AppColors.textMuted,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Top Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.pureBlack.withValues(alpha: 0.95),
                      AppColors.pureBlack.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    // Back/Close Button
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'BACK',
                              style: AppTypography.monoBadge(
                                color: AppColors.textPrimary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Artist Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.acidLime,
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                                child: Text(
                                  'HIGH-RES ARTWORK',
                                  style: AppTypography.monoBadge(
                                    color: AppColors.pureBlack,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                              if (widget.year != null && widget.year!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '// ${widget.year}',
                                  style: AppTypography.monoLabel(
                                    color: AppColors.textMuted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.displaySmall(fontSize: 13),
                          ),
                          Text(
                            widget.artist.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.monoLabel(
                              color: AppColors.textSecondary,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tactile Close [X] Button
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      borderRadius: BorderRadius.circular(2),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border, width: 1.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Center(
                          child: Icon(Icons.close, color: AppColors.acidLime, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),

          // Bottom Controls & Hints Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.pureBlack.withValues(alpha: 0.95),
                      AppColors.pureBlack.withValues(alpha: 0.60),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isZoomed) ...[
                      // Zoom scale badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.cyberCyan, width: 1.2),
                        ),
                        child: Text(
                          '${_currentScale.toStringAsFixed(1)}X ZOOM',
                          style: AppTypography.monoBadge(
                            color: AppColors.cyberCyan,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Reset Zoom Brutalist Button
                      InkWell(
                        onTap: _resetZoom,
                        borderRadius: BorderRadius.circular(2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.acidLime,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: AppColors.pureBlack, width: 1.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.restart_alt, color: AppColors.pureBlack, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                'RESET ZOOM',
                                style: AppTypography.monoBadge(
                                  color: AppColors.pureBlack,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Gestures Hint Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.90),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_in,
                              color: AppColors.acidLime,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PINCH OR DOUBLE-TAP TO ZOOM',
                              style: AppTypography.monoBadge(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 250.ms),
        ],
      ),
    );
  }
}
