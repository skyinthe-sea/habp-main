// lib/features/dashboard/presentation/widgets/monthly_summary_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      if (controller.isLoading.value || controller.isAssetsLoading.value) {
        return Center(child: CircularProgressIndicator(
          color: themeController.primaryColor,
        ));
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
                child: GestureDetector(
                  onTap: () => _showCardDetails(context, 'income'),
                  child: _buildSummaryCard(
                    title: '소득',
                    amount: income,
                    percentChange: controller.incomeChangePercentage.value,
                    isPositiveTrend: controller.incomeChangePercentage.value > 0,
                    iconData: Icons.arrow_downward_rounded,
                    cardType: 'income',
                  ),
                ),
              ),
              const SizedBox(width: 8), // 좁아진 간격
              // Expense card
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCardDetails(context, 'expense'),
                  child: _buildSummaryCard(
                    title: '지출',
                    amount: expense,
                    percentChange: controller.expenseChangePercentage.value,
                    isPositiveTrend: controller.expenseChangePercentage.value <= 0, // 지출은 감소가 긍정적
                    iconData: Icons.arrow_upward_rounded,
                    cardType: 'expense',
                  ),
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
                child: GestureDetector(
                  onTap: () => _showCardDetails(context, 'assets'),
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
              ),
              const SizedBox(width: 8), // 좁아진 간격
              // Balance card
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCardDetails(context, 'balance'),
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
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMonthSelector() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
            icon: Icon(
              Icons.chevron_left, 
              color: themeController.textSecondaryColor,
            ),
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
                color: themeController.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                controller.getMonthYearString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeController.textPrimaryColor,
                ),
              ),
            ),
          ),

          // 다음 달로 이동 - 현재 달 이후는 비활성화
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: themeController.textSecondaryColor,
            ),
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    // 금액 형식화
    final formattedAmount = cardType == 'balance' && amount < 0
        ? '-₩${_formatAmount(amount.abs())}'
        : '₩${_formatAmount(amount)}';

    // 카드 타입에 따른 색상 설정
    Color textColor;
    Color iconBgColor;
    Color iconColor;

    if (themeController.isDarkMode) {
      switch (cardType) {
        case 'income':
          textColor = AppColors.darkSuccess;
          iconBgColor = AppColors.darkSuccess.withOpacity(0.2);
          iconColor = AppColors.darkSuccess;
          break;
        case 'expense':
          textColor = AppColors.darkError;
          iconBgColor = AppColors.darkError.withOpacity(0.2);
          iconColor = AppColors.darkError;
          break;
        case 'assets':
          textColor = AppColors.darkInfo;
          iconBgColor = AppColors.darkInfo.withOpacity(0.2);
          iconColor = AppColors.darkInfo;
          break;
        case 'balance':
          textColor = amount >= 0 ? AppColors.darkSuccess : AppColors.darkError;
          iconBgColor = Colors.grey.shade800;
          iconColor = Colors.grey.shade400;
          break;
        default:
          textColor = Colors.grey.shade400;
          iconBgColor = Colors.grey.shade800;
          iconColor = Colors.grey.shade400;
      }
    } else {
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
    }

    // 세로 방향 레이아웃으로 변경
    return Container(
      width: double.infinity,
      height: 80, // 고정된 높이로 모든 카드 통일
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
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
                style: TextStyle(
                  color: themeController.textSecondaryColor,
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
                      color: isPositiveTrend 
                          ? (themeController.isDarkMode ? AppColors.darkSuccess.withOpacity(0.2) : Colors.green.shade50)
                          : (themeController.isDarkMode ? AppColors.darkError.withOpacity(0.2) : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${percentChange > 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isPositiveTrend 
                            ? (themeController.isDarkMode ? AppColors.darkSuccess : Colors.green.shade700)
                            : (themeController.isDarkMode ? AppColors.darkError : Colors.red.shade700),
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

  // 카드 상세 정보 다이얼로그 표시
  void _showCardDetails(BuildContext context, String cardType) {
    Get.dialog(
      _CardDetailDialog(
        cardType: cardType,
        controller: controller,
      ),
      barrierDismissible: true,
    );
  }
}

// 카드 상세 정보 다이얼로그
class _CardDetailDialog extends StatelessWidget {
  final String cardType;
  final DashboardController controller;

  const _CardDetailDialog({
    required this.cardType,
    required this.controller,
  });
  
  ThemeController get themeController => Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            color: themeController.cardColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                _buildHeader(),
                
                // 내용
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color headerColor;
    String title;
    IconData icon;
    
    switch (cardType) {
      case 'income':
        headerColor = Colors.green[400]!;
        title = '소득 분석';
        icon = Icons.trending_up;
        break;
      case 'expense':
        headerColor = Colors.red[400]!;
        title = '지출 분석';
        icon = Icons.trending_down;
        break;
      case 'assets':
        headerColor = Colors.blue[400]!;
        title = '재테크 분석';
        icon = Icons.account_balance;
        break;
      case 'balance':
        headerColor = Colors.purple[400]!;
        title = '잔액 분석';
        icon = Icons.account_balance_wallet;
        break;
      default:
        headerColor = Colors.grey[400]!;
        title = '분석';
        icon = Icons.analytics;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [headerColor, headerColor.withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white30,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (cardType) {
      case 'income':
        return _buildIncomeContent();
      case 'expense':
        return _buildExpenseContent();
      case 'assets':
        return _buildAssetsContent();
      case 'balance':
        return _buildBalanceContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildIncomeContent() {
    return Obx(() {
      final selectedMonth = controller.selectedMonth.value;
      final monthlyIncome = controller.monthlyIncome.value;
      final incomeChange = controller.incomeChangePercentage.value;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(
            '이번 달 총 소득',
            '₩${_formatCurrency(monthlyIncome)}',
            incomeChange,
            Colors.green,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '💡 소득 인사이트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '평균 일일 소득',
            '₩${_formatCurrency(monthlyIncome / DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day)}',
            Icons.calendar_today,
            Colors.green[50]!,
            Colors.green[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '소득 안정성',
            incomeChange.abs() < 10 ? '안정적' : '변동 있음',
            Icons.security,
            Colors.blue[50]!,
            Colors.blue[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '권장 저축률',
            '${(monthlyIncome * 0.3 / monthlyIncome * 100).toStringAsFixed(0)}% (₩${_formatCurrency(monthlyIncome * 0.3)})',
            Icons.savings,
            Colors.orange[50]!,
            Colors.orange[600]!,
          ),
        ],
      );
    });
  }

  Widget _buildExpenseContent() {
    return Obx(() {
      final selectedMonth = controller.selectedMonth.value;
      final monthlyExpense = controller.monthlyExpense.value;
      final expenseChange = controller.expenseChangePercentage.value;
      final monthlyIncome = controller.monthlyIncome.value;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(
            '이번 달 총 지출',
            '₩${_formatCurrency(monthlyExpense)}',
            expenseChange,
            Colors.red,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '💡 지출 인사이트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '평균 일일 지출',
            '₩${_formatCurrency(monthlyExpense / DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day)}',
            Icons.calendar_today,
            Colors.red[50]!,
            Colors.red[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '소득 대비 지출률',
            '${monthlyIncome > 0 ? (monthlyExpense / monthlyIncome * 100).toStringAsFixed(1) : 0}%',
            Icons.pie_chart,
            Colors.purple[50]!,
            Colors.purple[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '절약 목표',
            expenseChange > 0 ? '지출 증가 주의!' : '절약 잘하고 있어요!',
            Icons.lightbulb,
            expenseChange > 0 ? Colors.orange[50]! : Colors.green[50]!,
            expenseChange > 0 ? Colors.orange[600]! : Colors.green[600]!,
          ),
        ],
      );
    });
  }

  Widget _buildAssetsContent() {
    return Obx(() {
      final monthlyAssets = controller.monthlyAssets.value;
      final monthlyIncome = controller.monthlyIncome.value;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(
            '이번 달 재테크',
            '₩${_formatCurrency(monthlyAssets)}',
            0.0, // 재테크는 변화율 표시 안함
            Colors.blue,
            showChange: false,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '💡 재테크 인사이트',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '투자 비율',
            '${monthlyIncome > 0 ? (monthlyAssets / monthlyIncome * 100).toStringAsFixed(1) : 0}%',
            Icons.trending_up,
            Colors.blue[50]!,
            Colors.blue[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '권장 투자율',
            '소득의 20-30% 권장',
            Icons.flag,
            Colors.green[50]!,
            Colors.green[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '투자 상태',
            monthlyAssets > monthlyIncome * 0.2 ? '목표 달성!' : '더 투자해보세요!',
            Icons.assessment,
            monthlyAssets > monthlyIncome * 0.2 ? Colors.green[50]! : Colors.orange[50]!,
            monthlyAssets > monthlyIncome * 0.2 ? Colors.green[600]! : Colors.orange[600]!,
          ),
        ],
      );
    });
  }

  Widget _buildBalanceContent() {
    return Obx(() {
      final monthlyIncome = controller.monthlyIncome.value;
      final monthlyExpense = controller.monthlyExpense.value;
      final monthlyAssets = controller.monthlyAssets.value;
      final balance = monthlyIncome - monthlyExpense - monthlyAssets;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummarySection(
            '이번 달 잔액',
            '₩${_formatCurrency(balance)}',
            0.0, // 잔액은 변화율 표시 안함
            balance >= 0 ? Colors.green : Colors.red,
            showChange: false,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            '💡 현금 흐름 분석',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: themeController.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '저축률',
            '${monthlyIncome > 0 ? (balance / monthlyIncome * 100).toStringAsFixed(1) : 0}%',
            Icons.savings,
            Colors.blue[50]!,
            Colors.blue[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '재정 상태',
            balance >= 0 ? '흑자 운영 중' : '적자 주의',
            Icons.account_balance_wallet,
            balance >= 0 ? Colors.green[50]! : Colors.red[50]!,
            balance >= 0 ? Colors.green[600]! : Colors.red[600]!,
          ),
          
          const SizedBox(height: 12),
          
          _buildInsightCard(
            '권장 사항',
            balance >= monthlyIncome * 0.2 
                ? '훌륭한 저축률!' 
                : balance >= 0 
                    ? '저축을 늘려보세요' 
                    : '지출 관리 필요',
            Icons.lightbulb,
            balance >= monthlyIncome * 0.2 
                ? Colors.green[50]! 
                : balance >= 0 
                    ? Colors.orange[50]! 
                    : Colors.red[50]!,
            balance >= monthlyIncome * 0.2 
                ? Colors.green[600]! 
                : balance >= 0 
                    ? Colors.orange[600]! 
                    : Colors.red[600]!,
          ),
        ],
      );
    });
  }

  Widget _buildSummarySection(
    String title,
    String amount,
    double change,
    MaterialColor color, {
    bool showChange = true,
  }) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: themeController.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color[700],
                ),
              ),
              if (showChange && change != 0.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: change > 0 ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: change > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
    Color textColor,
  ) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: textColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeController.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final absAmount = amount.abs();
    
    if (absAmount >= 100000000) {
      return '${(absAmount / 100000000).toStringAsFixed(1)}억';
    } else if (absAmount >= 10000) {
      return '${(absAmount / 10000).toStringAsFixed(1)}만';
    } else {
      return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
  }
}