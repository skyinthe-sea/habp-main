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
                    onPressed: () {
                      // 알럿 다이얼로그 표시
                      Get.dialog(
                        AlertDialog(
                          backgroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          title: const Text(
                            '설정 건너뛰기',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            '초기설정을 건너뛰시겠습니까?\n나중에 설정에서 다시 볼 수 있습니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.black,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(), // 다이얼로그 닫기
                              child: const Text(
                                '취소',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.back(); // 다이얼로그 닫기
                                controller.skipOnboarding(); // 온보딩 건너뛰기 함수 호출
                              },
                              child: const Text(
                                '확인',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            // ElevatedButton(
                            //   onPressed: () {
                            //     Get.back(); // 다이얼로그 닫기
                            //     controller.skipOnboarding(); // 온보딩 건너뛰기 함수 호출
                            //   },
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor: AppColors.primary,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(30),
                            //     ),
                            //   ),
                            //   child: const Text('확인'),
                            // ),
                          ],
                        ),
                      );
                    },
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
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
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      title: const Text(
                                        '설정완료',
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        '최고의 재무관리를 받으러 가시겠습니까?',
                                        style: TextStyle(
                                          color: AppColors.black,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // 알럿 닫기
                                          },
                                          child: const Text('취소',
                                              style: TextStyle(
                                                  color: Colors.grey)),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context)
                                                .pop(); // 알럿 닫기
                                            controller
                                                .completeOnboarding(); // 완료 함수 호출
                                          },
                                          child: const Text(
                                            '확인',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
