import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class BrutalistButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final IconData? icon;
  final double height;
  final double? width;
  final bool isFullWidth;
  final bool isSmall;

  const BrutalistButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.acidLime,
    this.textColor = AppColors.pureBlack,
    this.borderColor = AppColors.pureBlack,
    this.icon,
    this.height = 48,
    this.width,
    this.isFullWidth = false,
    this.isSmall = false,
  });

  @override
  State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.isSmall ? 36.0 : widget.height;
    final fontSize = widget.isSmall ? 11.0 : 13.0;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(
          _isPressed ? 3.0 : 0.0,
          _isPressed ? 3.0 : 0.0,
          0.0,
        ),
        width: widget.isFullWidth ? double.infinity : widget.width,
        height: effectiveHeight,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSmall ? 12 : 20,
          vertical: widget.isSmall ? 6 : 10,
        ),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: widget.borderColor, width: 2.0),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.borderColor,
                    offset: const Offset(3.5, 3.5),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: widget.isSmall ? 14 : 18, color: widget.textColor),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label.toUpperCase(),
              style: AppTypography.buttonLabel(
                color: widget.textColor,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
