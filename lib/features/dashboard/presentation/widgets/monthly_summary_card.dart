// lib/features/dashboard/presentation/widgets/monthly_summary_card.dart
import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
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
      _CardDetailDialog(
        cardType: cardType,
        controller: widget.controller,
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
        headerColor = themeController.incomeColor;
        title = '소득 분석';
        icon = Icons.trending_up;
        break;
      case 'expense':
        headerColor = themeController.expenseColor;
        title = '지출 분석';
        icon = Icons.trending_down;
        break;
      case 'assets':
        headerColor = themeController.financeColor;
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
    
    // 다크모드에서는 채도를 낮춘 배경색 사용
    Color backgroundColor;
    Color borderColor;
    
    if (themeController.isDarkMode) {
      backgroundColor = color.withOpacity(0.08); // 매우 낮은 투명도
      borderColor = color.withOpacity(0.15);
    } else {
      backgroundColor = color[50]!;
      borderColor = color[100]!;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
                    color: themeController.isDarkMode
                        ? (change > 0 
                            ? themeController.incomeColor.withOpacity(0.15) 
                            : themeController.expenseColor.withOpacity(0.15))
                        : (change > 0 ? Colors.green[100] : Colors.red[100]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: themeController.isDarkMode
                          ? (change > 0 
                              ? themeController.incomeColor 
                              : themeController.expenseColor)
                          : (change > 0 ? Colors.green[700] : Colors.red[700]),
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
    
    // 다크모드에서는 배경색 채도를 더 낮춤
    Color adjustedBackgroundColor = backgroundColor;
    if (themeController.isDarkMode) {
      adjustedBackgroundColor = textColor.withOpacity(0.1);
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: adjustedBackgroundColor,
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

// 별 모양을 그리는 CustomPainter
class _StarPainter extends CustomPainter {
  final Color color;

  _StarPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius / 2.5;

    // 5개의 별 꼭지점
    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 72 - 90) * 3.14159 / 180;
      final innerAngle = ((i * 72) + 36 - 90) * 3.14159 / 180;

      if (i == 0) {
        path.moveTo(
          centerX + outerRadius * cos(outerAngle),
          centerY + outerRadius * sin(outerAngle),
        );
      } else {
        path.lineTo(
          centerX + outerRadius * cos(outerAngle),
          centerY + outerRadius * sin(outerAngle),
        );
      }

      path.lineTo(
        centerX + innerRadius * cos(innerAngle),
        centerY + innerRadius * sin(innerAngle),
      );
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  double cos(double angle) => dart_math.cos(angle);
  double sin(double angle) => dart_math.sin(angle);
}