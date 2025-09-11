import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/models/category_model.dart';
import '../controllers/expense_controller.dart';
import 'add_category_dialog.dart';

class MultiCategoryBudgetDialog extends StatefulWidget {
  final ExpenseController controller;

  const MultiCategoryBudgetDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<MultiCategoryBudgetDialog> createState() => _MultiCategoryBudgetDialogState();
}

class _MultiCategoryBudgetDialogState extends State<MultiCategoryBudgetDialog> with SingleTickerProviderStateMixin {
  // Selected categories map: category id -> budget amount
  final Map<int, double> selectedCategories = {};

  // Amount input controllers
  final TextEditingController defaultAmountController = TextEditingController();
  final Map<int, TextEditingController> categoryAmountControllers = {};

  // Search and filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // State variables
  bool isLoading = false;
  bool _isSaveButtonEnabled = false;
  bool _useDefaultAmount = true;
  bool _isCompleted = false; // 추가: 완료 상태 추적 변수

  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    defaultAmountController.addListener(_updateSaveButtonState);

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    defaultAmountController.removeListener(_updateSaveButtonState);
    defaultAmountController.dispose();

    // Dispose all category amount controllers
    for (var controller in categoryAmountControllers.values) {
      controller.dispose();
    }

    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      // 검색어가 변경되면 완료 상태 리셋
      if (_isCompleted) {
        _isCompleted = false;
      }
    });
  }

  void _updateSaveButtonState() {
    setState(() {
      // 완료 상태일 경우 버튼은 항상 활성화
      if (_isCompleted) {
        _isSaveButtonEnabled = true;
        return;
      }

      bool hasValidAmounts = true;

      if (_useDefaultAmount) {
        hasValidAmounts = defaultAmountController.text.isNotEmpty &&
            double.tryParse(defaultAmountController.text.replaceAll(',', '')) != null &&
            double.tryParse(defaultAmountController.text.replaceAll(',', ''))! > 0;
      } else {
        // Check if each selected category has a valid amount
        for (var categoryId in selectedCategories.keys) {
          final controller = categoryAmountControllers[categoryId];
          if (controller == null || controller.text.isEmpty ||
              double.tryParse(controller.text.replaceAll(',', '')) == null ||
              double.tryParse(controller.text.replaceAll(',', ''))! <= 0) {
            hasValidAmounts = false;
            break;
          }
        }
      }

      _isSaveButtonEnabled = selectedCategories.isNotEmpty &&
          hasValidAmounts &&
          !isLoading;
    });
  }

  // Format currency with comma separators
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    // Remove commas and non-numeric characters
    String onlyNums = value.replaceAll(RegExp(r'[^\d]'), '');

    // Parse to integer
    int amount = int.tryParse(onlyNums) ?? 0;

    // Format with commas
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // Toggle category selection
  void _toggleCategorySelection(CategoryModel category) {
    setState(() {
      // 카테고리 선택 상태가 변경되면 완료 상태 리셋
      _isCompleted = false;

      if (selectedCategories.containsKey(category.id)) {
        // Remove if already selected
        selectedCategories.remove(category.id);
        categoryAmountControllers.remove(category.id);
      } else {
        // Add if not selected
        selectedCategories[category.id] = 0.0;

        // Create a new controller for this category
        final controller = TextEditingController();
        categoryAmountControllers[category.id] = controller;

        // If using default amount, pre-fill with default amount
        if (_useDefaultAmount && defaultAmountController.text.isNotEmpty) {
          controller.text = defaultAmountController.text;
        }

        controller.addListener(_updateSaveButtonState);
      }
      _updateSaveButtonState();
    });
  }

  // Show category delete confirmation dialog
  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    final ThemeController themeController = Get.find<ThemeController>();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeController.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '카테고리 삭제',
          style: TextStyle(
            color: themeController.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\'${category.name}\' 카테고리를 삭제하시겠습니까?',
              style: TextStyle(
                fontSize: 16,
                color: themeController.textPrimaryColor,
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
                color: themeController.textSecondaryColor,
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

                  // Remove from selected categories if it was selected
                  if (selectedCategories.containsKey(category.id)) {
                    setState(() {
                      selectedCategories.remove(category.id);
                      if (categoryAmountControllers.containsKey(category.id)) {
                        categoryAmountControllers[category.id]?.dispose();
                        categoryAmountControllers.remove(category.id);
                      }
                      _updateSaveButtonState();
                    });
                  }

                  // Delete the category
                  final success = await widget.controller.deleteCategory(category.id);

                  Navigator.of(context).pop();

                  // Show result notification
                  if (success) {
                    Get.snackbar(
                      '성공',
                      '카테고리가 삭제되었습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '카테고리 삭제에 실패했습니다.',
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
                    valueColor: AlwaysStoppedAnimation<Color>(themeController.primaryColor),
                  ),
                )
                    : Text(
                  '삭제',
                  style: TextStyle(
                    color: themeController.isDarkMode ? Colors.red.shade400 : Colors.red.shade700,
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

  // Save budgets for all selected categories
  Future<void> _saveBudgets() async {
    setState(() {
      isLoading = true;
      _updateSaveButtonState();
    });

    int successCount = 0;
    int failCount = 0;

    // Process each selected category
    for (var entry in selectedCategories.entries) {
      final categoryId = entry.key;

      // Get the amount based on the mode
      double amount;
      if (_useDefaultAmount) {
        amount = double.tryParse(defaultAmountController.text.replaceAll(',', '')) ?? 0;
      } else {
        final controller = categoryAmountControllers[categoryId];
        if (controller == null) continue;
        amount = double.tryParse(controller.text.replaceAll(',', '')) ?? 0;
      }

      if (amount <= 0) continue;

      // Add the budget
      final success = await widget.controller.addBudget(
        categoryId: categoryId,
        amount: amount,
      );

      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    // 상태 업데이트 - 로딩 중단 및 완료 상태로 변경
    setState(() {
      isLoading = false;
      if (successCount > 0) {
        _isCompleted = true;
      }
      _updateSaveButtonState();
    });

    // Show result notification
    if (successCount > 0) {
      Get.snackbar(
        '성공',
        '${successCount}개의 예산이 설정되었습니다.',
        snackPosition: SnackPosition.TOP,
      );

      // 대화상자를 닫지 않고 완료 버튼 표시하도록 변경
      // Get.back(); <- 이 줄 제거
    } else {
      Get.snackbar(
        '오류',
        '예산 설정에 실패했습니다.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: themeController.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeController.isDarkMode 
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with background gradient
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeController.primaryColor.withOpacity(0.8),
                      themeController.primaryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '다중 예산 설정',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.controller.selectedPeriod.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Default amount mode selector
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeController.isDarkMode 
                                ? Colors.grey.shade800.withOpacity(0.3)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeController.isDarkMode 
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade200
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '예산 설정 방식',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: themeController.textPrimaryColor,
                                    ),
                                  ),
                                  Switch(
                                    value: _useDefaultAmount,
                                    activeColor: themeController.primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _useDefaultAmount = value;
                                        // 스위치 변경 시 완료 상태 리셋
                                        _isCompleted = false;
                                        if (value && defaultAmountController.text.isNotEmpty) {
                                          // Copy default amount to all selected categories
                                          for (var categoryId in selectedCategories.keys) {
                                            categoryAmountControllers[categoryId]?.text =
                                                defaultAmountController.text;
                                          }
                                        }
                                        _updateSaveButtonState();
                                      });
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                _useDefaultAmount
                                    ? '모든 카테고리에 동일한 예산 금액 설정'
                                    : '카테고리별로 다른 예산 금액 설정',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: themeController.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Default amount input (when in default amount mode)
                        AnimatedOpacity(
                          opacity: _useDefaultAmount ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _useDefaultAmount ? null : 0,
                            child: _useDefaultAmount ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '기본 예산 금액',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: themeController.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: themeController.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: themeController.primaryColor.withOpacity(0.5)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeController.isDarkMode 
                                            ? Colors.black.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: defaultAmountController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    onChanged: (value) {
                                      // 입력값이 변경되면 완료 상태 리셋
                                      if (_isCompleted) {
                                        setState(() {
                                          _isCompleted = false;
                                        });
                                      }

                                      if (value.isNotEmpty) {
                                        final formatted = _formatCurrency(value);
                                        if (formatted != value) {
                                          defaultAmountController.value = TextEditingValue(
                                            text: formatted,
                                            selection: TextSelection.collapsed(
                                              offset: formatted.length,
                                            ),
                                          );
                                        }

                                        // Also update all category amount controllers
                                        if (_useDefaultAmount) {
                                          for (var categoryId in selectedCategories.keys) {
                                            categoryAmountControllers[categoryId]?.text = formatted;
                                          }
                                        }
                                      }
                                      _updateSaveButtonState();
                                    },
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: themeController.textPrimaryColor,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '금액을 입력하세요',
                                      hintStyle: TextStyle(
                                        color: themeController.textSecondaryColor,
                                        fontSize: 16,
                                      ),
                                      suffixText: '원',
                                      suffixStyle: TextStyle(
                                        color: themeController.textSecondaryColor,
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
                                const SizedBox(height: 20),
                              ],
                            ) : const SizedBox(),
                          ),
                        ),

                        // Categories section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '카테고리 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: themeController.textPrimaryColor,
                              ),
                            ),
                            Row(
                              children: [
                                if (selectedCategories.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        for (var controller in categoryAmountControllers.values) {
                                          controller.dispose();
                                        }
                                        selectedCategories.clear();
                                        categoryAmountControllers.clear();
                                        // 카테고리 전체 해제 시 완료 상태 리셋
                                        _isCompleted = false;
                                        _updateSaveButtonState();
                                      });
                                    },
                                    icon: const Icon(Icons.clear, size: 16),
                                    label: Text('전체 해제 (${selectedCategories.length})'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: themeController.textSecondaryColor,
                                      side: BorderSide(color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AddCategoryDialog(
                                        controller: widget.controller,
                                        onCategoryAdded: (categoryId) {
                                          // Auto-select newly added category
                                          setState(() {
                                            selectedCategories[categoryId] = 0.0;
                                            // 새 카테고리 추가 시 완료 상태 리셋
                                            _isCompleted = false;

                                            final controller = TextEditingController();
                                            categoryAmountControllers[categoryId] = controller;

                                            if (_useDefaultAmount && defaultAmountController.text.isNotEmpty) {
                                              controller.text = defaultAmountController.text;
                                            }

                                            controller.addListener(_updateSaveButtonState);
                                            _updateSaveButtonState();
                                          });
                                        },
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('추가'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeController.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Search field
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: themeController.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: themeController.isDarkMode 
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: themeController.isDarkMode 
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(color: themeController.textPrimaryColor),
                            decoration: InputDecoration(
                              hintText: '카테고리 검색',
                              hintStyle: TextStyle(color: themeController.textSecondaryColor),
                              prefixIcon: Icon(Icons.search, color: themeController.textSecondaryColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),

                        // Categories grid
                        Obx(() {
                          final categories = widget.controller.variableCategories;

                          // Filter by search
                          List<CategoryModel> filteredCategories = categories;
                          if (_searchQuery.isNotEmpty) {
                            filteredCategories = categories.where(
                                    (c) => c.name.toLowerCase().contains(_searchQuery)
                            ).toList();
                          }

                          if (filteredCategories.isEmpty) {
                            return Container(
                              height: 200,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: themeController.isDarkMode 
                                    ? Colors.grey.shade800.withOpacity(0.3)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: themeController.isDarkMode 
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade200
                                ),
                              ),
                              child: Text(
                                _searchQuery.isNotEmpty
                                    ? '검색 결과가 없습니다'
                                    : '등록된 카테고리가 없습니다',
                                style: TextStyle(
                                  color: themeController.textSecondaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.6,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredCategories.length,
                            itemBuilder: (context, index) {
                              final category = filteredCategories[index];
                              final isSelected = selectedCategories.containsKey(category.id);

                              return CategoryBudgetCard(
                                category: category,
                                isSelected: isSelected,
                                amountController: categoryAmountControllers[category.id],
                                showAmountField: !_useDefaultAmount && isSelected,
                                onSelected: () => _toggleCategorySelection(category),
                                onDelete: () => _showDeleteCategoryDialog(context, category),
                                onAmountChanged: (value) {
                                  // 개별 카테고리 금액 변경 시 완료 상태 리셋
                                  if (_isCompleted) {
                                    setState(() {
                                      _isCompleted = false;
                                    });
                                  }

                                  if (value.isNotEmpty) {
                                    final formatted = _formatCurrency(value);
                                    if (formatted != value) {
                                      categoryAmountControllers[category.id]?.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    }
                                  }
                                  _updateSaveButtonState();
                                },
                              );
                            },
                          );
                        }),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 14, color: themeController.textSecondaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '카테고리를 길게 누르면 삭제할 수 있습니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: themeController.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: themeController.cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: themeController.textSecondaryColor,
                          side: BorderSide(color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSaveButtonEnabled
                            ? () {
                          if (_isCompleted) {
                            // 완료 상태면 다이얼로그 닫기
                            Get.back();
                          } else {
                            // 아니면 예산 저장
                            _saveBudgets();
                          }
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isCompleted ? Colors.green : themeController.primaryColor,
                          disabledBackgroundColor: themeController.primaryColor.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _isCompleted
                              ? '완료'
                              : (selectedCategories.isNotEmpty
                              ? '${selectedCategories.length}개 카테고리 예산 설정'
                              : '예산 설정하기'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Individual category card with budget amount input
class CategoryBudgetCard extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final bool showAmountField;
  final TextEditingController? amountController;
  final VoidCallback onSelected;
  final VoidCallback onDelete;
  final Function(String) onAmountChanged;

  const CategoryBudgetCard({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.showAmountField,
    required this.amountController,
    required this.onSelected,
    required this.onDelete,
    required this.onAmountChanged,
  }) : super(key: key);

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case '식비':
        return Icons.restaurant;
      case '교통비':
        return Icons.directions_bus;
      case '문화생활':
        return Icons.movie;
      case '쇼핑':
        return Icons.shopping_bag;
      case '통신비':
        return Icons.phone_android;
      case '교육비':
        return Icons.school;
      case '카페':
        return Icons.coffee;
      case '의료비':
        return Icons.medical_services;
      case '주거비':
        return Icons.home;
      case '월세':
        return Icons.home;
      case '보험':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    // Category colors based on selection state
    final cardColor = isSelected
        ? themeController.primaryColor.withOpacity(0.1)
        : themeController.cardColor;

    final borderColor = isSelected
        ? themeController.primaryColor
        : (themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200);

    final iconColor = isSelected
        ? themeController.primaryColor
        : themeController.textSecondaryColor;

    return GestureDetector(
      onTap: onSelected,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isSelected ? [
            BoxShadow(
              color: themeController.primaryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Stack(
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name and icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeController.primaryColor.withOpacity(0.2)
                              : (themeController.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(category.name),
                          size: 16,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? themeController.primaryColor : themeController.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Budget amount field (when individual amounts are enabled)
                  if (showAmountField && amountController != null)
                    Expanded(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: themeController.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: themeController.primaryColor.withOpacity(0.3)),
                          ),
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: onAmountChanged,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: themeController.textPrimaryColor,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: '금액 입력',
                              hintStyle: TextStyle(
                                color: themeController.textSecondaryColor,
                                fontSize: 12,
                              ),
                              suffixText: '원',
                              suffixStyle: TextStyle(
                                color: themeController.textSecondaryColor,
                                fontSize: 12,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Selection indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? themeController.primaryColor 
                      : (themeController.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected 
                        ? themeController.primaryColor 
                        : (themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                    width: 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}