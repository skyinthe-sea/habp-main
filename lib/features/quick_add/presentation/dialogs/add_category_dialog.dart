// lib/features/quick_add/presentation/dialogs/add_category_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';

class AddCategoryDialog extends StatefulWidget {
  final QuickAddController controller;
  // onCategoryAdded 콜백은 옵셔널로 변경
  final Function(int, String)? onCategoryAdded;

  const AddCategoryDialog({
    Key? key,
    required this.controller,
    this.onCategoryAdded,
  }) : super(key: key);

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController categoryNameController = TextEditingController();
  bool isLoading = false;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    categoryNameController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      isButtonEnabled = categoryNameController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    categoryNameController.removeListener(_updateButtonState);
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryType = widget.controller.transaction.value.categoryType;
    final isIncome = categoryType == 'INCOME';
    final isFinance = categoryType == 'FINANCE';

    // 카테고리 타입에 따라 제목과 힌트 텍스트 변경
    String titleText;
    String hintText;

    if (isIncome) {
      titleText = '소득 카테고리 추가';
      hintText = '월급, 용돈, 부수입 등';
    } else if (isFinance) {
      titleText = '재테크 카테고리 추가';
      hintText = '주식, 저축, 가상화폐 등';
    } else {
      titleText = '지출 카테고리 추가';
      hintText = '식비, 교통비, 문화생활 등';
    }

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
                  titleText,
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
                setState(() {
                  isButtonEnabled = text.trim().isNotEmpty;
                });
              },
              decoration: InputDecoration(
                labelText: '카테고리 이름',
                hintText: hintText,
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
                      Navigator.of(context).pop();
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
                      setState(() {
                        isLoading = true;
                      });

                      // 컨트롤러를 통해 카테고리 추가
                      final result = await widget.controller.addCategory(
                        name: categoryNameController.text.trim(),
                        type: categoryType,
                        isFixed: 0, // 변동 카테고리
                      );

                      if (result != null) {
                        // 성공 메시지
                        Get.snackbar(
                          '성공',
                          '카테고리가 추가되었습니다.',
                          snackPosition: SnackPosition.TOP,
                        );

                        // 다이얼로그 닫기만 하고 자동으로 다음 단계로 진행하지 않음
                        Navigator.of(context).pop();

                        // 콜백이 있는 경우에만 호출 (옵션)
                        // if (widget.onCategoryAdded != null) {
                        //   widget.onCategoryAdded!(result.id, result.name);
                        // }
                      } else {
                        setState(() {
                          isLoading = false;
                        });

                        // 오류 메시지
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