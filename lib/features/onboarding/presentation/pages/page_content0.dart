// lib/features/onboarding/presentation/pages/page_content0.dart

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/wave_background.dart';

class PageContent0 extends StatefulWidget {
  const PageContent0({Key? key}) : super(key: key);

  @override
  State<PageContent0> createState() => _PageContent0State();
}

class _PageContent0State extends State<PageContent0> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _lineAnimations;

  final List<String> _lines = [
    '하나하나 직접 작성하면서',
    '나의 소비를 돌아보고',
    '나를 알아가는 시간',
  ];

  @override
  void initState() {
    super.initState();

    // Handwriting reveal animation - each line reveals from left to right
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Create staggered animations for each line
    _lineAnimations = List.generate(_lines.length, (index) {
      final start = index * 0.28; // Each line starts 28% later
      final end = start + 0.5;    // Each line takes 50% of total time to complete

      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeInOut, // Smoother curve for handwriting
          ),
        ),
      );
    });

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Slightly larger font size for handwriting feel
    final fontSize = size.width * 0.075;

    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400),
        child: Stack(children: [
          const WaveBackground(
            primaryColor: AppColors.grey,
            secondaryColor: AppColors.primary,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_lines.length, (index) {
                            final animation = _lineAnimations[index].value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: ClipRect(
                                  clipper: _CenterHandwritingClipper(animation),
                                  child: Text(
                                    _lines[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Noto Sans JP',
                                      height: 1.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Custom clipper for handwriting reveal effect from left to right
class _CenterHandwritingClipper extends CustomClipper<Rect> {
  final double progress;

  _CenterHandwritingClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // Reveal from left to right (like writing)
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_CenterHandwritingClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}