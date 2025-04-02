import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/dashboard_controller.dart';

class MonthlySummaryCard extends StatelessWidget {
  final DashboardController controller;

  const MonthlySummaryCard({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value || controller.isAssetsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Get all values from controller
      final income = controller.monthlyIncome.value;
      final expense = controller.monthlyExpense.value;
      final assets = controller.monthlyAssets.value;

      // Calculate balance as income - expense - assets
      final balance = income - expense - assets;

      return Column(
        children: [
          // First row: Income and Assets
          Row(
            children: [
              // Income card
              Expanded(
                child: _buildSummaryCard(
                  title: '이번 달 수입',
                  amount: income,
                  comparison:
                      '지난달 대비 ${controller.getPercentageSign(controller.incomeChangePercentage.value)}${controller.incomeChangePercentage.value.toStringAsFixed(1)}%',
                  comparisonColor: controller.incomeChangePercentage.value > 0
                      ? Colors.green
                      : Colors.red,
                  iconData: controller.incomeChangePercentage.value > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  iconBackgroundColor:
                      controller.incomeChangePercentage.value > 0
                          ? const Color(0xFFE6F4EA)
                          : const Color(0xFFFEE8EC),
                  iconColor: controller.incomeChangePercentage.value > 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              // Assets card
              Expanded(
                child: _buildSummaryCard(
                  title: '이번 달 재테크',
                  amount: assets,
                  comparison: '',
                  // No comparison for assets yet
                  comparisonColor: Colors.blue,
                  iconData: Icons.account_balance_outlined,
                  iconBackgroundColor: const Color(0xFFE3F2FD),
                  iconColor: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Expenses and Balance
          Row(
            children: [
              // Expenses card
              Expanded(
                child: _buildSummaryCard(
                  title: '이번 달 지출',
                  amount: expense,
                  comparison:
                      '지난달 대비 ${controller.getPercentageSign(controller.expenseChangePercentage.value)}${controller.expenseChangePercentage.value.toStringAsFixed(1)}%',
                  comparisonColor: controller.expenseChangePercentage.value > 0
                      ? Colors.red
                      : Colors.green,
                  iconData: controller.expenseChangePercentage.value > 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  iconBackgroundColor:
                      controller.expenseChangePercentage.value > 0
                          ? const Color(0xFFFEE8EC)
                          : const Color(0xFFE6F4EA),
                  iconColor: controller.expenseChangePercentage.value > 0
                      ? Colors.red
                      : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              // Balance card
              Expanded(
                child: _buildSummaryCard(
                  title: '이번 달 잔액',
                  amount: balance,
                  comparison: '',
                  comparisonColor: Colors.grey,
                  iconData: Icons.account_balance_wallet_outlined,
                  iconBackgroundColor: const Color(0xFFF5F5F5),
                  iconColor: Colors.grey,
                ),
              ),
            ],
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
    // 금액 형식화
    final formattedAmount = '₩${_formatAmount(amount)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16), // Reduced padding for smaller cards
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
                    fontSize: 13, // Slightly smaller text
                  ),
                ),
                const SizedBox(height: 6), // Reduced spacing

                // 금액을 표시하는 부분을 스크롤 가능하게 변경
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    formattedAmount,
                    style: const TextStyle(
                      fontSize: 16, // 더 작은 폰트 크기로 변경
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 3), // Reduced spacing
                if (comparison.isNotEmpty)
                  Text(
                    comparison,
                    style: TextStyle(
                      color: comparisonColor,
                      fontSize: 11, // Smaller font
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 36, // Slightly smaller icon container
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 18, // Smaller icon
            ),
          ),
        ],
      ),
    );
  }

  // 금액 형식화 함수 - 큰 숫자일 경우 간소화
  String _formatAmount(double amount) {
    // 절대값 사용
    final absAmount = amount.abs();

    // 숫자가 너무 클 경우 단위로 표시
    if (absAmount >= 1000000000) {
      // 10억 이상
      return '${(absAmount / 1000000000).toStringAsFixed(1)}B';
    } else {
      // 일반적인 형식: 천 단위 구분자
      return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
  }
}
