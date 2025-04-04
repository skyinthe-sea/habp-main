// lib/features/settings/presentation/widgets/fixed_income_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../controllers/settings_controller.dart';

class FixedIncomeDialog extends StatefulWidget {
  const FixedIncomeDialog({Key? key}) : super(key: key);

  @override
  State<FixedIncomeDialog> createState() => _FixedIncomeDialogState();
}

class _FixedIncomeDialogState extends State<FixedIncomeDialog> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isLoadingIncome.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '고정 소득 설정',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(),

              // 설명 텍스트
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '매월 반복되는 고정 소득을 설정합니다. 금액 변경 시 적용 시작 월을 선택할 수 있습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              // 고정 소득 목록
              if (_controller.incomeCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('고정 소득 카테고리가 없습니다.'),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _controller.incomeCategories.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = _controller.incomeCategories[index];
                      final latestSetting = category.settings.isNotEmpty
                          ? category.settings.first
                          : null;

                      return ListTile(
                        title: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: latestSetting != null
                            ? Text(
                          '현재 금액: ${_formatCurrency(latestSetting.amount)}원\n'
                              '마지막 수정: ${_formatDate(latestSetting.effectiveFrom)}부터 적용',
                          style: const TextStyle(fontSize: 12),
                        )
                            : const Text('설정된 금액 없음'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => _showUpdateDialog(category),
                          child: const Text('수정'),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      );
                    },
                  ),
                ),

              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      '닫기',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showUpdateDialog(CategoryWithSettings category) {
    final TextEditingController amountController = TextEditingController();

    // 기존 금액이 있으면 입력 필드에 설정
    if (category.settings.isNotEmpty) {
      amountController.text = category.settings.first.amount.toStringAsFixed(0);
    }

    // 적용 시작 월 선택 (기본값은 현재 월)
    final now = DateTime.now();
    DateTime selectedMonth = DateTime(now.year, now.month, 1);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${category.name} 금액 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 금액 입력 필드
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: '금액',
                      border: OutlineInputBorder(),
                      prefixText: '₩ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // 적용 시작 월 선택
                  Row(
                    children: [
                      const Text('적용 시작 월:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedMonth,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              initialDatePickerMode: DatePickerMode.year,
                              selectableDayPredicate: (DateTime date) {
                                // 월의 첫 날만 선택 가능하도록
                                return date.day == 1;
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedMonth = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              DateFormat('yyyy년 M월').format(selectedMonth),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // 입력값 검증
                    if (amountController.text.isEmpty) {
                      Get.snackbar('오류', '금액을 입력해주세요');
                      return;
                    }

                    final amount = double.tryParse(amountController.text);
                    if (amount == null) {
                      Get.snackbar('오류', '올바른 금액을 입력해주세요');
                      return;
                    }

                    // 설정 업데이트
                    final success = await _controller.updateFixedTransactionSetting(
                      categoryId: category.id,
                      amount: amount,
                      effectiveFrom: selectedMonth,
                    );

                    // 대화상자 닫기
                    Navigator.pop(context);

                    // 결과 표시
                    if (success) {
                      Get.snackbar(
                        '성공',
                        '${category.name}의 금액이 ${DateFormat('yyyy년 M월').format(selectedMonth)}부터 ${_formatCurrency(amount)}원으로 수정되었습니다.',
                        backgroundColor: Colors.green[100],
                      );
                    } else {
                      Get.snackbar(
                        '오류',
                        '설정 업데이트에 실패했습니다.',
                        backgroundColor: Colors.red[100],
                      );
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월').format(date);
  }
}

// 확장 함수로 다이얼로그 표시 쉽게 만들기
extension FixedIncomeDialogExtension on GetInterface {
  Future<void> showFixedIncomeDialog() {
    return Get.dialog(
      const FixedIncomeDialog(),
      barrierDismissible: true,
    );
  }
}