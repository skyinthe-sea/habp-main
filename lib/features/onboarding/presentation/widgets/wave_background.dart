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

    _controller1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _controller2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
        // 기본 배경 레이어
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor.withOpacity(0.4),
                widget.secondaryColor.withOpacity(0.4),
              ],
            ),
          ),
        ),

        // 오로라 효과 레이어 1
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  center: Alignment(
                    math.cos(_animation1.value * math.pi) * 0.6,
                    math.sin(_animation1.value * math.pi) * 0.6,
                  ),
                  colors: [
                    widget.primaryColor.withOpacity(0.0),
                    widget.secondaryColor.withOpacity(0.2),
                    widget.primaryColor.withOpacity(0.1),
                    widget.secondaryColor.withOpacity(0.2),
                    widget.primaryColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  transform: GradientRotation(_animation1.value * math.pi),
                ),
                backgroundBlendMode: BlendMode.overlay,
              ),
            );
          },
        ),

        // 오로라 효과 레이어 2
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(
                    math.sin(_animation2.value * math.pi) * 0.8,
                    math.cos(_animation2.value * math.pi) * 0.8,
                  ),
                  radius: 1.2,
                  colors: [
                    widget.secondaryColor.withOpacity(0.1),
                    widget.primaryColor.withOpacity(0.2),
                    widget.secondaryColor.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
                backgroundBlendMode: BlendMode.softLight,
              ),
            );
          },
        ),

        // 블러 효과 레이어
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 50.0,
            sigmaY: 50.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.1),
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