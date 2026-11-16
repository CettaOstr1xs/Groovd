import 'dart:math';
import 'package:flutter/material.dart';
import 'package:groovd/core/theme/app_colors.dart';
import 'package:groovd/core/theme/app_typography.dart';
import 'package:groovd/presentation/widgets/groovd_markdown_text.dart';

/// Cyberpunk terminal-style text scramble decode animation widget.
/// Rapidly scrambles through non-emoji alphanumeric/symbol glyphs
/// before locking into formatted markdown text.
class ScrambleText extends StatefulWidget {
  final String text;
  final Duration duration;
  final TextStyle? style;
  final VoidCallback? onComplete;

  const ScrambleText({
    super.key,
    required this.text,
    this.duration = const Duration(milliseconds: 1000),
    this.style,
    this.onComplete,
  });

  @override
  State<ScrambleText> createState() => _ScrambleTextState();
}

class _ScrambleTextState extends State<ScrambleText> with SingleTickerProviderStateMixin {
  static const String _pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!#\$%&*+-=/?[]{}';
  late final AnimationController _controller;
  late final Animation<double> _curve;
  final Random _random = Random();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && !_isFinished) {
          setState(() {
            _isFinished = true;
          });
          widget.onComplete?.call();
        }
      }
    });

    if (widget.text.isEmpty) {
      _isFinished = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete?.call();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ScrambleText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && !_isFinished) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generateScrambled(double progress) {
    final chars = widget.text.split('');
    final length = chars.length;
    final resolvedThreshold = (progress * length).floor();
    const int activeWindow = 6;

    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      final ch = chars[i];
      if (ch == ' ' || ch == '\n' || ch == '\t') {
        buffer.write(ch);
      } else if (i < resolvedThreshold) {
        buffer.write(ch);
      } else if (i < resolvedThreshold + activeWindow) {
        buffer.write(_pool[_random.nextInt(_pool.length)]);
      } else {
        final stableIndex = (ch.codeUnitAt(0) + i) % _pool.length;
        buffer.write(_pool[stableIndex]);
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return GroovdMarkdownText(
        text: widget.text,
        baseStyle: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, _) {
        if (_controller.isCompleted) {
          return GroovdMarkdownText(
            text: widget.text,
            baseStyle: widget.style,
          );
        }

        final scrambled = _generateScrambled(_curve.value);
        return Text(
          scrambled,
          style: widget.style ??
              AppTypography.monoLabel(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                letterSpacing: 0.2,
              ).copyWith(height: 1.5),
        );
      },
    );
  }
}
