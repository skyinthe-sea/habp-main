import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content1.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content2.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content3.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/dot_indicators.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 초기화
    final controller = Get.put(OnboardingController());

    // 페이지 콘텐츠 리스트
    final pageContents = [
      const PageContent1(),
      const PageContent2(),
      const PageContent3(),
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // 페이지 내용 - 현재 인덱스에 따라 변경됨
          Obx(() => AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: pageContents[controller.currentPageIndex.value],
          )),

          // 상단 페이지 인디케이터
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Obx(() => DotIndicators(
              currentIndex: controller.currentPageIndex.value,
              pageCount: 3,
            )),
          ),

          // 건너뛰기 버튼 - 마지막 페이지에서는 숨김
          Positioned(
            top: 90,
            right: 16,
            child: Obx(() => Visibility(
              visible: controller.currentPageIndex.value < 2,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white, // 글자 색 변경
                ),
                child: const Text(
                  'skip',
                  style: TextStyle(
                    fontSize: 20.0, // 글자 크기 변경
                  ),
                ),
              ),
            )),
          ),

          // 하단 버튼 영역
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 왼쪽 화살표 버튼 (첫 페이지에서는 숨김)
                  controller.currentPageIndex.value > 0
                      ? IconButton(
                    onPressed: controller.previousPage,
                    icon: const Icon(Icons.arrow_back_ios),
                    color: AppColors.white,
                  )
                      : const SizedBox(width: 48),

                  // 중앙 버튼 (마지막 페이지에서는 숨김)
                  // controller.currentPageIndex.value < 2
                  //     ? TextButton(
                  //   onPressed: controller.nextPage,
                  //   style: TextButton.styleFrom(
                  //     foregroundColor: AppColors.white, // 글자 색 변경
                  //   ),
                  //   child: const Text(
                  //     '',
                  //     style: TextStyle(
                  //       fontSize: 20.0, // 글자 크기 변경
                  //       fontWeight: FontWeight.bold, // 글자 굵기 설정
                  //     ),
                  //   ),
                  // ) :
                  const SizedBox(),

                  // 오른쪽 버튼 (마지막 페이지에서는 완료 버튼)
                  controller.currentPageIndex.value < 2
                      ? IconButton(
                    onPressed: controller.nextPage,
                    icon: const Icon(Icons.arrow_forward_ios),
                    color: AppColors.white,
                  )
                      : IconButton(
                    onPressed: controller.completeOnboarding,
                    icon: const Icon(Icons.check_sharp),
                    color: AppColors.white,
                  )
                  // TextButton(
                  //   onPressed: controller.completeOnboarding,
                  //   child: const Text('완료'),
                  //   style: TextButton.styleFrom(
                  //     backgroundColor: AppColors.white,
                  //     foregroundColor: AppColors.grey,
                  //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(30),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }
}