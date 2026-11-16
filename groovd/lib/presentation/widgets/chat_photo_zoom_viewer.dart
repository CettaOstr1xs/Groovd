import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groovd/core/theme/app_colors.dart';

class ChatPhotoZoomViewer extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const ChatPhotoZoomViewer({
    super.key,
    this.imagePath,
    this.imageBytes,
  });

  static Future<void> show(
    BuildContext context, {
    String? imagePath,
    Uint8List? imageBytes,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ChatPhotoZoomViewer(
            imagePath: imagePath,
            imageBytes: imageBytes,
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
  State<ChatPhotoZoomViewer> createState() => _ChatPhotoZoomViewerState();
}

class _ChatPhotoZoomViewerState extends State<ChatPhotoZoomViewer>
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
      duration: const Duration(milliseconds: 240),
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
      const targetScale = 2.5;
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

  Widget _buildPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        border: Border.all(color: AppColors.acidLime, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.broken_image_outlined,
            color: AppColors.acidLime,
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'PHOTO UNAVAILABLE',
            style: GoogleFonts.spaceMono(
              color: AppColors.acidLime,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.imageBytes != null && widget.imageBytes!.isNotEmpty) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      final file = File(widget.imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      }
    }

    return _buildPlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    final isZoomed = _currentScale > 1.05;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background tap to dismiss or reset zoom
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

          // Main Interactive Image Viewer
          Center(
            child: GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                onInteractionStart: (_) {
                  if (_animController.isAnimating) {
                    _animController.stop();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
                  child: _buildImageContent(),
                ),
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.pureBlack,
                        border: Border.all(color: AppColors.acidLime, width: 1.5),
                      ),
                      child: Text(
                        'GROOVD AI // INSPECTION',
                        style: GoogleFonts.spaceMono(
                          color: AppColors.acidLime,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      key: const Key('chat_photo_zoom_close_btn'),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pureBlack,
                          border: Border.all(color: AppColors.acidLime, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.acidLime,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

