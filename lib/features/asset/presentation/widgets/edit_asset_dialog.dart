// lib/features/asset/presentation/widgets/edit_asset_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/models/asset_category_model.dart';
import '../../domain/entities/asset.dart';

class EditAssetDialog extends StatefulWidget {
  final Asset asset;
  final List<AssetCategoryModel> categories;
  final Function({
  required int assetId,
  int? categoryId,
  String? name,
  double? currentValue,
  double? purchaseValue,
  String? purchaseDate,
  double? interestRate,
  double? loanAmount,
  String? description,
  String? location,
  String? details,
  String? iconType,
  }) onUpdate;

  const EditAssetDialog({
    Key? key,
    required this.asset,
    required this.categories,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditAssetDialog> createState() => _EditAssetDialogState();
}

class _EditAssetDialogState extends State<EditAssetDialog> {
  late int selectedCategoryId;
  late final TextEditingController nameController;
  late final TextEditingController currentValueController;
  late final TextEditingController purchaseValueController;
  late final TextEditingController interestRateController;
  late final TextEditingController loanAmountController;
  late final TextEditingController descriptionController;
  late final TextEditingController locationController;

  DateTime? purchaseDate;
  bool isLoading = false;
  bool _isSaveButtonEnabled = true;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.asset.categoryId;

    // 컨트롤러 초기화 및 기존 값 설정
    nameController = TextEditingController(text: widget.asset.name);
    currentValueController = TextEditingController(text: _formatCurrency(widget.asset.currentValue.toInt().toString()));
    purchaseValueController = widget.asset.purchaseValue != null
        ? TextEditingController(text: _formatCurrency(widget.asset.purchaseValue!.toInt().toString()))
        : TextEditingController();
    interestRateController = widget.asset.interestRate != null
        ? TextEditingController(text: widget.asset.interestRate!.toString())
        : TextEditingController();
    loanAmountController = widget.asset.loanAmount != null
        ? TextEditingController(text: _formatCurrency(widget.asset.loanAmount!.toInt().toString()))
        : TextEditingController();
    descriptionController = TextEditingController(text: widget.asset.description ?? '');
    locationController = TextEditingController(text: widget.asset.location ?? '');

    // 구매 날짜 설정
    if (widget.asset.purchaseDate != null) {
      purchaseDate = DateTime.parse(widget.asset.purchaseDate!);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    currentValueController.dispose();
    purchaseValueController.dispose();
    interestRateController.dispose();
    loanAmountController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled = nameController.text.isNotEmpty &&
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

  void _saveAsset() async {
    if (nameController.text.isEmpty || currentValueController.text.isEmpty) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '알림',
            '이름과 현재 가치는 필수 입력사항입니다.',
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

      final success = await widget.onUpdate(
        assetId: widget.asset.id,
        categoryId: selectedCategoryId,
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
            '자산 정보가 업데이트되었습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '자산 업데이트에 실패했습니다.',
            backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '입력한 값을 확인해주세요.',
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
                    '자산 정보 수정',
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
                      padding: const EdgeInsets.only(left: 16, top: 12),
                      child: Text(
                        '자산 유형',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.categories.map((category) {
                          final isSelected = selectedCategoryId == category.id;
                          return ChoiceChip(
                            label: Text(category.name),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  selectedCategoryId = category.id;
                                  _updateSaveButtonState();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 이름 입력
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '자산 이름',
                  hintText: '예: 삼성전자 주식, 강남 아파트, 마이카',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  _updateSaveButtonState();
                },
              ),
              const SizedBox(height: 16),

              // 현재 가치 입력
              TextField(
                controller: currentValueController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '현재 가치 (원)',
                  hintText: '자산의 현재 가치를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final formatted = _formatCurrency(value);
                    if (formatted != value) {
                      currentValueController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                  _updateSaveButtonState();
                },
              ),
              const SizedBox(height: 16),

              // 선택적 정보 섹션 헤더
              const Text(
                '추가 정보 (선택사항)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 구매 가치 입력
              TextField(
                controller: purchaseValueController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '구매 가치 (원)',
                  hintText: '자산 구매 당시 가치',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final formatted = _formatCurrency(value);
                    if (formatted != value) {
                      purchaseValueController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // 구매 날짜 선택
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: '구매 날짜',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        purchaseDate != null
                            ? DateFormat('yyyy년 MM월 dd일').format(purchaseDate!)
                            : '날짜 선택',
                        style: TextStyle(
                          color: purchaseDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 위치 입력 (부동산 등에 적합)
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: '위치',
                  hintText: '자산의 위치 (주소 등)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 이자율 입력 (예금, 적금 등에 적합)
              TextField(
                controller: interestRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: '이자율 (%)',
                  hintText: '연 이자율 (예: 3.5)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 대출 금액 입력
              TextField(
                controller: loanAmountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: '대출 잔액 (원)',
                  hintText: '현재 남은 대출 금액',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final formatted = _formatCurrency(value);
                    if (formatted != value) {
                      loanAmountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),

              // 설명 입력
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: '설명',
                  hintText: '자산에 대한 추가 설명',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: !_isSaveButtonEnabled ? null : _saveAsset,
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