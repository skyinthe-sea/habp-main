// lib/features/onboarding/presentation/pages/page_content1.dart
// (Apply similar modifications to PageContent2 and PageContent3)

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
  late List<Animation<double>> _textAnimations;
  bool _showGif = false;

  // Number of text elements
  final int _numTextElements = 3;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller - faster animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Reduced from 2 seconds
      vsync: this,
    );

    // Create animations for each text element
    _textAnimations = List.generate(_numTextElements, (index) {
      final start = index * 0.15; // Faster timing
      final end = start + 0.3;    // Faster completion

      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      );
    });

    // Add animation status listener
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Show GIF when animation completes
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
    // Standardized text size
    final standardFontSize = size.width * 0.07;

    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 400), // Faster fade in
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
                  // GIF area - smaller size and shows after animation completes
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: _showGif ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400), // Faster fade
                      child: GifView.asset(
                        'assets/images/money-1156.gif',
                        height: size.height * 0.20, // Reduced size
                        width: size.width * 0.6,   // Reduced size
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Text content area
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // First text
                            AnimatedOpacity(
                              opacity: _textAnimations[0].value,
                              duration: const Duration(milliseconds: 200), // Faster animation
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[0].value),
                                duration: const Duration(milliseconds: 200), // Faster animation
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '고정소득의',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: standardFontSize,
                                      fontFamily: 'Noto Sans JP',
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Second text (Row with BlinkingTextButton)
                            AnimatedOpacity(
                              opacity: _textAnimations[1].value,
                              duration: const Duration(milliseconds: 200), // Faster animation
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[1].value),
                                duration: const Duration(milliseconds: 200), // Faster animation
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Wrap BlinkingTextButton with GestureDetector to prevent tap events from propagating
                                    GestureDetector(
                                      onTap: () {
                                        // Show dialog when tapped
                                        showDialog(
                                          context: context,
                                          builder: (_) => const PageContent1Alert(),
                                        );
                                      },
                                      // This is critical - it prevents the tap from propagating to parent
                                      behavior: HitTestBehavior.opaque,
                                      child: BlinkingTextButton(
                                        text: '종류와 액수',
                                        fontSize: standardFontSize,
                                        onTap: () {
                                          // Show dialog when tapped
                                          showDialog(
                                            context: context,
                                            builder: (_) => const PageContent1Alert(),
                                          );
                                        },
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '를',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: standardFontSize,
                                          fontFamily: 'Noto Sans JP',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Third text
                            AnimatedOpacity(
                              opacity: _textAnimations[2].value,
                              duration: const Duration(milliseconds: 200), // Faster animation
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[2].value),
                                duration: const Duration(milliseconds: 200), // Faster animation
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '입력해주세요',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: standardFontSize,
                                      fontFamily: 'Noto Sans JP',
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
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}