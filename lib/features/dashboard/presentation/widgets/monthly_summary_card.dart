// lib/features/dashboard/presentation/widgets/monthly_summary_card.dart
import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
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

    // 2026 트렌디한 색상 설정 (더 부드럽고 세련된 색상)
    Color accentColor;
    Color iconBgColor;
    Color textColor;
    List<Color> gradientColors;

    if (themeController.isDarkMode) {
      switch (cardType) {
        case 'income':
          accentColor = const Color(0xFF5BC4A8); // 부드러운 민트
          iconBgColor = accentColor.withOpacity(0.15);
          textColor = accentColor;
          gradientColors = [
            Colors.white.withOpacity(0.06),
            accentColor.withOpacity(0.03),
          ];
          break;
        case 'expense':
          accentColor = const Color(0xFFE88B8B); // 부드러운 코랄
          iconBgColor = accentColor.withOpacity(0.15);
          textColor = accentColor;
          gradientColors = [
            Colors.white.withOpacity(0.06),
            accentColor.withOpacity(0.03),
          ];
          break;
        case 'assets':
          accentColor = const Color(0xFF7BA3D8); // 부드러운 블루
          iconBgColor = accentColor.withOpacity(0.15);
          textColor = accentColor;
          gradientColors = [
            Colors.white.withOpacity(0.06),
            accentColor.withOpacity(0.03),
          ];
          break;
        case 'balance':
          accentColor = amount >= 0
              ? const Color(0xFF5BC4A8)
              : const Color(0xFFE88B8B);
          iconBgColor = Colors.grey.shade700.withOpacity(0.5);
          textColor = accentColor;
          gradientColors = [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ];
          break;
        default:
          accentColor = Colors.grey.shade400;
          iconBgColor = Colors.grey.shade800;
          textColor = Colors.grey.shade400;
          gradientColors = [
            Colors.white.withOpacity(0.06),
            Colors.white.withOpacity(0.02),
          ];
      }
    } else {
      switch (cardType) {
        case 'income':
          accentColor = const Color(0xFF2EAA87); // 세련된 그린
          iconBgColor = accentColor.withOpacity(0.1);
          textColor = accentColor;
          gradientColors = [
            Colors.white,
            accentColor.withOpacity(0.04),
          ];
          break;
        case 'expense':
          accentColor = const Color(0xFFE57373); // 부드러운 레드
          iconBgColor = accentColor.withOpacity(0.1);
          textColor = accentColor;
          gradientColors = [
            Colors.white,
            accentColor.withOpacity(0.04),
          ];
          break;
        case 'assets':
          accentColor = const Color(0xFF5B8BD8); // 세련된 블루
          iconBgColor = accentColor.withOpacity(0.1);
          textColor = accentColor;
          gradientColors = [
            Colors.white,
            accentColor.withOpacity(0.04),
          ];
          break;
        case 'balance':
          accentColor = amount >= 0
              ? const Color(0xFF2EAA87)
              : const Color(0xFFE57373);
          iconBgColor = Colors.grey.shade100;
          textColor = accentColor;
          gradientColors = [
            Colors.white,
            Colors.grey.shade50,
          ];
          break;
        default:
          accentColor = Colors.grey.shade600;
          iconBgColor = Colors.grey.shade100;
          textColor = Colors.grey.shade600;
          gradientColors = [
            Colors.white,
            Colors.grey.shade50,
          ];
      }
    }

    // 2026 트렌디한 카드 위젯 (글라스모피즘 + 미세 그라데이션)
    Widget cardWidget = _TrendySummaryCardWidget(
      title: title,
      formattedAmount: formattedAmount,
      percentChange: percentChange,
      hasPercentage: hasPercentage,
      isPositiveTrend: isPositiveTrend,
      iconData: iconData,
      cardType: cardType,
      accentColor: accentColor,
      iconBgColor: iconBgColor,
      textColor: textColor,
      gradientColors: gradientColors,
      themeController: themeController,
      scaleAnim: scaleAnim,
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
            // 컨페티 색상들 (더 부드러운 파스텔 색상)
            final confettiColors = [
              const Color(0xFFFFD89B), // 부드러운 금색
              const Color(0xFFFFB5C5), // 부드러운 핑크
              const Color(0xFF7ED4C8), // 부드러운 민트
              const Color(0xFFFFB78C), // 부드러운 코랄
              const Color(0xFFA8E6CF), // 부드러운 연두
              const Color(0xFFC5B8E8), // 부드러운 보라
              const Color(0xFFFFF3A3), // 부드러운 노랑
              const Color(0xFFAAE3D8), // 부드러운 청록
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
                  top: 40 + offsetY,
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

// 2026 트렌디한 서머리 카드 위젯
class _TrendySummaryCardWidget extends StatefulWidget {
  final String title;
  final String formattedAmount;
  final double percentChange;
  final bool hasPercentage;
  final bool isPositiveTrend;
  final IconData iconData;
  final String cardType;
  final Color accentColor;
  final Color iconBgColor;
  final Color textColor;
  final List<Color> gradientColors;
  final ThemeController themeController;
  final Animation<double>? scaleAnim;

  const _TrendySummaryCardWidget({
    required this.title,
    required this.formattedAmount,
    required this.percentChange,
    required this.hasPercentage,
    required this.isPositiveTrend,
    required this.iconData,
    required this.cardType,
    required this.accentColor,
    required this.iconBgColor,
    required this.textColor,
    required this.gradientColors,
    required this.themeController,
    this.scaleAnim,
  });

  @override
  State<_TrendySummaryCardWidget> createState() => _TrendySummaryCardWidgetState();
}

class _TrendySummaryCardWidgetState extends State<_TrendySummaryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressController.reverse();
      },
      child: AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: _buildCard(),
          );
        },
      ),
    );
  }

  Widget _buildCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 88,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.themeController.isDarkMode
                  ? Colors.white.withOpacity(_isPressed ? 0.15 : 0.08)
                  : Colors.grey.shade200.withOpacity(_isPressed ? 0.9 : 0.6),
              width: 1,
            ),
            boxShadow: [
              // 메인 그림자
              BoxShadow(
                color: widget.themeController.isDarkMode
                    ? Colors.black.withOpacity(0.25)
                    : widget.accentColor.withOpacity(0.08),
                blurRadius: _isPressed ? 8 : 16,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
              // 하이라이트 (상단 밝은 부분)
              if (!widget.themeController.isDarkMode)
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 상단: 제목과 아이콘
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.themeController.textSecondaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                  // 트렌디한 아이콘 컨테이너
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: widget.iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      widget.iconData,
                      color: widget.accentColor,
                      size: 14,
                    ),
                  ),
                ],
              ),

              // 하단: 금액과 퍼센트
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildAmountText(),
                  ),
                  if (widget.hasPercentage && widget.percentChange != 0.0)
                    _buildPercentageBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountText() {
    final textWidget = Text(
      widget.formattedAmount,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: widget.textColor,
        letterSpacing: -0.5,
      ),
      overflow: TextOverflow.ellipsis,
    );

    // 숫자 스케일 애니메이션이 있는 경우
    if (widget.scaleAnim != null && widget.cardType != 'balance') {
      return AnimatedBuilder(
        animation: widget.scaleAnim!,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.scaleAnim!.value,
            alignment: Alignment.centerLeft,
            child: textWidget,
          );
        },
      );
    }

    return textWidget;
  }

  Widget _buildPercentageBadge() {
    final isPositive = widget.percentChange > 0;
    final badgeColor = widget.isPositiveTrend
        ? const Color(0xFF2EAA87) // 트렌디한 그린
        : const Color(0xFFE57373); // 트렌디한 레드

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(widget.themeController.isDarkMode ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 10,
            color: badgeColor,
          ),
          const SizedBox(width: 2),
          Text(
            '${isPositive ? '+' : ''}${widget.percentChange.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
