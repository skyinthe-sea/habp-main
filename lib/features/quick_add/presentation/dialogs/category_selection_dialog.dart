// lib/features/quick_add/presentation/dialogs/category_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'add_category_dialog.dart';
import 'category_type_dialog.dart';
import 'date_selection_dialog.dart';

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
                      transitionBuilder:
                          (context, animation, secondaryAnimation, child) {
                        final curve = CurvedAnimation(
                          parent: animation,
                          curve: Curves.elasticOut,
                        );

                        return ScaleTransition(
                          scale: curve,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
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

            // Add category button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () {
                  // 카테고리 추가 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder: (context) => AddCategoryDialog(
                      controller: controller,
                      // 콜백 제거 또는 null로 설정하여 자동 진행하지 않도록 함
                      // onCategoryAdded: (categoryId, categoryName) { ... },
                    ),
                  );
                },
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_getTypeLabel(controller.transaction.value.categoryType)} 카테고리 추가',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 카테고리 삭제 안내 문구
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '카테고리를 길게 누르면 삭제할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

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

  Widget _buildCategoryItem({
    required BuildContext context,
    required int categoryId,
    required String categoryName,
    required QuickAddController controller,
  }) {
    return InkWell(
      onLongPress: () {
        // 카테고리 삭제 확인 다이얼로그 표시
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('카테고리 삭제'),
              content: Text('\'$categoryName\' 카테고리를 삭제하시겠습니까? \n 설정한 예산정보도 삭제됩니다.'),
              actions: [
                TextButton(
                  child: const Text('취소'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
                TextButton(
                  child: const Text('확인'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () async {
                    // 다이얼로그 닫기
                    Navigator.of(dialogContext).pop();

                    // 카테고리 삭제 시도
                    final success = await controller.deleteCategory(categoryId);

                    if (success) {
                      // 성공 메시지
                      Get.snackbar(
                        '삭제 완료',
                        '\'$categoryName\' 카테고리가 삭제되었습니다.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      // 실패 메시지
                      Get.snackbar(
                        '삭제 실패',
                        '해당 카테고리는 삭제할 수 없습니다.',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
      onTap: () {
        // Set the selected category
        controller.setCategory(categoryId, categoryName);

        // Close this dialog and show the next one
        Navigator.of(context).pop();

        // Show date selection dialog with animation
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => const DateSelectionDialog(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            );

            return ScaleTransition(
              scale: curve,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
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

  String _getTypeLabel(String type) {
    switch (type) {
      case 'INCOME':
        return '소득';
      case 'EXPENSE':
        return '지출';
      case 'FINANCE':
        return '재테크';
      default:
        return '';
    }
  }
}