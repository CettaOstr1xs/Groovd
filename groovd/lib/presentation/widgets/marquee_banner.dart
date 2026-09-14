import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';

class MarqueeBanner extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final int repeatCount;

  const MarqueeBanner({
    super.key,
    required this.text,
    this.backgroundColor = AppColors.acidLime,
    this.textColor = AppColors.pureBlack,
    this.height = 34,
    this.repeatCount = 20,
  });

  @override
  State<MarqueeBanner> createState() => _MarqueeBannerState();
}

class _MarqueeBannerState extends State<MarqueeBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _itemKey = GlobalKey();
  double _itemWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _itemKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        final w = renderBox.size.width;
        if (w > 0) {
          setState(() {
            _itemWidth = w;
            final durationSeconds = (w / 45.0).clamp(4.0, 60.0);
            _controller.duration = Duration(milliseconds: (durationSeconds * 1000).toInt());
            _controller.repeat();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildItem({Key? key}) {
    return Row(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.text.toUpperCase(),
          style: AppTypography.monoBadge(
            color: widget.textColor,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '★',
          style: TextStyle(color: widget.textColor, fontSize: 10),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: const Border.symmetric(
          horizontal: BorderSide(color: AppColors.pureBlack, width: 1.5),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final offset = _itemWidth > 0 ? -_controller.value * _itemWidth : 0.0;
          return OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildItem(key: _itemKey),
                  for (int i = 0; i < widget.repeatCount; i++) _buildItem(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
