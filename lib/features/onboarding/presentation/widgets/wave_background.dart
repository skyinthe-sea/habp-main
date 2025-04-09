// lib/features/onboarding/presentation/widgets/wave_background.dart

import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const WaveBackground({
    Key? key,
    this.primaryColor = const Color(0xFFE495C0),
    this.secondaryColor = const Color(0xFFF7B7D3),
  }) : super(key: key);

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> with TickerProviderStateMixin {
  late final AnimationController _controller1;
  late final AnimationController _controller2;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;

  @override
  void initState() {
    super.initState();

    // Speed up animations
    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7), // Reduced from 10s
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Reduced from 15s
    )..repeat();

    _animation1 = CurvedAnimation(
      parent: _controller1,
      curve: Curves.easeInOutSine,
    );

    _animation2 = CurvedAnimation(
      parent: _controller2,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor,
                widget.secondaryColor,
              ],
              stops: const [0.3, 1.0],
            ),
          ),
        ),

        // Aurora effect layer 1
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  center: Alignment(
                    math.cos(_animation1.value * math.pi * 2) * 0.5,
                    math.sin(_animation1.value * math.pi * 2) * 0.5,
                  ),
                  colors: [
                    widget.primaryColor.withOpacity(0.0),
                    widget.secondaryColor.withOpacity(0.3),
                    widget.primaryColor.withOpacity(0.2),
                    widget.secondaryColor.withOpacity(0.3),
                    widget.primaryColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  transform: GradientRotation(_animation1.value * math.pi * 2),
                ),
                backgroundBlendMode: BlendMode.overlay,
              ),
            );
          },
        ),

        // Aurora effect layer 2
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    math.sin(_animation2.value * math.pi * 2) * 0.8,
                    math.cos(_animation2.value * math.pi * 2) * 0.8,
                  ),
                  radius: 1.2,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    widget.secondaryColor.withOpacity(0.1),
                    widget.primaryColor.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
                backgroundBlendMode: BlendMode.softLight,
              ),
            );
          },
        ),

        // Modern pattern overlay
        CustomPaint(
          painter: ModernPatternPainter(
            color: Colors.white.withOpacity(0.05),
            animationValue: _animation1.value,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
          ),
        ),

        // Blur effect layer
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 30.0, // Reduced blur for better performance
            sigmaY: 30.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Modern pattern painter for decorative elements
class ModernPatternPainter extends CustomPainter {
  final Color color;
  final double animationValue;

  ModernPatternPainter({
    required this.color,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw modern decorative elements that move subtly with animation
    final offset = 20.0 * animationValue;

    // Draw subtle grid pattern
    for (var i = 0; i < size.width; i += 40) {
      // Horizontal lines
      canvas.drawLine(
        Offset(0, i + offset),
        Offset(size.width, i + offset),
        paint,
      );

      // Vertical lines
      canvas.drawLine(
        Offset(i + offset, 0),
        Offset(i + offset, size.height),
        paint,
      );
    }

    // Draw some circles
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      Offset(size.width * 0.2 + (offset * 2), size.height * 0.3),
      50 + (10 * math.sin(animationValue * math.pi * 2)),
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8 - (offset * 2), size.height * 0.7),
      70 + (15 * math.cos(animationValue * math.pi * 2)),
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint with animation
  }
}