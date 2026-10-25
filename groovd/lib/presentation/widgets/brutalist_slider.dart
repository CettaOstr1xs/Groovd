import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';

/// Neo-brutalist solid rectangular block slider thumb matching the Groovd title block aesthetic.
class BrutalistBlockSliderThumbShape extends SliderComponentShape {
  final double width;
  final double height;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double elevation;

  const BrutalistBlockSliderThumbShape({
    this.width = 16.0,
    this.height = 24.0,
    this.fillColor = AppColors.acidLime,
    this.borderColor = AppColors.pureBlack,
    this.borderWidth = 2.0,
    this.elevation = 2.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size(width, height);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // Brutalist hard drop shadow (crisp black block)
    if (elevation > 0) {
      final shadowRect = rect.shift(Offset(elevation, elevation));
      final shadowPaint = Paint()..color = AppColors.pureBlack;
      canvas.drawRect(shadowRect, shadowPaint);
    }

    // Solid block fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Crisp black outline border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRect(rect, borderPaint);

    // Tactile center grip line
    final gripPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx, center.dy - height * 0.25),
      Offset(center.dx, center.dy + height * 0.25),
      gripPaint,
    );
  }
}

/// Neo-brutalist solid rectangular block track with sharp ends and crisp border.
class BrutalistBlockSliderTrackShape extends SliderTrackShape {
  final double trackHeight;
  final double borderWidth;
  final Color borderColor;

  const BrutalistBlockSliderTrackShape({
    this.trackHeight = 8.0,
    this.borderWidth = 1.5,
    this.borderColor = AppColors.pureBlack,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    const double margin = 6.0;
    final double trackLeft = offset.dx + margin;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - (margin * 2);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final canvas = context.canvas;
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final clampedThumbX = thumbCenter.dx.clamp(trackRect.left, trackRect.right);

    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      clampedThumbX,
      trackRect.bottom,
    );

    final inactiveRect = Rect.fromLTRB(
      clampedThumbX,
      trackRect.top,
      trackRect.right,
      trackRect.bottom,
    );

    // Inactive track (sharp rectangular block)
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? AppColors.surfaceElevated;
    canvas.drawRect(inactiveRect, inactivePaint);

    // Active track (sharp rectangular block in vibrant score color)
    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppColors.acidLime;
    canvas.drawRect(activeRect, activePaint);

    // Entire track border (crisp brutalist outline)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRect(trackRect, borderPaint);
  }
}
