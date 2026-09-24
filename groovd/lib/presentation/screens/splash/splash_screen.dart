import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Fullscreen animated launch screen inspired by brutalist aesthetics & modern streaming apps.
/// Features a choreographed reveal of the "GROOVD" title followed by the signature
/// acid-lime block entrance with an elastic bounce and neon glow bloom.
class SplashScreen extends StatefulWidget {
  final Duration duration;
  final Widget? nextScreen;
  final VoidCallback? onComplete;

  const SplashScreen({
    super.key,
    this.duration = const Duration(milliseconds: 1900),
    this.nextScreen,
    this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // GROOVD Text animations
  late final Animation<double> _textOpacity;
  late final Animation<double> _textScale;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _letterSpacing;

  // Acid-lime block animations
  late final Animation<double> _blockScale;
  late final Animation<double> _blockOpacity;
  late final Animation<double> _glowIntensity;

  // Subtitle / tagline animations
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  // Background vinyl groove lines subtle pulse
  late final Animation<double> _grooveOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // GROOVD text fades and glides in (0.06 -> 0.45)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.40, curve: Curves.easeOutCubic),
      ),
    );

    _textScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _letterSpacing = Tween<double>(begin: -4.0, end: -2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.50, curve: Curves.easeOutCubic),
      ),
    );

    // Acid-lime block pops in with spring bounce (0.40 -> 0.72)
    _blockScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOutBack),
      ),
    );

    _blockOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.52, curve: Curves.easeIn),
      ),
    );

    // Glow blooms on impact, then settles into crisp solid lime
    _glowIntensity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.20)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 65,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.78),
      ),
    );

    // Subtitle tagline (0.60 -> 0.85)
    _taglineOpacity = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Subtle vinyl groove background presence
    _grooveOpacity = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.10, 0.60, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    _controller.forward();
  }

  void _proceed() {
    if (_navigated || !mounted) return;
    _navigated = true;

    if (widget.onComplete != null) {
      widget.onComplete!();
    }

    if (widget.nextScreen != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              widget.nextScreen!,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _proceed, // Tap to skip launch animation immediately
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Subtle concentric vinyl grooves centered in the dark
                if (_grooveOpacity.value > 0.0)
                  CustomPaint(
                    painter: _VinylGroovesPainter(
                      opacity: _grooveOpacity.value,
                    ),
                  ),

                // Centered branding: GROOVD ▪ + Tagline
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "GROOVD ▪" Row
                      SlideTransition(
                        position: _textSlide,
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Transform.scale(
                            scale: _textScale.value,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'GROOVD',
                                  style: AppTypography.displayMassive(
                                    fontSize: 54,
                                    color: Colors.white,
                                  ).copyWith(
                                    letterSpacing: _letterSpacing.value,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                // Animated Acid Lime Block
                                Opacity(
                                  opacity: _blockOpacity.value,
                                  child: Transform.scale(
                                    scale: _blockScale.value,
                                    child: Container(
                                      width: 10.5,
                                      height: 10.5,
                                      margin: const EdgeInsets.only(left: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.acidLime,
                                        boxShadow: _glowIntensity.value > 0.01
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.acidLime
                                                      .withValues(
                                                    alpha: (_glowIntensity.value * 0.8)
                                                        .clamp(0.0, 1.0),
                                                  ),
                                                  blurRadius:
                                                      18 * _glowIntensity.value,
                                                  spreadRadius:
                                                      2 * _glowIntensity.value,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline: THE MUSIC CRITIC'S NOTEBOOK
                      SlideTransition(
                        position: _taglineSlide,
                        child: Opacity(
                          opacity: _taglineOpacity.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 1,
                                color: AppColors.acidLime.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'THE MUSIC CRITIC’S NOTEBOOK',
                                style: AppTypography.monoLabel(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.5,
                                  letterSpacing: 2.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 14,
                                height: 1,
                                color: AppColors.acidLime.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tiny footer indicator
                Positioned(
                  bottom: 36,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: (_taglineOpacity.value * 0.6).clamp(0.0, 1.0),
                      child: Text(
                        'GROOVD // ARCHIVE v1.0',
                        style: AppTypography.monoLabel(
                          color: AppColors.textMuted,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VinylGroovesPainter extends CustomPainter {
  final double opacity;

  const _VinylGroovesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF26262F).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric grooves resembling a vinyl record centered on the screen
    final radii = [90.0, 140.0, 190.0, 240.0, 290.0, 340.0];
    for (final r in radii) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VinylGroovesPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
