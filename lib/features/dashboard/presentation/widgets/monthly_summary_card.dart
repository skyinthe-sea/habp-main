// lib/features/dashboard/presentation/widgets/monthly_summary_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../presentation/dashboard_controller.dart';

class MonthlySummaryCard extends StatelessWidget {
  final DashboardController controller;
  final bool excludeMonthSelector;

  const MonthlySummaryCard({
    Key? key,
    required this.controller,
    this.excludeMonthSelector = false,
  }) : super(key: key);

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
          // 월 선택 컨트롤은 옵션에 따라 표시
          if (!excludeMonthSelector) ...[
            _buildMonthSelector(),
            const SizedBox(height: 10),
          ],

          // First row: Income and Expense
          Row(
            children: [
              // Income card
              Expanded(
                child: _buildSummaryCard(
                  title: '소득',
                  amount: income,
                  percentChange: controller.incomeChangePercentage.value,
                  isPositiveTrend: controller.incomeChangePercentage.value > 0,
                  iconData: Icons.arrow_downward_rounded,
                  cardType: 'income',
                ),
              ),
              const SizedBox(width: 8), // 좁아진 간격
              // Expense card
              Expanded(
                child: _buildSummaryCard(
                  title: '지출',
                  amount: expense,
                  percentChange: controller.expenseChangePercentage.value,
                  isPositiveTrend: controller.expenseChangePercentage.value <= 0, // 지출은 감소가 긍정적
                  iconData: Icons.arrow_upward_rounded,
                  cardType: 'expense',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // 좁아진 간격
          // Second row: Finance and Balance
          Row(
            children: [
              // Finance card
              Expanded(
                child: _buildSummaryCard(
                  title: '재테크',
                  amount: assets,
                  percentChange: 0.0, // No comparison data
                  isPositiveTrend: true,
                  iconData: Icons.account_balance_outlined,
                  cardType: 'assets',
                  hasPercentage: false, // 퍼센티지 표시 안 함
                ),
              ),
              const SizedBox(width: 8), // 좁아진 간격
              // Balance card
              Expanded(
                child: _buildSummaryCard(
                  title: '잔액',
                  amount: balance,
                  percentChange: 0.0, // No comparison data
                  isPositiveTrend: balance >= 0, // 잔액이 양수면 긍정적
                  iconData: Icons.account_balance_wallet_outlined,
                  cardType: 'balance',
                  hasPercentage: false, // 퍼센티지 표시 안 함
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이전 달로 이동
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.grey),
            onPressed: controller.goToPreviousMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          // 현재 선택된 월 표시 - 클릭하면 현재 달로 이동
          GestureDetector(
            onTap: controller.goToCurrentMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.getMonthYearString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 다음 달로 이동 - 현재 달 이후는 비활성화
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: Colors.grey),
            onPressed: controller.selectedMonth.value.year == DateTime.now().year &&
                controller.selectedMonth.value.month == DateTime.now().month ?
            null : controller.goToNextMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required double percentChange,
    required bool isPositiveTrend,
    required IconData iconData,
    required String cardType, // 'income', 'expense', 'assets', 'balance'
    bool hasPercentage = true,
  }) {
    // 금액 형식화
    final formattedAmount = '₩${_formatAmount(amount)}';

    // 카드 타입에 따른 색상 설정
    Color textColor;
    Color iconBgColor;
    Color iconColor;

    switch (cardType) {
      case 'income':
        textColor = Colors.green.shade700;
        iconBgColor = const Color(0xFFE6F4EA);
        iconColor = Colors.green.shade600;
        break;
      case 'expense':
        textColor = Colors.red.shade700;
        iconBgColor = const Color(0xFFFEE8EC);
        iconColor = Colors.red.shade600;
        break;
      case 'assets':
        textColor = Colors.blue.shade700;
        iconBgColor = const Color(0xFFE3F2FD);
        iconColor = Colors.blue;
        break;
      case 'balance':
        textColor = amount >= 0 ? Colors.green.shade700 : Colors.red.shade700;
        iconBgColor = const Color(0xFFF5F5F5);
        iconColor = Colors.grey;
        break;
      default:
        textColor = Colors.grey.shade800;
        iconBgColor = Colors.grey.shade100;
        iconColor = Colors.grey;
    }

    // 세로 방향 레이아웃으로 변경
    return Container(
      width: double.infinity,
      height: 80, // 고정된 높이로 모든 카드 통일
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 제목과 아이콘을 한 줄에
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              Container(
                width: 24, // 더 작은 아이콘
                height: 24,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 14,
                ),
              ),
            ],
          ),

          // 금액
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  formattedAmount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (hasPercentage && percentChange != 0.0)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isPositiveTrend ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPositiveTrend ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
              ],
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
    } else if (absAmount >= 100000000) {
      // 1억 이상
      return '${(absAmount / 100000000).toStringAsFixed(1)}억';
    } else if (absAmount >= 10000) {
      // 만 이상
      return '${(absAmount / 10000).toStringAsFixed(1)}만';
    } else {
      // 일반적인 형식: 천 단위 구분자
      return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
  }
}