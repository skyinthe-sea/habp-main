import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/underline_button.dart';
import '../widgets/onboarding_alert.dart';
import '../widgets/onboarding_navigation.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 텍스트 영역 (화면의 절반)
            Expanded(
              flex: 1,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '고정소득의',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'YourCustomFont', // 실제 폰트 이름으로 변경 필요
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          UnderlineButton(
                            text: '종류와 금액',
                            width: 120,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => const OnboardingAlert(),
                              );
                            },
                          ),
                          const Text(
                            '을',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'YourCustomFont',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '입력해주세요',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontFamily: 'YourCustomFont',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 네비게이션 영역
            FadeTransition(
              opacity: _fadeAnimation,
              child: const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: OnboardingNavigation(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}