import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/expense_controller.dart';

class OverallBudgetCard extends StatelessWidget {
  final ExpenseController controller;

  const OverallBudgetCard({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 통화 포맷팅
      final currencyFormat = NumberFormat('#,###', 'ko_KR');
      final totalBudget = '${currencyFormat.format(controller.totalBudget.value.toInt())}원';
      final totalSpent = '${currencyFormat.format(controller.totalSpent.value.abs().toInt())}원';
      final totalRemaining = '${currencyFormat.format(controller.totalRemaining.value.toInt())}원';

      // 진행 상태에 따른 색상 결정
      final double progressPercentage = controller.overallProgressPercentage.value.abs();
      final Color progressColor = progressPercentage >= 90
          ? Colors.red
          : (progressPercentage >= 70 ? Colors.orange : AppColors.primary);

      return Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 텍스트 제목 추가
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '이번 달 예산 현황',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        progressPercentage >= 90
                            ? Icons.error_outline
                            : (progressPercentage >= 70
                            ? Icons.warning_amber_outlined
                            : Icons.check_circle_outline),
                        size: 14,
                        color: progressColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: progressColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 예산 현황 정보 표시
            Row(
              children: [
                // 전체 구성 카드
                Expanded(
                  child: _buildInfoCard(
                    '총 예산',
                    totalBudget,
                    Icons.account_balance_wallet,
                    AppColors.black,
                  ),
                ),
                const SizedBox(width: 12),
                // 사용 구성 카드
                Expanded(
                  child: _buildInfoCard(
                    '사용 금액',
                    totalSpent,
                    Icons.shopping_cart,
                    progressColor,
                  ),
                ),
                const SizedBox(width: 12),
                // 남은 예산 구성 카드
                Expanded(
                  child: _buildInfoCard(
                    '남은 예산',
                    totalRemaining,
                    Icons.savings,
                    Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (progressPercentage / 100).toDouble(),
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    });
  }

  // 정보 카드 위젯
  Widget _buildInfoCard(String title, String value, IconData icon, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}