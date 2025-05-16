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
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_getTypeLabel(controller.transaction.value.categoryType)} 카테고리 추가',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 카테고리 수정/삭제 안내 문구
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '카테고리를 길게 누르면 수정 또는 삭제할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories list - 작은 스티커 느낌의 그리드로 변경
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                            Icons.category_outlined,
                            size: 28,
                            color: Colors.grey.shade400
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '등록된 카테고리가 없습니다.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 스크롤 가능한 그리드 컨테이너
              return Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: GridView.builder(
                  // 그리드 설정 - 더 작은 아이템 크기와 간격
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 한 줄에 4개
                    childAspectRatio: 1.3, // 약간 가로가 긴 비율
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  shrinkWrap: true,
                  itemCount: controller.categories.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final category = controller.categories[index];
                    return _buildStickerCategoryItem(
                      context: context,
                      categoryId: category['id'],
                      categoryName: category['name'],
                      controller: controller,
                      index: index,
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

  // 스티커 느낌의 카테고리 아이템 위젯
  Widget _buildStickerCategoryItem({
    required BuildContext context,
    required int categoryId,
    required String categoryName,
    required QuickAddController controller,
    required int index,
  }) {
    // 카테고리 유형에 따른 색상 설정
    final categoryType = controller.transaction.value.categoryType;
    Color mainColor;

    // 유형별 색상 지정
    switch (categoryType) {
      case 'INCOME':
        mainColor = Colors.green.shade600;
        break;
      case 'EXPENSE':
        mainColor = AppColors.primary;
        break;
      case 'FINANCE':
        mainColor = Colors.blue.shade600;
        break;
      default:
        mainColor = AppColors.primary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () {
          // 카테고리 수정/삭제 옵션 표시
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (bottomSheetContext) => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.edit, color: mainColor),
                    title: const Text('카테고리 수정'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showEditCategoryDialog(context, categoryId, categoryName, controller);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('카테고리 삭제'),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _showDeleteConfirmDialog(context, categoryId, categoryName, controller);
                    },
                  ),
                ],
              ),
            ),
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
        // 스티커 효과를 위한 원형 경계
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            // 스티커 느낌을 위한 미묘한 그림자 효과
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
            // 스티커 느낌의 테두리
            border: Border.all(
              color: mainColor.withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // 스티커 효과를 위한 배경 그라데이션
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  gradient: LinearGradient(
                    colors: [
                      mainColor.withOpacity(0.15),
                      mainColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),

              // 텍스트 내용
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      // 스티커 효과를 위한 텍스트 그림자
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(0.5),
                          offset: const Offset(0, 0.5),
                          blurRadius: 0.5,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // 스티커 효과를 위한 광택 (subtle shine)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(7),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ],
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

  // 카테고리 수정 다이얼로그
  void _showEditCategoryDialog(BuildContext context, int categoryId, String categoryName, QuickAddController controller) {
    final nameController = TextEditingController(text: categoryName);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('카테고리 수정'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '카테고리 이름을 입력하세요',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar(
                  '오류',
                  '카테고리 이름을 입력해주세요.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              
              Navigator.pop(dialogContext);
              
              final success = await controller.updateCategory(categoryId, nameController.text.trim());
              if (success) {
                Get.snackbar(
                  '수정 완료',
                  '카테고리가 수정되었습니다.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  '수정 실패',
                  '카테고리 수정에 실패했습니다.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 카테고리 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context, int categoryId, String categoryName, QuickAddController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('카테고리 삭제'),
        content: Text('\'$categoryName\' 카테고리를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              
              final success = await controller.deleteCategory(categoryId);
              if (success) {
                Get.snackbar(
                  '삭제 완료',
                  '\'$categoryName\' 카테고리가 삭제되었습니다.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  '삭제 실패',
                  '해당 카테고리는 삭제할 수 없습니다.',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}