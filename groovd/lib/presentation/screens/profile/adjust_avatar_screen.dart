import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/brutalist_button.dart';

/// Interactive neo-brutalist avatar cropping and positioning screen.
/// Allows the user to pan, zoom (pinch or stepper), rotate, and align their
/// selected profile photo within a 1:1 square dossier viewport.
/// Supports both FILL (default, fills entire 1:1 square with zero black bars)
/// and FIT (shows full photo inside frame) modes.
class AdjustAvatarScreen extends StatefulWidget {
  final File imageFile;

  const AdjustAvatarScreen({super.key, required this.imageFile});

  static MaterialPageRoute<String?> route({required File imageFile}) {
    return MaterialPageRoute<String?>(
      builder: (_) => AdjustAvatarScreen(imageFile: imageFile),
    );
  }

  @override
  State<AdjustAvatarScreen> createState() => _AdjustAvatarScreenState();
}

class _AdjustAvatarScreenState extends State<AdjustAvatarScreen> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();

  bool _isSaving = false;
  bool _isFillMode = true;
  double _origWidth = 300;
  double _origHeight = 300;
  int _quarterTurns = 0;
  double _currentScale = 1.0;
  double _viewportSize = 270.0;

  @override
  void initState() {
    super.initState();
    _loadImageMetadata();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// Resolves true, orientation-corrected display dimensions via Flutter's ImageStream
  Future<void> _loadImageMetadata() async {
    try {
      final ImageStream stream =
          FileImage(widget.imageFile).resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      final completer = Completer<ui.Image>();

      listener = ImageStreamListener((ImageInfo info, bool _) {
        if (!completer.isCompleted) {
          completer.complete(info.image);
        }
        stream.removeListener(listener);
      }, onError: (dynamic exception, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception);
        }
        stream.removeListener(listener);
      });

      stream.addListener(listener);

      final image = await completer.future;
      if (mounted) {
        setState(() {
          _origWidth = image.width.toDouble();
          _origHeight = image.height.toDouble();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _resetFraming();
        });
      }
    } catch (_) {}
  }

  /// Calculates child layout dimensions that preserve aspect ratio and FILL or FIT the square
  Size _calculateChildSize() {
    if (_origWidth <= 0 || _origHeight <= 0) {
      return Size(_viewportSize, _viewportSize);
    }

    final isFlipped = _quarterTurns % 2 == 1;
    final w = isFlipped ? _origHeight : _origWidth;
    final h = isFlipped ? _origWidth : _origHeight;

    // In FILL mode: scale so both width & height cover the viewport (no empty black bars).
    // In FIT mode: scale so the full image fits inside the viewport.
    final scale = _isFillMode
        ? max(_viewportSize / w, _viewportSize / h)
        : min(_viewportSize / w, _viewportSize / h);

    return Size(w * scale, h * scale);
  }

  /// Centers the image within the viewport
  void _resetFraming() {
    final childSize = _calculateChildSize();

    final offsetX = -((childSize.width - _viewportSize) / 2);
    final offsetY = -((childSize.height - _viewportSize) / 2);

    _transformController.value =
        Matrix4.translationValues(offsetX, offsetY, 0.0);

    setState(() {
      _currentScale = 1.0;
    });
  }

  void _rotate90() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetFraming();
    });
  }

  void _toggleFitFill() {
    setState(() {
      _isFillMode = !_isFillMode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetFraming();
    });
  }

  void _zoomBy(double factor) {
    final newScale = (_currentScale * factor).clamp(0.4, 5.0);
    final ratio = newScale / _currentScale;

    final currentMatrix = _transformController.value;
    final center = Offset(_viewportSize / 2, _viewportSize / 2);

    final transform = Matrix4.translationValues(center.dx, center.dy, 0.0)
      ..multiply(Matrix4.diagonal3Values(ratio, ratio, 1.0))
      ..multiply(Matrix4.translationValues(-center.dx, -center.dy, 0.0));

    final updated = transform * currentMatrix;

    _transformController.value = updated;
    setState(() {
      _currentScale = newScale;
    });
  }

  Future<void> _applyCrop() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final boundary =
          _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary unavailable');
      }

      // 3.0 pixel ratio produces 800-960px crystal-clear square avatar
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to generate PNG bytes');
      }

      final buffer = byteData.buffer.asUint8List();
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedFile = File('${appDir.path}/$fileName');
      await savedFile.writeAsBytes(buffer);

      if (mounted) {
        Navigator.of(context).pop(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.electricPink,
            content: Text(
              'FAILED TO CROP AVATAR: $e',
              style: AppTypography.monoBadge(color: AppColors.pureBlack),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ADJUST AVATAR', style: AppTypography.displaySmall()),
            Text(
              'ARRANGE POSITION // 1:1 RATIO',
              style: AppTypography.monoLabel(
                color: AppColors.cyberCyan,
                fontSize: 9,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BrutalistButton(
              label: _isSaving ? 'SAVING...' : 'APPLY',
              isSmall: true,
              backgroundColor: AppColors.acidLime,
              textColor: AppColors.pureBlack,
              borderColor: AppColors.pureBlack,
              onPressed: _isSaving ? () {} : _applyCrop,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Viewport Frame Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final calculated =
                      (min(constraints.maxWidth - 24, constraints.maxHeight - 36))
                          .clamp(160.0, 320.0);
                  if ((calculated - _viewportSize).abs() > 2) {
                    _viewportSize = calculated;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _resetFraming();
                    });
                  }
                  final childSize = _calculateChildSize();

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1:1 Crop Viewport Stack
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // Captured Area
                              RepaintBoundary(
                                key: _cropKey,
                                child: ClipRect(
                                  child: Container(
                                    width: _viewportSize,
                                    height: _viewportSize,
                                    color: AppColors.pureBlack,
                                    child: InteractiveViewer(
                                      transformationController:
                                          _transformController,
                                      constrained: false,
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      minScale: 0.3,
                                      maxScale: 6.0,
                                      boundaryMargin: EdgeInsets.all(
                                          _viewportSize * 1.5),
                                      clipBehavior: Clip.none,
                                      child: SizedBox(
                                        width: childSize.width,
                                        height: childSize.height,
                                        child: RotatedBox(
                                          quarterTurns: _quarterTurns,
                                          child: Image.file(
                                            widget.imageFile,
                                            width: (_quarterTurns % 2 == 0)
                                                ? childSize.width
                                                : childSize.height,
                                            height: (_quarterTurns % 2 == 0)
                                                ? childSize.height
                                                : childSize.width,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Non-captured Viewfinder Overlay (Grid & Corner Brackets)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: _ViewfinderOverlayPainter(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Micro Instruction Badge
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.touch_app,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DRAG TO PAN • PINCH TO ZOOM',
                                style: AppTypography.monoLabel(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls Shelf
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Action Buttons Row
                  Row(
                    children: [
                      // Rotate Button
                      Expanded(
                        child: BrutalistButton(
                          label: 'ROTATE 90°',
                          icon: Icons.rotate_right,
                          isSmall: true,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: AppColors.textPrimary,
                          borderColor: AppColors.border,
                          onPressed: _rotate90,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fit / Fill Mode Toggle
                      Expanded(
                        child: BrutalistButton(
                          label: _isFillMode ? 'MODE: FILL' : 'MODE: FIT',
                          icon: _isFillMode
                              ? Icons.crop_free
                              : Icons.fit_screen,
                          isSmall: true,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: _isFillMode
                              ? AppColors.cyberCyan
                              : AppColors.acidLime,
                          borderColor: AppColors.border,
                          onPressed: _toggleFitFill,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Re-center Button
                      Expanded(
                        child: BrutalistButton(
                          label: 'RE-CENTER',
                          icon: Icons.center_focus_strong,
                          isSmall: true,
                          backgroundColor: AppColors.surfaceElevated,
                          textColor: AppColors.textPrimary,
                          borderColor: AppColors.border,
                          onPressed: _resetFraming,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Zoom Step Adjusters
                  Row(
                    children: [
                      Text(
                        'ZOOM',
                        style: AppTypography.monoLabel(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        color: AppColors.textPrimary,
                        tooltip: 'Zoom Out',
                        onPressed: () => _zoomBy(0.85),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${_currentScale.toStringAsFixed(1)}x',
                          style: AppTypography.monoBadge(
                            color: AppColors.cyberCyan,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        color: AppColors.textPrimary,
                        tooltip: 'Zoom In',
                        onPressed: () => _zoomBy(1.2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Main Confirm Action Button
                  BrutalistButton(
                    label: _isSaving
                        ? 'CAPTURING & SAVING...'
                        : 'CONFIRM AVATAR // SET PHOTO',
                    icon: Icons.check,
                    isFullWidth: true,
                    backgroundColor: AppColors.acidLime,
                    textColor: AppColors.pureBlack,
                    borderColor: AppColors.pureBlack,
                    onPressed: _isSaving ? () {} : _applyCrop,
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

/// Draws studio viewfinder guidelines (corner brackets, outer frame, and rule-of-thirds grid)
class _ViewfinderOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Outer Border Frame
    final borderPaint = Paint()
      ..color = AppColors.cyberCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );

    // 2. Rule of Thirds Grid Lines
    final gridPaint = Paint()
      ..color = AppColors.cyberCyan.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final stepX = size.width / 3;
    final stepY = size.height / 3;

    canvas.drawLine(Offset(stepX, 0), Offset(stepX, size.height), gridPaint);
    canvas.drawLine(
        Offset(stepX * 2, 0), Offset(stepX * 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, stepY), Offset(size.width, stepY), gridPaint);
    canvas.drawLine(
        Offset(0, stepY * 2), Offset(size.width, stepY * 2), gridPaint);

    // 3. Acid Lime Viewfinder Corner Brackets
    final cornerPaint = Paint()
      ..color = AppColors.acidLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;

    const cornerLength = 18.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
