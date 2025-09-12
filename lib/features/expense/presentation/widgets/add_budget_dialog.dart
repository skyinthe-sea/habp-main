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
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 텍스트 변경 시 저장 버튼 활성화 상태 업데이트를 위한 리스너
    amountController.addListener(_updateSaveButtonState);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    amountController.removeListener(_updateSaveButtonState);
    amountController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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
              '\'${category.name}\' 예산 정보를 삭제하시겠습니까?',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
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
                    final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '성공',
            '카테고리가 삭제되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
                      snackPosition: SnackPosition.TOP,
                    );
                  } else {
                    final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '카테고리 삭제에 실패했습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
                      snackPosition: SnackPosition.TOP,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '예산 추가하기',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                    onPressed: () => Get.back(),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 금액 입력 섹션
              _buildBudgetAmountSection(),
              const SizedBox(height: 24),

              // 카테고리 선택 섹션
              _buildCategorySelectionSection(),
              const SizedBox(height: 24),

              // 기간 선택 안내
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
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
                        elevation: 0,
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
                          final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '유효한 금액을 입력하세요.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
                            snackPosition: SnackPosition.TOP,
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
                          final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '성공',
            '예산이 추가되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
                            snackPosition: SnackPosition.TOP,
                          );
                        } else {
                          setState(() {
                            isLoading = false;
                            _updateSaveButtonState();
                          });
                          final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '예산 추가에 실패했습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
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

  // 예산 금액 입력 섹션
  Widget _buildBudgetAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예산 금액',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: '금액을 입력하세요',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
              suffixText: '원',
              suffixStyle: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // 카테고리 선택 섹션
  Widget _buildCategorySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '카테고리',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.add, size: 16),
              label: const Text('추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 검색 필드
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '카테고리 검색',
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // 카테고리 목록
        Obx(() {
          final categories = widget.controller.variableCategories;

          // 검색 필터링
          List<CategoryModel> filteredCategories = categories;
          if (_searchQuery.isNotEmpty) {
            filteredCategories = categories.where(
                    (c) => c.name.toLowerCase().contains(_searchQuery)
            ).toList();
          }

          // 이전 카테고리 ID 목록 저장 (애니메이션 효과용)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_previousCategoryIds.isEmpty ||
                categories.length != _previousCategoryIds.length) {
              setState(() {
                _previousCategoryIds = categories.map((c) => c.id).toList();
              });
            }
          });

          if (filteredCategories.isEmpty) {
            return Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _searchQuery.isNotEmpty
                    ? '검색 결과가 없습니다'
                    : '등록된 카테고리가 없습니다',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            );
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              itemCount: filteredCategories.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.shade200,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                final isSelected = selectedCategoryId == category.id;
                final isNewlyAdded = isSelected &&
                    !_previousCategoryIds.contains(category.id);

                return ListTile(
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category.id;
                      _updateSaveButtonState();
                    });
                  },
                  onLongPress: () {
                    _showDeleteCategoryDialog(context, category);
                  },
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _showDeleteCategoryDialog(context, category);
                    },
                    splashRadius: 20,
                  ),
                  tileColor: isSelected ? AppColors.primary.withOpacity(0.05) : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          '카테고리를 길게 누르면 삭제할 수 있습니다.',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}