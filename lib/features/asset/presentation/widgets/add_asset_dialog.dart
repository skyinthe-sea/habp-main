// lib/features/asset/presentation/widgets/add_asset_dialog.dart 수정

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
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

  DateTime? purchaseDate;
  bool isLoading = false;
  bool _isSaveButtonEnabled = false;

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
    super.dispose();
  }

  void _updateSaveButtonState() {
    setState(() {
      _isSaveButtonEnabled = selectedCategoryId != null &&
          nameController.text.isNotEmpty &&
          currentValueController.text.isNotEmpty &&
          !isLoading;
      debugPrint('버튼 활성화 상태: $_isSaveButtonEnabled');
      debugPrint('카테고리: $selectedCategoryId, 이름: ${nameController.text}, 값: ${currentValueController.text}');
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
    if (selectedCategoryId == null || nameController.text.isEmpty || currentValueController.text.isEmpty) {
      Get.snackbar(
        '알림',
        '카테고리, 이름, 현재 가치는 필수 입력사항입니다.',
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
        Get.snackbar(
          '성공',
          '자산이 추가되었습니다.',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          '오류',
          '자산 추가에 실패했습니다.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('자산 추가 중 오류: $e');
      Get.snackbar(
        '오류',
        '입력한 값을 확인해주세요: $e',
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
                    '새 자산 추가하기',
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
                    Obx(() {
                      final categories = widget.controller.assetCategories;

                      if (categories.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '카테고리를 불러오는 중입니다...',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            final isSelected = selectedCategoryId == category.id;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategoryId = category.id;
                                  _updateSaveButtonState();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
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
                      onPressed: _isSaveButtonEnabled ? _saveAsset : null,
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