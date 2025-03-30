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

    // 전체 애니메이션을 위한 컨트롤러
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // 각 단어별 애니메이션 생성
    _wordAnimations = List.generate(_words.length, (index) {
      // 각 단어는 이전 단어보다 약간 늦게 나타남
      final start = index * 0.1; // 단어 간 10% 지연
      final end = start + 0.3;   // 각 단어는 전체 애니메이션 시간의 30%를 차지

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
              padding: const EdgeInsets.only(top: 80.0, bottom: 80.0), // 인디케이터와 버튼을 위한 공간
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 환영 텍스트 영역
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
                              runSpacing: 20, // 줄 간격
                              children: List.generate(_words.length, (index) {
                                return AnimatedOpacity(
                                  opacity: _wordAnimations[index].value,
                                  duration: const Duration(milliseconds: 300),
                                  child: AnimatedSlide(
                                    offset: Offset(0, 1 - _wordAnimations[index].value),
                                    duration: const Duration(milliseconds: 300),
                                    child: Text(
                                      _words[index],
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: size.width * 0.07,
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