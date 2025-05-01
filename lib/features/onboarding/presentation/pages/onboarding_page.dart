// lib/features/onboarding/presentation/pages/onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content0.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content1.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content2.dart';
import 'package:habp/features/onboarding/presentation/pages/page_content3.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/blinking_text_button.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(OnboardingController());

    // Page content list - including welcome page
    final pageContents = [
      const PageContent0(), // Welcome page
      const PageContent1(), // Income information
      const PageContent2(), // Expense information
      const PageContent3(), // Finance/Investment information
    ];

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Page content with swipe detection - changes based on current index
          Obx(() =>
              GestureDetector(
                // Detect swipe gestures
                onHorizontalDragEnd: (details) {
                  // Check the drag velocity
                  if (details.primaryVelocity != null) {
                    // Swiping from right to left (negative velocity) - Next page
                    if (details.primaryVelocity! < -300) {
                      if (controller.currentPageIndex.value < controller.totalPages - 1) {
                        controller.nextPage();
                      }
                    }
                    // Swiping from left to right (positive velocity) - Previous page
                    else if (details.primaryVelocity! > 300) {
                      if (controller.currentPageIndex.value > 0) {
                        controller.previousPage();
                      }
                    }
                  }
                },
                // Detect taps, but only when not tapping on a BlinkingTextButton
                onTap: () {
                  // Navigation to next page on general screen tap
                  if (controller.currentPageIndex.value < controller.totalPages - 1) {
                    controller.nextPage();
                  } else {
                    // Show completion dialog on last page
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          title: const Text(
                            '설정완료',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: const Text(
                            '수기가계부를 시작 하시겠습니까?',
                            style: TextStyle(
                              color: AppColors.black,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close alert
                              },
                              child: const Text('취소',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close alert
                                controller.completeOnboarding(); // Complete
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
                  }
                },
                // This allows BlinkingTextButton to capture taps directly
                behavior: HitTestBehavior.deferToChild,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500), // Faster transition
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: pageContents[controller.currentPageIndex.value],
                ),
              ),
          ),

          // Modern dot indicator
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: Obx(() => _buildModernIndicator(
              currentIndex: controller.currentPageIndex.value,
              pageCount: controller.totalPages,
            )),
          ),

          // Skip button - hidden on last page
          Positioned(
            top: 90,
            right: 16,
            child: Obx(() => AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: controller.currentPageIndex.value < controller.totalPages - 1 ? 1.0 : 0.0,
              child: TextButton(
                onPressed: controller.currentPageIndex.value < controller.totalPages - 1
                    ? () {
                  // Alert dialog
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
                          onPressed: () => Get.back(), // Close dialog
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Get.back(); // Close dialog
                            controller.skipOnboarding(); // Skip onboarding
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
                    ),
                  );
                }
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.white,
                ),
                child: const Text(
                  'skip',
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
            )),
          ),

          // Bottom navigation buttons - now optional, kept for visual aid
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => _buildNavigationButtons(context, controller)),
          ),
        ],
      ),
    );
  }

  // Modern dot indicator
  Widget _buildModernIndicator({required int currentIndex, required int pageCount}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
            (index) => Container(
          width: index == currentIndex ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == currentIndex ? AppColors.white : AppColors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // Navigation buttons - still present for visual guidance and accessibility
  Widget _buildNavigationButtons(BuildContext context, OnboardingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first page)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: controller.currentPageIndex.value > 0 ? 1.0 : 0.0,
            child: controller.currentPageIndex.value > 0
                ? IconButton(
              onPressed: controller.previousPage,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios, size: 16),
              ),
              color: AppColors.white,
            )
                : const SizedBox(width: 48),
          ),

          // Center placeholder
          const SizedBox(),

          // Forward/Done button
          controller.currentPageIndex.value < controller.totalPages - 1
              ? IconButton(
            onPressed: controller.nextPage,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            color: AppColors.white,
          )
              : IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: const Text(
                      '설정완료',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      '수기가계부를 시작 하시겠습니까?',
                      style: TextStyle(
                        color: AppColors.black,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close alert
                        },
                        child: const Text('취소',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close alert
                          controller.completeOnboarding(); // Complete
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: AppColors.primary),
            ),
            color: AppColors.white,
          )
        ],
      ),
    );
  }
}