import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Splash screen shown during app initialisation.
///
/// Displays the stokesdrift brand mark with an animated wave, then
/// calls [onComplete] when the loading phase finishes. Other parts
/// of the app can extend the splash by calling [SplashController.extend].
class SplashScreen extends StatefulWidget {
  /// Called once the splash animation and any async init are done.
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Listen for external "ready" signal
    SplashController._instance = this;

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && SplashController._ready) {
        widget.onComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    SplashController._instance = null;
    _controller.dispose();
    super.dispose();
  }

  void _tryComplete() {
    if (_controller.status == AnimationStatus.completed) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            // Staggered opacity curves
            final markOpacity = Curves.easeOut.transform((t / 0.4).clamp(0, 1));
            final titleOpacity = Curves.easeOut.transform(((t - 0.25) / 0.4).clamp(0, 1));
            final tagOpacity = Curves.easeOut.transform(((t - 0.5) / 0.3).clamp(0, 1));

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Brand mark (wave icon) ───
                Opacity(
                  opacity: markOpacity,
                  child: CustomPaint(
                    size: const Size(96, 96),
                    painter: _WavePainter(
                      color: AppColors.tertiary,
                      progress: Curves.easeOutCubic.transform(t),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── App name ───
                Opacity(
                  opacity: titleOpacity,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - titleOpacity)),
                    child: Text(
                      'stokesdrift',
                      style: AppTypography.display.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // ─── Tagline ───
                Opacity(
                  opacity: tagOpacity,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - tagOpacity)),
                    child: Text(
                      'Track items. Mark locations. Stay organized.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ─── Loading indicator ───
                if (!SplashController._ready)
                  Opacity(
                    opacity: Curves.easeIn.transform(((t - 0.6) / 0.4).clamp(0, 1)),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.tertiary,
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

/// ─── Custom wave painter (brand icon) ───────────────────────────────────────
class _WavePainter extends CustomPainter {
  final Color color;
  final double progress;

  _WavePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final waveW = size.width * 0.7;
    final waveH = size.height * 0.12;

    // Draw three wave lines, staggered
    for (int i = 0; i < 3; i++) {
      final yOffset = cy + (i - 1) * waveH * 2;
      final phaseShift = i * 0.3;
      final path = Path();
      final segProgress = ((progress - phaseShift) / (1 - phaseShift)).clamp(0, 1);

      for (double x = -waveW / 2; x <= waveW / 2 * segProgress; x += 1) {
        final normalX = x / waveW;
        final y = yOffset + sin((normalX * 2 + phaseShift) * pi) * waveH;
        if (x == -waveW / 2) {
          path.moveTo(cx + x, y);
        } else {
          path.lineTo(cx + x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Dot accent (location pin)
    if (progress > 0.7) {
      final dotProgress = ((progress - 0.7) / 0.3).clamp(0, 1);
      final dotPaint = Paint()
        ..color = color.withValues(alpha: dotProgress.toDouble())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx + waveW * 0.3, cy - waveH * 2.5), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.progress != progress;
}

/// ─── Splash Controller (hook for external callers) ─────────────────────────
///
/// Usage from anywhere in the app:
///   SplashController.markReady();   // signal that init is complete
///   SplashController.extend();      // ask splash to stay visible longer
///
class SplashController {
  static _SplashScreenState? _instance;
  static bool _ready = false;

  /// Signal that async initialisation is finished.
  /// The splash will dismiss once both this is called *and* the animation completes.
  static void markReady() {
    _ready = true;
    _instance?._tryComplete();
  }

  /// Extend the splash screen (e.g. while waiting for a critical resource).
  /// Call [markReady] again when ready.
  static void extend() {
    _ready = false;
  }

  /// Reset state (useful for hot-restart during development).
  static void reset() {
    _ready = false;
  }
}