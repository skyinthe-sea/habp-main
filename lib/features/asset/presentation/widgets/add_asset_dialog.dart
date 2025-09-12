import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../controllers/asset_controller.dart';

class AddAssetDialog extends StatefulWidget {
  final AssetController controller;

  const AddAssetDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  int? selectedCategoryId;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController currentValueController = TextEditingController();
  final TextEditingController purchaseValueController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();
  final TextEditingController loanAmountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController newCategoryController = TextEditingController();

  DateTime? purchaseDate;
  bool isLoading = false;
  bool _isSaveButtonEnabled = false;
  bool _showAdvancedOptions = false;
  final dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    // 값 변경 시마다 버튼 상태 업데이트를 위한 리스너 추가
    nameController.addListener(_updateSaveButtonState);
    currentValueController.addListener(_updateSaveButtonState);
  }

  @override
  void dispose() {
    nameController.removeListener(_updateSaveButtonState);
    currentValueController.removeListener(_updateSaveButtonState);
    nameController.dispose();
    currentValueController.dispose();
    purchaseValueController.dispose();
    interestRateController.dispose();
    loanAmountController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    newCategoryController.dispose();
    super.dispose();
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled = selectedCategoryId != null &&
          nameController.text.isNotEmpty &&
          currentValueController.text.isNotEmpty &&
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

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        purchaseDate = picked;
      });
    }
  }

  void _addNewCategory() async {
    if (newCategoryController.text.isEmpty) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '알림',
            '카테고리 이름을 입력해주세요.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkInfo : AppColors.info,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final now = DateTime.now().toIso8601String();
      final db = await dbHelper.database;

      // 카테고리 추가
      final categoryId = await db.insert('category', {
        'name': newCategoryController.text.trim(),
        'type': 'ASSET',
        'is_fixed': 0,  // 사용자 추가 카테고리는 is_fixed = 0
        'is_deleted': 0,
        'created_at': now,
        'updated_at': now,
      });

      if (categoryId > 0) {
        // 카테고리 목록 새로고침
        await widget.controller.fetchAssetCategories();

        // 새로 추가된 카테고리 선택
        setState(() {
          selectedCategoryId = categoryId;
          newCategoryController.clear();
        });

        Get.back(); // 다이얼로그 닫기

        final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '성공',
            '새 자산 유형이 추가되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '자산 유형 추가 중 오류가 발생했습니다: $e',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '새 자산 유형 추가',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: newCategoryController,
          decoration: InputDecoration(
            labelText: '자산 유형 이름',
            hintText: '예: 컬렉션, NFT, 예술품',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.category, color: AppColors.primary),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: _addNewCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: isLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                )
            )
                : const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _saveAsset() async {
    if (selectedCategoryId == null || nameController.text.isEmpty || currentValueController.text.isEmpty) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '알림',
            '카테고리, 이름, 현재 가치는 필수 입력사항입니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkInfo : AppColors.info,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 금액 값 파싱
      final currentValue = double.parse(currentValueController.text.replaceAll(',', ''));
      final purchaseValue = purchaseValueController.text.isNotEmpty
          ? double.parse(purchaseValueController.text.replaceAll(',', ''))
          : null;
      final interestRate = interestRateController.text.isNotEmpty
          ? double.parse(interestRateController.text)
          : null;
      final loanAmount = loanAmountController.text.isNotEmpty
          ? double.parse(loanAmountController.text.replaceAll(',', ''))
          : null;

      final success = await widget.controller.addAsset(
        categoryId: selectedCategoryId!,
        name: nameController.text,
        currentValue: currentValue,
        purchaseValue: purchaseValue,
        purchaseDate: purchaseDate?.toIso8601String(),
        interestRate: interestRate,
        loanAmount: loanAmount,
        description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
        location: locationController.text.isNotEmpty ? locationController.text : null,
      );

      if (success) {
        Navigator.of(context).pop();
        final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '성공',
            '자산이 추가되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '자산 추가에 실패했습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('자산 추가 중 오류: $e');
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '입력한 값을 확인해주세요: $e',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCategorySelector(),
                    const SizedBox(height: 12),
                    _buildBasicInfoFields(),
                    const SizedBox(height: 16),
                    _buildAdvancedOptionsToggle(),
                    if (_showAdvancedOptions) _buildAdvancedOptions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '새 자산 추가',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        Divider(color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '자산 유형',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: Icon(Icons.add, size: 16, color: AppColors.primary),
              label: Text(
                '새 유형 추가',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Obx(() {
            final categories = widget.controller.assetCategories;

            if (categories.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = selectedCategoryId == category.id;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategoryId = category.id;
                        _updateSaveButtonState();
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                            : null,
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBasicInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: nameController,
          labelText: '자산 이름',
          hintText: '예: 삼성전자 주식, 강남 아파트, 마이카',
          prefixIcon: Icons.edit,
          isRequired: true,
        ),
        const SizedBox(height: 12),
        _buildCurrencyField(
          controller: currentValueController,
          labelText: '현재 가치 (원)',
          hintText: '자산의 현재 가치',
          prefixIcon: Icons.attach_money,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsToggle() {
    return InkWell(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showAdvancedOptions ? '기본 정보만 보기' : '상세 정보 입력하기',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _showAdvancedOptions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 8),
        _buildCurrencyField(
          controller: purchaseValueController,
          labelText: '구매 가치 (원)',
          hintText: '자산 구매 당시 가치',
          prefixIcon: Icons.shopping_cart,
        ),
        const SizedBox(height: 12),
        _buildDatePicker(),
        const SizedBox(height: 12),
        _buildInputField(
          controller: locationController,
          labelText: '위치',
          hintText: '자산의 위치 (주소 등)',
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: interestRateController,
          labelText: '이자율 (%)',
          hintText: '연 이자율 (예: 3.5)',
          prefixIcon: Icons.percent,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
        ),
        const SizedBox(height: 12),
        _buildCurrencyField(
          controller: loanAmountController,
          labelText: '대출 잔액 (원)',
          hintText: '현재 남은 대출 금액',
          prefixIcon: Icons.account_balance,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: descriptionController,
          labelText: '설명',
          hintText: '자산에 대한 추가 설명',
          prefixIcon: Icons.description,
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool isRequired = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14),
      onChanged: (value) {
        if (value.isNotEmpty) {
          final formatted = _formatCurrency(value);
          if (formatted != value) {
            controller.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(
                offset: formatted.length,
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                purchaseDate != null
                    ? DateFormat('yyyy년 MM월 dd일').format(purchaseDate!)
                    : '구매 날짜 선택',
                style: TextStyle(
                  fontSize: 14,
                  color: purchaseDate != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: const Text(
                '취소',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaveButtonEnabled ? _saveAsset : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
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
                '저장',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}