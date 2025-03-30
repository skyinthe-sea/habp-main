import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/expense_controller.dart';
import '../widgets/category_detail_dialog.dart';

class CategoryBudgetList extends StatelessWidget {
  final ExpenseController controller;

  const CategoryBudgetList({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExpenseController>(
        init: controller,
        builder: (controller) {
          return Obx(() {
            debugPrint(
                'CategoryBudgetList 빌드됨 - 로딩: ${controller.isLoading.value}, 항목: ${controller.budgetStatusList.length}개');

            // Add this safety check for the controller state
            if (!controller.dataInitialized.value) {
              controller.fetchBudgetStatus();
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Empty state handling
            if (controller.budgetStatusList.isEmpty) {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Return a widget with a defined size for empty state
              return Container(
                height: 200,
                // Explicit height prevents layout issues
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '등록된 예산 정보가 없습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '예산을 설정하여 관리해보세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.budgetStatusList.length,
              itemBuilder: (context, index) {
                final budgetStatus = controller.budgetStatusList[index];

                // 통화 포맷팅
                final budget =
                    '${budgetStatus.budgetAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
                final spent =
                    '${budgetStatus.spentAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';
                final remaining =
                    '${budgetStatus.remainingAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원';

                // 진행 상태에 따른 색상 결정
                final progressPercentage =
                budgetStatus.progressPercentage.abs();
                final Color progressColor = progressPercentage >= 90
                    ? Colors.red
                    : (progressPercentage >= 70
                    ? Colors.orange
                    : AppColors.primary);

                return InkWell(
                  onTap: () {
                    // 카테고리 상세 분석 다이얼로그 표시
                    showDialog(
                      context: context,
                      builder: (context) => CategoryDetailDialog(
                        budgetStatus: budgetStatus,
                        controller: controller,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  budgetStatus.categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '${progressPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: progressColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressPercentage / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '예산',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  budget,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  '사용',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  spent,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: progressColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              '남은 예산: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              remaining,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          });
        });
  }
}