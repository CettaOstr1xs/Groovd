import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';

/// Rating sign tier representing the visual variation.
/// Note: Do not expose or mention internal shape names in user-facing UI text.
enum RatingSignTier {
  /// Rating <= 6.0: Hollow stroked shape.
  hollow,

  /// 6.1 <= Rating <= 9.4: Full solid filled 4-point shape.
  full,

  /// 9.5 <= Rating <= 10.0: Detailed 8-point shape.
  eightPoint,
}

/// A custom-painted rating sign reflecting the release's score tier.
///
/// Rules:
/// - `rating <= 6.0`: Hollow inside (stroked outline)
/// - `6.1 <= rating <= 9.4`: Full solid shape
/// - `9.5 <= rating <= 10.0`: 8-point detailed shape
class RatingSpikeSign extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final double? strokeWidth;

  const RatingSpikeSign({
    super.key,
    required this.rating,
    this.size = 16.0,
    this.color,
    this.strokeWidth,
  });

  /// Resolves the rating tier based on the score.
  RatingSignTier get tier {
    if (rating >= 9.5) {
      return RatingSignTier.eightPoint;
    }
    if (rating > 6.0) {
      return RatingSignTier.full;
    }
    return RatingSignTier.hollow;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.acidLime;
    final width = size * 0.72;
    final height = size;

    return Semantics(
      label: 'Rating Sign',
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          size: Size(width, height),
          painter: _RatingSpikePainter(
            tier: tier,
            color: effectiveColor,
            strokeWidth: strokeWidth ?? (size * 0.09).clamp(1.2, 2.4),
          ),
        ),
      ),
    );
  }
}

class _RatingSpikePainter extends CustomPainter {
  final RatingSignTier tier;
  final Color color;
  final double strokeWidth;

  _RatingSpikePainter({
    required this.tier,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Vertical elongation reaches ~95% of height; horizontal span reaches ~92% of width.
    final rY = (size.height / 2) * 0.94;
    final rX = (size.width / 2) * 0.92;

    // Pinched control point factor for the needle-sharp classic spike taper.
    final kX = rX * 0.14;
    final kY = rY * 0.14;

    final primaryPath = Path();
    // Start at Top Tip
    primaryPath.moveTo(cx, cy - rY);
    // Curve to Right Tip
    primaryPath.quadraticBezierTo(cx + kX, cy - kY, cx + rX, cy);
    // Curve to Bottom Tip
    primaryPath.quadraticBezierTo(cx + kX, cy + kY, cx, cy + rY);
    // Curve to Left Tip
    primaryPath.quadraticBezierTo(cx - kX, cy + kY, cx - rX, cy);
    // Curve back to Top Tip
    primaryPath.quadraticBezierTo(cx - kX, cy - kY, cx, cy - rY);
    primaryPath.close();

    if (tier == RatingSignTier.eightPoint) {
      // 8-Point Shape (9.5 - 10.0):
      // Primary 4-point elongated spikes + 4 diagonal tapered spikes.
      final diagR = rX * 0.78;
      final diagX = diagR * 0.7071;
      final diagY = diagR * 0.7071;
      final diagK = diagR * 0.16;

      final diagPath = Path();
      diagPath.moveTo(cx + diagX, cy - diagY);
      diagPath.quadraticBezierTo(cx + diagK, cy, cx + diagX, cy + diagY);
      diagPath.quadraticBezierTo(cx, cy + diagK, cx - diagX, cy + diagY);
      diagPath.quadraticBezierTo(cx - diagK, cy, cx - diagX, cy - diagY);
      diagPath.quadraticBezierTo(cx, cy - diagK, cx + diagX, cy - diagY);
      diagPath.close();

      final combinedPath = Path()
        ..addPath(primaryPath, Offset.zero)
        ..addPath(diagPath, Offset.zero);

      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(combinedPath, fillPaint);
    } else if (tier == RatingSignTier.full) {
      // Full shape (6.1 - 9.4): Solid filled 4-point classic spike.
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawPath(primaryPath, fillPaint);
    } else {
      // Hollow shape (<= 6.0): Stroked outline, hollow inside.
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      canvas.drawPath(primaryPath, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RatingSpikePainter oldDelegate) {
    return oldDelegate.tier != tier ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
