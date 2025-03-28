// lib/features/quick_add/presentation/dialogs/category_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'category_type_dialog.dart';
import 'date_selection_dialog.dart';

/// Second dialog in the quick add flow
/// Shows scrollable list of categories to select from
class CategorySelectionDialog extends StatelessWidget {
  const CategorySelectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog title and back button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getTypeLabel(controller.transaction.value.categoryType)} 카테고리 선택',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () {
                    // Go back to the previous dialog
                    Navigator.of(context).pop();

                    // Show the category type dialog again
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (_, __, ___) => const CategoryTypeDialog(),
                      transitionBuilder: (context, animation, secondaryAnimation, child) {
                        // 풍선 터지는 효과를 위한 커브 설정
                        final curve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
                        );

                        // 크기 애니메이션을 적용
                        return ScaleTransition(
                          scale: curve, // elasticOut 커브를 적용
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      // 매우 빠른 애니메이션을 위해 시간 단축
                      transitionDuration: const Duration(milliseconds: 150),
                      barrierDismissible: true,
                      barrierLabel: '',
                      barrierColor: Colors.black.withOpacity(0.5),
                    );
                  },
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Categories list
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.categories.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      '등록된 카테고리가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Container(
                constraints: BoxConstraints(
                  // Limit height to ensure dialog doesn't overflow
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.0,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  shrinkWrap: true,
                  itemCount: controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    return _buildCategoryItem(
                      context: context,
                      categoryId: category['id'],
                      categoryName: category['name'],
                      controller: controller,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds an individual category selection item
  Widget _buildCategoryItem({
    required BuildContext context,
    required int categoryId,
    required String categoryName,
    required QuickAddController controller,
  }) {
    return InkWell(
      onTap: () {
        // Set the selected category
        controller.setCategory(categoryId, categoryName);

        // Close this dialog and show the next one
        Navigator.of(context).pop();

        // Show date selection dialog with animation
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => const DateSelectionDialog(), // 다음 다이얼로그 컴포넌트
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            // 풍선 터지는 효과를 위한 커브 설정
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut, // 가장 중요한 설정! 풍선 튕김 효과
            );

            // 크기 애니메이션을 적용
            return ScaleTransition(
              scale: curve, // elasticOut 커브를 적용
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          // 매우 빠른 애니메이션을 위해 시간 단축
          transitionDuration: const Duration(milliseconds: 150),
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withOpacity(0.5),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            categoryName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// Returns a human-readable label for the transaction type
  String _getTypeLabel(String type) {
    switch (type) {
      case 'INCOME':
        return '소득';
      case 'EXPENSE':
        return '지출';
      case 'FINANCE':
        return '금융';
      default:
        return '';
    }
  }
}