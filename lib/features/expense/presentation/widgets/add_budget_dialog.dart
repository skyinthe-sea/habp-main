import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../controllers/expense_controller.dart';
import 'add_category_dialog.dart';

class AddBudgetDialog extends StatefulWidget {
  final ExpenseController controller;

  const AddBudgetDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  int? selectedCategoryId;
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;
  List<int> _previousCategoryIds = [];
  bool _isSaveButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    // 텍스트 변경 시 저장 버튼 활성화 상태 업데이트를 위한 리스너
    amountController.addListener(_updateSaveButtonState);
  }

  @override
  void dispose() {
    amountController.removeListener(_updateSaveButtonState);
    amountController.dispose();
    super.dispose();
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled = selectedCategoryId != null &&
          amountController.text.isNotEmpty &&
          !isLoading;
    });
  }

  // 금액 포맷팅 함수
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    // 콤마와 문자 제거
    String onlyNums = value.replaceAll(RegExp(r'[^\d]'), '');

    // 숫자를 정수로 변환
    int amount = int.tryParse(onlyNums) ?? 0;

    // 천 단위 콤마 포맷팅
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    );
  }

  // 카테고리 삭제 다이얼로그
  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '카테고리 삭제',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\'${category.name}\' 카테고리를 삭제하시겠습니까?',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '이 카테고리에 연결된 모든 예산 정보도 함께 삭제됩니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                  setDialogState(() {
                    isDeleting = true;
                  });

                  // 삭제 애니메이션을 위해 선택된 카테고리 ID 초기화
                  if (selectedCategoryId == category.id) {
                    setState(() {
                      selectedCategoryId = null;
                      _updateSaveButtonState();
                    });
                  }

                  // 카테고리 삭제
                  final success = await widget.controller.deleteCategory(category.id);

                  Navigator.of(context).pop();

                  // 결과 알림
                  if (success) {
                    Get.snackbar(
                      '성공',
                      '카테고리가 삭제되었습니다.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '카테고리 삭제에 실패했습니다.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                child: isDeleting
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
                    : Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '예산 추가하기',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 카테고리 선택
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '지출 카테고리',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // 카테고리 추가 다이얼로그 표시
                              showDialog(
                                context: context,
                                builder: (context) => AddCategoryDialog(
                                  controller: widget.controller,
                                  onCategoryAdded: (categoryId) {
                                    setState(() {
                                      selectedCategoryId = categoryId;
                                      _updateSaveButtonState();
                                    });
                                  },
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '카테고리 추가',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(() {
                      final categories = widget.controller.variableCategories;

                      // 이전 카테고리 ID 목록 저장 (애니메이션 효과용)
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_previousCategoryIds.isEmpty ||
                            categories.length != _previousCategoryIds.length) {
                          setState(() {
                            _previousCategoryIds = categories.map((c) => c.id).toList();
                          });
                        }
                      });

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: categories.isEmpty
                            ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                '변동 지출 카테고리가 없습니다.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('카테고리 추가하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AddCategoryDialog(
                                      controller: widget.controller,
                                      onCategoryAdded: (categoryId) {
                                        setState(() {
                                          selectedCategoryId = categoryId;
                                          _updateSaveButtonState();
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                            : Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(categories.length, (index) {
                              final category = categories[index];
                              final isSelected = selectedCategoryId == category.id;
                              final isNewlyAdded = isSelected &&
                                  !_previousCategoryIds.contains(category.id);

                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: 1.0,
                                child: Hero(
                                  tag: 'category-${category.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedCategoryId = category.id;
                                          _updateSaveButtonState();
                                        });
                                      },
                                      onLongPress: () {
                                        _showDeleteCategoryDialog(context, category);
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: isNewlyAdded
                                              ? [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ]
                                              : null,
                                        ),
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 예산 금액 입력
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12),
                      child: Text(
                        '예산 금액',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final formatted = _formatCurrency(value);
                            if (formatted != value) {
                              amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                  offset: formatted.length,
                                ),
                              );
                            }
                          }
                          _updateSaveButtonState();
                        },
                        decoration: InputDecoration(
                          hintText: '금액을 입력하세요',
                          suffixText: '원',
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
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 기간 선택 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '선택한 달(${widget.controller.selectedPeriod.value})에 대한 예산으로 설정됩니다.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isSaveButtonEnabled
                          ? null
                          : () async {
                        setState(() {
                          isLoading = true;
                          _updateSaveButtonState();
                        });

                        // 금액에서 콤마 제거
                        final amount = double.tryParse(
                            amountController.text.replaceAll(',', '')
                        ) ?? 0;

                        if (amount <= 0) {
                          Get.snackbar(
                            '오류',
                            '유효한 금액을 입력하세요.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          setState(() {
                            isLoading = false;
                            _updateSaveButtonState();
                          });
                          return;
                        }

                        final success = await widget.controller.addBudget(
                          categoryId: selectedCategoryId!,
                          amount: amount,
                        );

                        if (success) {
                          Get.back();
                          Get.snackbar(
                            '성공',
                            '예산이 추가되었습니다.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          setState(() {
                            isLoading = false;
                            _updateSaveButtonState();
                          });
                          Get.snackbar(
                            '오류',
                            '예산 추가에 실패했습니다.',
                            snackPosition: SnackPosition.BOTTOM,
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
                        '저장하기',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}