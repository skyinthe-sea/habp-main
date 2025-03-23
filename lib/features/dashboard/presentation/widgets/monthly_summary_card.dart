import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habp/features/dashboard/presentation/presentation/dashboard_controller.dart';

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
            comparison: '지난달 대비 +8.2%',
            comparisonColor: Colors.red,
            iconData: Icons.arrow_upward_rounded,
            iconBackgroundColor: const Color(0xFFFEE8EC),
            iconColor: Colors.red,
          ),
          const SizedBox(height: 16),

          // 수입 카드
          _buildSummaryCard(
            title: '이번 달 수입',
            amount: controller.monthlyIncome.value,
            comparison: '지난달 대비 +3.5%',
            comparisonColor: Colors.green,
            iconData: Icons.arrow_downward_rounded,
            iconBackgroundColor: const Color(0xFFE6F4EA),
            iconColor: Colors.green,
          ),
          const SizedBox(height: 16),

          // 잔액 카드
          _buildSummaryCard(
            title: '이번 달 잔액',
            amount: controller.monthlyBalance.value,
            comparison: '목표 대비 +12.0%',
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
                  '₩${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
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