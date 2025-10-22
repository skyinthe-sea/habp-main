import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/expense/data/models/category_model.dart';
import '../../../../features/expense/presentation/controllers/expense_controller.dart';
import '../../domain/entities/user_challenge.dart';
import '../controllers/challenge_controller.dart';

/// 숫자 입력 시 자동으로 천 단위 콤마를 추가하는 포맷터
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // 콤마 제거 후 숫자만 추출
    final numericValue = newValue.text.replaceAll(',', '');

    // 숫자만 있는지 검증
    if (int.tryParse(numericValue) == null) {
      return oldValue;
    }

    // 콤마 포맷팅
    final formattedValue = _formatter.format(int.parse(numericValue));

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}

class CreateChallengeDialog extends StatefulWidget {
  const CreateChallengeDialog({Key? key}) : super(key: key);

  @override
  State<CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<CreateChallengeDialog> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'EXPENSE_LIMIT'; // EXPENSE_LIMIT or SAVING_GOAL
  String _selectedDuration = 'WEEKLY'; // WEEKLY or MONTHLY
  CategoryModel? _selectedCategory;
  String? _amountError; // 금액 에러 메시지

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 다크모드에 따른 primary 색상 반환
  Color _getPrimaryColor(ThemeController themeController) {
    return themeController.isDarkMode ? AppColors.darkPrimary : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final expenseController = Get.find<ExpenseController>();
    final primaryColor = _getPrimaryColor(themeController);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 고정 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '챌린지 만들기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

              // 챌린지 타입 선택
              Text(
                '챌린지 타입',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      themeController,
                      '지출 제한',
                      '목표 금액 이하로',
                      '🎯',
                      'EXPENSE_LIMIT',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(
                      themeController,
                      '저축 목표',
                      '목표 금액 달성',
                      '💰',
                      'SAVING_GOAL',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 챌린지 제목
              Text(
                '챌린지 이름',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '예: 커피 다이어트',
                  filled: true,
                  fillColor: themeController.isDarkMode
                      ? AppColors.darkBackground
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 카테고리 선택 (필수)
              Text(
                '카테고리 *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final categories = expenseController.variableCategories
                    .where((c) => c.type == 'EXPENSE')
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리 추가 버튼
                    GestureDetector(
                      onTap: () => _showAddCategoryDialog(expenseController, themeController),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+ 지출 카테고리 추가',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 카테고리 버튼 그리드 (스크롤 가능)
                    if (categories.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '카테고리를 추가해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeController.isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categories.map((category) {
                              final isSelected = _selectedCategory?.id == category.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.1)
                                        : (themeController.isDarkMode
                                            ? AppColors.darkBackground
                                            : Colors.grey.shade50),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : (themeController.isDarkMode
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : (themeController.isDarkMode
                                              ? AppColors.darkTextPrimary
                                              : AppColors.textPrimary),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // 목표 금액
              Text(
                '목표 금액',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _amountError = null;
                    } else {
                      final numericValue = value.replaceAll(',', '');
                      final amount = int.tryParse(numericValue);
                      if (amount != null && amount < 1000) {
                        _amountError = '최소 1,000원 이상 입력해주세요';
                      } else {
                        _amountError = null;
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                  hintText: '금액을 입력하세요',
                  hintStyle: TextStyle(
                    color: themeController.isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  suffixText: '원',
                  errorText: _amountError,
                  filled: true,
                  fillColor: themeController.isDarkMode
                      ? AppColors.darkBackground
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _amountError != null ? Colors.red : primaryColor,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 기간 선택
              Text(
                '기간',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDurationButton(
                      themeController,
                      '일주일',
                      '7일',
                      'WEEKLY',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDurationButton(
                      themeController,
                      '한 달',
                      '30일',
                      'MONTHLY',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 확인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '챌린지 시작! 🚀',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
),
);
  }

  Widget _buildTypeButton(
    ThemeController themeController,
    String title,
    String subtitle,
    String emoji,
    String type,
  ) {
    final isSelected = _selectedType == type;
    final primaryColor = _getPrimaryColor(themeController);
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : (themeController.isDarkMode
                  ? AppColors.darkBackground
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? primaryColor
                    : (themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: themeController.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton(
    ThemeController themeController,
    String title,
    String subtitle,
    String duration,
  ) {
    final isSelected = _selectedDuration == duration;
    final primaryColor = _getPrimaryColor(themeController);
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = duration),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : (themeController.isDarkMode
                  ? AppColors.darkBackground
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? primaryColor
                    : (themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: themeController.isDarkMode
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createChallenge() {
    // 유효성 검사
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('알림', '챌린지 이름을 입력해주세요');
      return;
    }

    if (_selectedCategory == null) {
      Get.snackbar('알림', '카테고리를 선택해주세요');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      Get.snackbar('알림', '목표 금액을 입력해주세요');
      return;
    }

    // 콤마 제거 후 숫자로 변환
    final amountText = _amountController.text.replaceAll(',', '');
    final targetAmount = double.parse(amountText);

    // 최소 금액 검증 (1,000원 이상)
    if (targetAmount < 1000) {
      Get.snackbar('알림', '목표 금액은 최소 1,000원 이상이어야 합니다');
      return;
    }

    final now = DateTime.now();
    final daysToAdd = _selectedDuration == 'WEEKLY' ? 7 : 30;

    final challenge = UserChallenge(
      userId: 1, // 기본 사용자 ID
      title: _titleController.text.trim(),
      type: _selectedType,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      categoryId: _selectedCategory?.id,
      startDate: now,
      endDate: now.add(Duration(days: daysToAdd)),
      status: 'IN_PROGRESS',
      progress: 0.0,
      createdAt: now,
      updatedAt: now,
    );

    final controller = Get.find<ChallengeController>();
    controller.createChallenge(challenge);
  }

  /// 카테고리 추가 다이얼로그 표시
  Future<void> _showAddCategoryDialog(
    ExpenseController expenseController,
    ThemeController themeController,
  ) async {
    await Get.dialog(
      _AddCategoryDialogContent(
        expenseController: expenseController,
        themeController: themeController,
        onCategoryAdded: (newCategory) {
          // 추가된 카테고리를 ID로 찾아서 설정 (객체 참조 대신 ID로 매칭)
          setState(() {
            final categories = expenseController.variableCategories
                .where((c) => c.type == 'EXPENSE')
                .toList();
            _selectedCategory = categories.firstWhere(
              (c) => c.id == newCategory.id,
              orElse: () => newCategory,
            );
          });
        },
      ),
    );
  }
}

/// 카테고리 추가 다이얼로그 내용 (별도 StatefulWidget)
class _AddCategoryDialogContent extends StatefulWidget {
  final ExpenseController expenseController;
  final ThemeController themeController;
  final Function(CategoryModel) onCategoryAdded;

  const _AddCategoryDialogContent({
    required this.expenseController,
    required this.themeController,
    required this.onCategoryAdded,
  });

  @override
  State<_AddCategoryDialogContent> createState() => _AddCategoryDialogContentState();
}

class _AddCategoryDialogContentState extends State<_AddCategoryDialogContent> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.themeController.isDarkMode
        ? AppColors.darkPrimary
        : AppColors.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: widget.themeController.isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.category,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '새 카테고리 추가',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.themeController.isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 카테고리 이름 입력
              Text(
                '카테고리 이름',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '예: 커피',
                  filled: true,
                  fillColor: widget.themeController.isDarkMode
                      ? AppColors.darkBackground
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 안내 문구
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '지출 카테고리로 추가됩니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.trim().isEmpty) {
                          Get.snackbar('알림', '카테고리 이름을 입력해주세요');
                          return;
                        }

                        // 카테고리 추가
                        final newCategory = await widget.expenseController.addCategory(
                          name: _nameController.text.trim(),
                        );

                        if (newCategory != null) {
                          Get.back(); // 다이얼로그 닫기

                          // 카테고리 목록이 업데이트될 때까지 잠시 대기
                          await Future.delayed(const Duration(milliseconds: 200));

                          // 콜백으로 새 카테고리 전달
                          widget.onCategoryAdded(newCategory);

                          Get.snackbar(
                            '성공',
                            '카테고리가 추가되었습니다',
                            backgroundColor: primaryColor,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '추가',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
