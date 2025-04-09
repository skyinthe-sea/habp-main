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
  late List<Animation<double>> _wordAnimations;

  final List<String> _words = [
    '안녕하세요?',
    '정확하고',
    '편한',
    '수기가계부',
    '입니다.',
    '재무관리를',
    '도와드릴게요.'
  ];

  @override
  void initState() {
    super.initState();

    // Faster animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Reduced from 3 seconds
      vsync: this,
    );

    // Each word appears with a slight delay
    _wordAnimations = List.generate(_words.length, (index) {
      final start = index * 0.08; // Faster timing (0.08 instead of 0.1)
      final end = start + 0.25;   // Faster completion (0.25 instead of 0.3)

      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
              start.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: Curves.easeOut
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
    // Standard text size for all pages
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
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10,
                              runSpacing: 20,
                              children: List.generate(_words.length, (index) {
                                return AnimatedOpacity(
                                  opacity: _wordAnimations[index].value,
                                  duration: const Duration(milliseconds: 200), // Faster animation
                                  child: AnimatedSlide(
                                    offset: Offset(0, 1 - _wordAnimations[index].value),
                                    duration: const Duration(milliseconds: 200), // Faster animation
                                    child: Text(
                                      _words[index],
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: standardFontSize,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Noto Sans JP',
                                      ),
                                    ),
                                  ),
                                );
                              }),
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