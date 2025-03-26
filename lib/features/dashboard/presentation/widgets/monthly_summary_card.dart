import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/dashboard_controller.dart';

class MonthlySummaryCard extends StatelessWidget {
  final DashboardController controller;

  const MonthlySummaryCard({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // 지출 카드
          _buildSummaryCard(
            title: '이번 달 지출',
            amount: controller.monthlyExpense.value,
            comparison: '지난달 대비 ${controller.getPercentageSign(controller.expenseChangePercentage.value)}${controller.expenseChangePercentage.value.toStringAsFixed(1)}%',
            comparisonColor: controller.expenseChangePercentage.value > 0 ? Colors.red : Colors.green,
            iconData: controller.expenseChangePercentage.value > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            iconBackgroundColor: controller.expenseChangePercentage.value > 0 ? const Color(0xFFFEE8EC) : const Color(0xFFE6F4EA),
            iconColor: controller.expenseChangePercentage.value > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),

          // 수입 카드
          _buildSummaryCard(
            title: '이번 달 수입',
            amount: controller.monthlyIncome.value,
            comparison: '지난달 대비 ${controller.getPercentageSign(controller.incomeChangePercentage.value)}${controller.incomeChangePercentage.value.toStringAsFixed(1)}%',
            comparisonColor: controller.incomeChangePercentage.value > 0 ? Colors.green : Colors.red,
            iconData: controller.incomeChangePercentage.value > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            iconBackgroundColor: controller.incomeChangePercentage.value > 0 ? const Color(0xFFE6F4EA) : const Color(0xFFFEE8EC),
            iconColor: controller.incomeChangePercentage.value > 0 ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),

          // 잔액 카드 (목표 대비 퍼센트 제거)
          _buildSummaryCard(
            title: '이번 달 잔액',
            amount: controller.monthlyBalance.value,
            comparison: '', // 목표 대비 퍼센트 제거
            comparisonColor: const Color(0xFF4285F4),
            iconData: Icons.account_balance_wallet_outlined,
            iconBackgroundColor: const Color(0xFFE8F0FE),
            iconColor: const Color(0xFF4285F4),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String comparison,
    required Color comparisonColor,
    required IconData iconData,
    required Color iconBackgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₩${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (comparison.isNotEmpty)
                  Text(
                    comparison,
                    style: TextStyle(
                      color: comparisonColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}