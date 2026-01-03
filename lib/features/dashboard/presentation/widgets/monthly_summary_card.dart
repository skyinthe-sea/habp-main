// lib/features/dashboard/presentation/widgets/monthly_summary_card.dart
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/dialogs/trendy_card_detail_dialog.dart';
import '../presentation/dashboard_controller.dart';

class MonthlySummaryCard extends StatefulWidget {
  final DashboardController controller;
  final bool excludeMonthSelector;

  const MonthlySummaryCard({
    Key? key,
    required this.controller,
    this.excludeMonthSelector = false,
  }) : super(key: key);

  @override
  State<MonthlySummaryCard> createState() => _MonthlySummaryCardState();
}

class _MonthlySummaryCardState extends State<MonthlySummaryCard> with TickerProviderStateMixin {
  // Animation controllers for each card type
  late AnimationController _incomeAnimController;
  late AnimationController _expenseAnimController;
  late AnimationController _assetsAnimController;

  // Scale animations for pulse effect
  late Animation<double> _incomeScaleAnim;
  late Animation<double> _expenseScaleAnim;
  late Animation<double> _assetsScaleAnim;

  // Previous values for number counting animation
  double _prevIncome = 0;
  double _prevExpense = 0;
  double _prevAssets = 0;

  // Animated values for counting
  late Animation<double> _incomeCountAnim;
  late Animation<double> _expenseCountAnim;
  late Animation<double> _assetsCountAnim;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _incomeAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _expenseAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _assetsAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animations with bounce effect
    _incomeScaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _incomeAnimController, curve: Curves.elasticOut),
    );
    _expenseScaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _expenseAnimController, curve: Curves.elasticOut),
    );
    _assetsScaleAnim = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _assetsAnimController, curve: Curves.elasticOut),
    );

    // Initialize counting animations
    _incomeCountAnim = Tween<double>(begin: 0, end: 0).animate(_incomeAnimController);
    _expenseCountAnim = Tween<double>(begin: 0, end: 0).animate(_expenseAnimController);
    _assetsCountAnim = Tween<double>(begin: 0, end: 0).animate(_assetsAnimController);

    // Set initial values
    _prevIncome = widget.controller.monthlyIncome.value;
    _prevExpense = widget.controller.monthlyExpense.value;
    _prevAssets = widget.controller.monthlyAssets.value;
  }

  @override
  void dispose() {
    _incomeAnimController.dispose();
    _expenseAnimController.dispose();
    _assetsAnimController.dispose();
    super.dispose();
  }

  void _animateCard(String type, double oldValue, double newValue) {
    AnimationController controller;

    switch (type) {
      case 'income':
        controller = _incomeAnimController;
        // 1.0 → 1.5 → 1.0으로 돌아오는 애니메이션 (커질때 느리게, 작아질때 빠르게)
        _incomeScaleAnim = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.5)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,  // 커질때 더 많은 시간
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.5, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInCubic)),  // 더 빠른 곡선
            weight: 20,  // 작아질때 훨씬 더 적은 시간
          ),
        ]).animate(controller);
        _incomeCountAnim = Tween<double>(begin: oldValue, end: newValue).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        );
        break;
      case 'expense':
        controller = _expenseAnimController;
        _expenseScaleAnim = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.5)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.5, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInCubic)),
            weight: 20,
          ),
        ]).animate(controller);
        _expenseCountAnim = Tween<double>(begin: oldValue, end: newValue).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        );
        break;
      case 'assets':
        controller = _assetsAnimController;
        _assetsScaleAnim = TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.5)
                .chain(CurveTween(curve: Curves.easeOut)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.5, end: 1.0)
                .chain(CurveTween(curve: Curves.easeInCubic)),
            weight: 20,
          ),
        ]).animate(controller);
        _assetsCountAnim = Tween<double>(begin: oldValue, end: newValue).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOut),
        );
        break;
      default:
        return;
    }

    // 다이얼로그 닫히는 시간 고려해서 300ms 지연 후 애니메이션 시작
    controller.reset();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      if (widget.controller.isLoading.value || widget.controller.isAssetsLoading.value) {
        return Center(child: CircularProgressIndicator(
          color: themeController.primaryColor,
        ));
      }

      // Get all values from controller
      final income = widget.controller.monthlyIncome.value;
      final expense = widget.controller.monthlyExpense.value;
      final assets = widget.controller.monthlyAssets.value;

      // Detect changes and trigger animations
      if (income != _prevIncome) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCard('income', _prevIncome, income);
          _prevIncome = income;
        });
      }
      if (expense != _prevExpense) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCard('expense', _prevExpense, expense);
          _prevExpense = expense;
        });
      }
      if (assets != _prevAssets) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCard('assets', _prevAssets, assets);
          _prevAssets = assets;
        });
      }

      // Calculate balance as income - expense - assets
      final balance = income - expense - assets;

      return Column(
        children: [
          // 월 선택 컨트롤은 옵션에 따라 표시
          if (!widget.excludeMonthSelector) ...[
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
                    percentChange: widget.controller.incomeChangePercentage.value,
                    isPositiveTrend: widget.controller.incomeChangePercentage.value > 0,
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
                    percentChange: widget.controller.expenseChangePercentage.value,
                    isPositiveTrend: widget.controller.expenseChangePercentage.value <= 0, // 지출은 감소가 긍정적
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
            onPressed: widget.controller.goToPreviousMonth,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),

          // 현재 선택된 월 표시 - 클릭하면 현재 달로 이동
          GestureDetector(
            onTap: widget.controller.goToCurrentMonth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: themeController.isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.controller.getMonthYearString(),
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
            onPressed: widget.controller.selectedMonth.value.year == DateTime.now().year &&
                widget.controller.selectedMonth.value.month == DateTime.now().month ?
            null : widget.controller.goToNextMonth,
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

    // Get appropriate animation based on card type
    Animation<double>? scaleAnim;
    Animation<double>? countAnim;

    switch (cardType) {
      case 'income':
        scaleAnim = _incomeScaleAnim;
        countAnim = _incomeCountAnim;
        break;
      case 'expense':
        scaleAnim = _expenseScaleAnim;
        countAnim = _expenseCountAnim;
        break;
      case 'assets':
        scaleAnim = _assetsScaleAnim;
        countAnim = _assetsCountAnim;
        break;
      default:
        break;
    }

    // Use animated value for counting effect, fallback to actual amount
    final displayAmount = (countAnim != null && countAnim.status != AnimationStatus.dismissed)
        ? countAnim.value
        : amount;

    // 금액 형식화
    final formattedAmount = cardType == 'balance' && displayAmount < 0
        ? '-₩${_formatAmount(displayAmount.abs())}'
        : '₩${_formatAmount(displayAmount)}';

    // 카드 타입에 따른 색상 설정
    Color textColor;
    Color iconBgColor;
    Color iconColor;

    if (themeController.isDarkMode) {
      switch (cardType) {
        case 'income':
          textColor = themeController.incomeColor;
          iconBgColor = themeController.incomeColor.withOpacity(0.2);
          iconColor = themeController.incomeColor;
          break;
        case 'expense':
          textColor = themeController.expenseColor;
          iconBgColor = themeController.expenseColor.withOpacity(0.2);
          iconColor = themeController.expenseColor;
          break;
        case 'assets':
          textColor = themeController.financeColor;
          iconBgColor = themeController.financeColor.withOpacity(0.2);
          iconColor = themeController.financeColor;
          break;
        case 'balance':
          textColor = amount >= 0 ? themeController.incomeColor : themeController.expenseColor;
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
          textColor = themeController.incomeColor;
          iconBgColor = themeController.incomeColor.withOpacity(0.1);
          iconColor = themeController.incomeColor;
          break;
        case 'expense':
          textColor = themeController.expenseColor;
          iconBgColor = themeController.expenseColor.withOpacity(0.1);
          iconColor = themeController.expenseColor;
          break;
        case 'assets':
          textColor = themeController.financeColor;
          iconBgColor = themeController.financeColor.withOpacity(0.1);
          iconColor = themeController.financeColor;
          break;
        case 'balance':
          textColor = amount >= 0 ? themeController.incomeColor : themeController.expenseColor;
          iconBgColor = const Color(0xFFF5F5F5);
          iconColor = Colors.grey;
          break;
        default:
          textColor = Colors.grey.shade800;
          iconBgColor = Colors.grey.shade100;
          iconColor = Colors.grey;
      }
    }

    // Wrap with AnimatedBuilder for scale animation (only for income, expense, assets)
    Widget cardWidget = Container(
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

          // 금액 - 애니메이션 적용
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // 숫자만 애니메이션 (카드 전체가 아님)
                if (scaleAnim != null && cardType != 'balance')
                  AnimatedBuilder(
                    animation: scaleAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: scaleAnim!.value,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedAmount,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  )
                else
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

    // 파티클 효과를 위해 Stack으로 감싸기
    if (scaleAnim != null && cardType != 'balance') {
      final nonNullScaleAnim = scaleAnim;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          cardWidget,
          // 컨페티 효과 - 숫자 주변에서 터지는 조각들 (8~10개)
          ...List.generate(10, (index) {
            // 컨페티 색상들 (밝고 화려한 색상)
            final confettiColors = [
              const Color(0xFFFFD700), // 금색
              const Color(0xFFFF6B9D), // 핑크
              const Color(0xFF4ECDC4), // 민트
              const Color(0xFFFFA07A), // 코랄
              const Color(0xFF98D8C8), // 연두
              const Color(0xFFB4A7D6), // 보라
              const Color(0xFFFFE66D), // 노랑
              const Color(0xFF95E1D3), // 청록
            ];

            // 각도별로 퍼지는 위치 (숫자 중심 기준)
            final angle = (index * 36.0) * 3.14159 / 180; // 36도씩

            return AnimatedBuilder(
              animation: nonNullScaleAnim,
              builder: (context, child) {
                // 최대치부터 끝까지 터지는 효과 지속 (1.3 ~ 1.0)
                final progress = nonNullScaleAnim.value;
                final isActive = progress >= 1.3;

                if (!isActive) return const SizedBox.shrink();

                // 터지는 애니메이션 진행도 (더 길게)
                final burstProgress = progress >= 1.5
                    ? ((1.5 - progress) / 0.5 + 1.0).clamp(0.0, 1.0)  // 1.5에서 1.0까지
                    : ((progress - 1.3) / 0.2).clamp(0.0, 1.0);  // 1.3에서 1.5까지

                // 거리는 점점 멀어지고 (더 멀리)
                final distance = 40.0 * burstProgress;
                // 투명도는 천천히 사라짐
                final opacity = (1.0 - (burstProgress * 0.7)).clamp(0.0, 1.0);
                // 회전 (더 많이)
                final rotation = burstProgress * 3.14159 * 3 * (index % 2 == 0 ? 1 : -1);

                // 중심에서 각도별로 퍼져나감
                final offsetX = distance * dart_math.cos(angle);
                final offsetY = distance * dart_math.sin(angle);

                // 다양한 모양 (원, 사각형, 곡선)
                final shapeType = index % 3;

                return Positioned(
                  left: 40 + offsetX,
                  top: 35 + offsetY,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Opacity(
                      opacity: opacity,
                      child: _buildConfettiShape(
                        shapeType,
                        confettiColors[index % confettiColors.length],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      );
    }

    return cardWidget;
  }

  // 컨페티 조각 모양 생성
  Widget _buildConfettiShape(int type, Color color) {
    switch (type) {
      case 0: // 작은 원
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      case 1: // 작은 사각형
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      case 2: // 작은 라운드 바
        return Container(
          width: 8,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      default:
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
    }
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
      TrendyCardDetailDialog(
        cardType: cardType,
        controller: widget.controller,
      ),
      barrierDismissible: true,
    );
  }
}
