import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:habp/features/onboarding/presentation/widgets/page_content3_alert.dart';

import '../../../../core/constants/app_colors.dart';
import '../widgets/underline_button.dart';
import '../widgets/wave_background.dart';

class PageContent3 extends StatefulWidget {
  const PageContent3({Key? key}) : super(key: key);

  @override
  State<PageContent3> createState() => _PageContent3State();
}

class _PageContent3State extends State<PageContent3> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _textAnimations;
  bool _showGif = false;

  // 텍스트 라인 수
  final int _numTextElements = 3;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 각 텍스트 요소에 대한 애니메이션 생성
    _textAnimations = List.generate(_numTextElements, (index) {
      final start = index * 0.2; // 각 요소 사이에 20% 지연
      final end = start + 0.4;   // 각 요소는 전체 애니메이션의 40% 차지

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

    // 애니메이션 상태 리스너 추가
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 애니메이션이 완료되면 GIF 표시
        setState(() {
          _showGif = true;
        });
      }
    });

    // 애니메이션 시작
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

    return Center(
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Stack(children: [
          const WaveBackground(
            primaryColor: AppColors.grey,
            secondaryColor: AppColors.primary, // 민트빛 블렌딩
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 80.0, bottom: 80.0), // Leave space for indicators and buttons
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // GIF 영역 (GIF area) - 애니메이션 완료 후 표시
                  Flexible(
                    child: AnimatedOpacity(
                      opacity: _showGif ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: GifView.asset(
                        'assets/images/money-18548.gif',
                        height: size.height * 0.4, // Responsive height
                        width: size.width * 0.7, // Responsive width
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // 상단 텍스트 영역 (Text section)
                  Flexible(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // 첫 번째 텍스트
                            AnimatedOpacity(
                              opacity: _textAnimations[0].value,
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[0].value),
                                duration: const Duration(milliseconds: 300),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '재테크관련',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: size.width * 0.12,
                                      fontFamily: 'Noto Sans JP',
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 두 번째 텍스트 (Row)
                            AnimatedOpacity(
                              opacity: _textAnimations[1].value,
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[1].value),
                                duration: const Duration(milliseconds: 300),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // UnderlineButton은 원래 기능 유지
                                    UnderlineButton(
                                      text: '종류와 액수',
                                      width: size.width * 0.43,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => const PageContent3Alert(),
                                        );
                                      },
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '를',
                                        style: TextStyle(
                                          color: AppColors.white,
                                          fontSize: size.width * 0.12,
                                          fontFamily: 'Noto Sans JP',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 세 번째 텍스트
                            AnimatedOpacity(
                              opacity: _textAnimations[2].value,
                              duration: const Duration(milliseconds: 300),
                              child: AnimatedSlide(
                                offset: Offset(0, 1 - _textAnimations[2].value),
                                duration: const Duration(milliseconds: 300),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '입력해주세요',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: size.width * 0.12,
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