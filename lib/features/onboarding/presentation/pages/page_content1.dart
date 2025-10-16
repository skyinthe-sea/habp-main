// lib/features/onboarding/presentation/pages/page_content1.dart

import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:habp/features/onboarding/presentation/widgets/page_content1_alert.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/blinking_text_button.dart';
import '../widgets/wave_background.dart';

class PageContent1 extends StatefulWidget {
  const PageContent1({Key? key}) : super(key: key);

  @override
  State<PageContent1> createState() => _PageContent1State();
}

class _PageContent1State extends State<PageContent1> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _lineAnimations;
  bool _showGif = false;

  final List<String> _lines = [
    '고정소득의',
    '종류와 액수를',
    '입력해주세요',
  ];

  @override
  void initState() {
    super.initState();

    // Handwriting reveal animation - same as PageContent0
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
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    // Add animation status listener
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showGif = true;
        });
      }
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
    // Same font size as PageContent0
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
              padding: const EdgeInsets.only(top: 80.0, bottom: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GIF area
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: _showGif ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: GifView.asset(
                        'assets/images/money-1156.gif',
                        height: size.height * 0.20,
                        width: size.width * 0.6,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Text content area with reveal animation
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(_lines.length, (index) {
                            final animation = _lineAnimations[index].value;

                            // Special handling for line 1 (종류와 액수를) with BlinkingTextButton
                            if (index == 1) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: ClipRect(
                                    clipper: _HandwritingClipper(animation),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (_) => const PageContent1Alert(),
                                            );
                                          },
                                          behavior: HitTestBehavior.opaque,
                                          child: BlinkingTextButton(
                                            text: '종류와 액수',
                                            fontSize: fontSize,
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => const PageContent1Alert(),
                                              );
                                            },
                                          ),
                                        ),
                                        Text(
                                          '를',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Noto Sans JP',
                                            height: 1.5,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: ClipRect(
                                  clipper: _HandwritingClipper(animation),
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
class _HandwritingClipper extends CustomClipper<Rect> {
  final double progress;

  _HandwritingClipper(this.progress);

  @override
  Rect getClip(Size size) {
    // Reveal from left to right (like writing)
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_HandwritingClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
