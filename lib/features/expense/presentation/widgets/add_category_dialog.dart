import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/expense_controller.dart';

class AddCategoryDialog extends StatefulWidget {
  final ExpenseController controller;
  final Function(int) onCategoryAdded;

  const AddCategoryDialog({
    Key? key,
    required this.controller,
    required this.onCategoryAdded,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController categoryNameController = TextEditingController();
  bool isLoading = false;
  bool isButtonEnabled = false;

  // 고정 카테고리 리스트
  final List<String> fixedCategories = ['통신비', '보험', '월세'];

  @override
  void initState() {
    super.initState();
    // 텍스트 변경 시 버튼 활성화 상태 업데이트를 위한 리스너
    categoryNameController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = categoryNameController.text.trim().isNotEmpty;
    });
  }

  // 고정 카테고리 알림 다이얼로그 표시
  void _showFixedCategoryAlert(BuildContext context, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('고정 카테고리 알림'),
          content: Text(
            '\'$categoryName\'은(는) 기본 고정 카테고리로 이미 존재합니다. 고정 카테고리는 사용자가 변경할 수 없습니다.',
            style: const TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: const Text(
                '확인',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    categoryNameController.removeListener(_updateButtonState);
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '지출 카테고리 추가',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 카테고리 이름 입력
            TextField(
              controller: categoryNameController,
              autofocus: true,
              onChanged: (text) {
                // 직접 상태 업데이트 (리스너와 함께 이중 보호)
                setState(() {
                  isButtonEnabled = text.trim().isNotEmpty;
                });
              },
              decoration: InputDecoration(
                labelText: '카테고리 이름',
                hintText: '식비, 교통비, 문화생활 등',
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading || !isButtonEnabled
                        ? null
                        : () async {
                      final categoryName = categoryNameController.text.trim();

                      // 고정 카테고리인지 확인
                      if (fixedCategories.contains(categoryName)) {
                        _showFixedCategoryAlert(context, categoryName);
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      final category = await widget.controller.addCategory(
                        name: categoryName,
                      );

                      if (category != null) {
                        Get.back();
                        widget.onCategoryAdded(category.id);
                        Get.snackbar(
                          '성공',
                          '카테고리가 추가되었습니다.',
                          snackPosition: SnackPosition.TOP,
                        );
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                        Get.snackbar(
                          '오류',
                          '카테고리 추가에 실패했습니다.',
                          snackPosition: SnackPosition.TOP,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      '추가하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}