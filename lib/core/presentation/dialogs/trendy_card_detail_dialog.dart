// lib/core/presentation/dialogs/trendy_card_detail_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../controllers/theme_controller.dart';
import '../../../features/dashboard/presentation/presentation/dashboard_controller.dart';

/// 2026 최신 트렌디 디자인 카드 상세 다이얼로그
/// 글래스모피즘, 애니메이션, 마이크로 인터랙션 적용
class TrendyCardDetailDialog extends StatefulWidget {
  final String cardType;
  final DashboardController controller;

  const TrendyCardDetailDialog({
    Key? key,
    required this.cardType,
    required this.controller,
  }) : super(key: key);

  @override
  State<TrendyCardDetailDialog> createState() => _TrendyCardDetailDialogState();
}

class _TrendyCardDetailDialogState extends State<TrendyCardDetailDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _countController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _countAnimation;

  ThemeController get themeController => Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // 메인 스케일 애니메이션
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    );

    // 슬라이드 업 애니메이션
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // 펄스 애니메이션 (아이콘용)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 시머 애니메이션 (광택 효과)
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // 카운트업 애니메이션
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _countAnimation = CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutExpo,
    );

    // 애니메이션 시작
    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _countController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _countController.dispose();
    super.dispose();
  }

  // 카드 타입별 설정
  _CardConfig get _cardConfig {
    switch (widget.cardType) {
      case 'income':
        return _CardConfig(
          title: '소득 분석',
          subtitle: 'Income Analysis',
          icon: Icons.trending_up_rounded,
          gradientColors: [
            const Color(0xFF00C853),
            const Color(0xFF69F0AE),
          ],
          accentColor: const Color(0xFF00C853),
          bgPatternColor: const Color(0xFF00E676),
        );
      case 'expense':
        return _CardConfig(
          title: '지출 분석',
          subtitle: 'Expense Analysis',
          icon: Icons.trending_down_rounded,
          gradientColors: [
            const Color(0xFFFF5252),
            const Color(0xFFFF8A80),
          ],
          accentColor: const Color(0xFFFF5252),
          bgPatternColor: const Color(0xFFFF6E6E),
        );
      case 'assets':
        return _CardConfig(
          title: '재테크 분석',
          subtitle: 'Investment Analysis',
          icon: Icons.account_balance_rounded,
          gradientColors: [
            const Color(0xFF2979FF),
            const Color(0xFF82B1FF),
          ],
          accentColor: const Color(0xFF2979FF),
          bgPatternColor: const Color(0xFF448AFF),
        );
      case 'balance':
        return _CardConfig(
          title: '잔액 분석',
          subtitle: 'Balance Analysis',
          icon: Icons.account_balance_wallet_rounded,
          gradientColors: [
            const Color(0xFF7C4DFF),
            const Color(0xFFB388FF),
          ],
          accentColor: const Color(0xFF7C4DFF),
          bgPatternColor: const Color(0xFF9575FF),
        );
      default:
        return _CardConfig(
          title: '분석',
          subtitle: 'Analysis',
          icon: Icons.analytics_rounded,
          gradientColors: [Colors.grey, Colors.grey.shade300],
          accentColor: Colors.grey,
          bgPatternColor: Colors.grey.shade400,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _cardConfig;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: config.accentColor.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 15),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // 배경
                  _buildBackground(config),

                  // 글래스모피즘 오버레이
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      color: themeController.isDarkMode
                          ? Colors.black.withOpacity(0.4)
                          : Colors.white.withOpacity(0.85),
                    ),
                  ),

                  // 시머 효과
                  _buildShimmerEffect(config),

                  // 메인 컨텐츠
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(config),
                      Flexible(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: _buildContent(config),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(_CardConfig config) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeController.isDarkMode
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ]
              : [
                  Colors.white,
                  config.accentColor.withOpacity(0.05),
                ],
        ),
      ),
      child: Stack(
        children: [
          // 장식 원
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.accentColor.withOpacity(0.2),
                    config.accentColor.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.gradientColors[1].withOpacity(0.15),
                    config.gradientColors[1].withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect(_CardConfig config) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Positioned(
          left: MediaQuery.of(context).size.width * _shimmerAnimation.value,
          top: 0,
          bottom: 0,
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0),
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(_CardConfig config) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
      child: Row(
        children: [
          // 애니메이션 아이콘
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: config.gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: config.accentColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                config.icon,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 타이틀
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: themeController.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: config.accentColor.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // 닫기 버튼
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeController.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: themeController.textSecondaryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(_CardConfig config) {
    switch (widget.cardType) {
      case 'income':
        return _buildIncomeContent(config);
      case 'expense':
        return _buildExpenseContent(config);
      case 'assets':
        return _buildAssetsContent(config);
      case 'balance':
        return _buildBalanceContent(config);
      default:
        return const SizedBox();
    }
  }

  Widget _buildIncomeContent(_CardConfig config) {
    return Obx(() {
      final selectedMonth = widget.controller.selectedMonth.value;
      final monthlyIncome = widget.controller.monthlyIncome.value;
      final incomeChange = widget.controller.incomeChangePercentage.value;
      final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

      return Column(
        children: [
          _buildMainAmountCard(
            config: config,
            label: '이번 달 총 소득',
            amount: monthlyIncome,
            changePercent: incomeChange,
          ),
          const SizedBox(height: 20),
          _buildInsightSection(
            config: config,
            insights: [
              _InsightData(
                icon: Icons.calendar_today_rounded,
                title: '평균 일일 소득',
                value: '₩${_formatCurrency(monthlyIncome / daysInMonth)}',
                color: const Color(0xFF10B981),
              ),
              _InsightData(
                icon: Icons.shield_rounded,
                title: '소득 안정성',
                value: incomeChange.abs() < 10 ? '안정적' : '변동 있음',
                color: const Color(0xFF3B82F6),
              ),
              _InsightData(
                icon: Icons.savings_rounded,
                title: '권장 저축률',
                value: '30% (₩${_formatCurrency(monthlyIncome * 0.3)})',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildExpenseContent(_CardConfig config) {
    return Obx(() {
      final selectedMonth = widget.controller.selectedMonth.value;
      final monthlyExpense = widget.controller.monthlyExpense.value;
      final expenseChange = widget.controller.expenseChangePercentage.value;
      final monthlyIncome = widget.controller.monthlyIncome.value;
      final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      final expenseRatio = monthlyIncome > 0 ? (monthlyExpense / monthlyIncome * 100) : 0.0;

      return Column(
        children: [
          _buildMainAmountCard(
            config: config,
            label: '이번 달 총 지출',
            amount: monthlyExpense,
            changePercent: expenseChange,
            isExpense: true,
          ),
          const SizedBox(height: 20),
          _buildInsightSection(
            config: config,
            insights: [
              _InsightData(
                icon: Icons.calendar_today_rounded,
                title: '평균 일일 지출',
                value: '₩${_formatCurrency(monthlyExpense / daysInMonth)}',
                color: const Color(0xFFEF4444),
              ),
              _InsightData(
                icon: Icons.pie_chart_rounded,
                title: '소득 대비 지출률',
                value: '${expenseRatio.toStringAsFixed(1)}%',
                color: const Color(0xFF8B5CF6),
              ),
              _InsightData(
                icon: Icons.lightbulb_rounded,
                title: '절약 상태',
                value: expenseChange > 0 ? '지출 증가 주의!' : '잘하고 있어요!',
                color: expenseChange > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildAssetsContent(_CardConfig config) {
    return Obx(() {
      final monthlyAssets = widget.controller.monthlyAssets.value;
      final monthlyIncome = widget.controller.monthlyIncome.value;
      final investRatio = monthlyIncome > 0 ? (monthlyAssets / monthlyIncome * 100) : 0.0;
      final isGoodRatio = monthlyAssets > monthlyIncome * 0.2;

      return Column(
        children: [
          _buildMainAmountCard(
            config: config,
            label: '이번 달 재테크',
            amount: monthlyAssets,
            showChange: false,
          ),
          const SizedBox(height: 20),
          _buildInsightSection(
            config: config,
            insights: [
              _InsightData(
                icon: Icons.trending_up_rounded,
                title: '투자 비율',
                value: '${investRatio.toStringAsFixed(1)}%',
                color: const Color(0xFF2979FF),
              ),
              _InsightData(
                icon: Icons.flag_rounded,
                title: '권장 투자율',
                value: '소득의 20-30%',
                color: const Color(0xFF10B981),
              ),
              _InsightData(
                icon: Icons.assessment_rounded,
                title: '투자 상태',
                value: isGoodRatio ? '목표 달성!' : '더 투자해보세요!',
                color: isGoodRatio ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildBalanceContent(_CardConfig config) {
    return Obx(() {
      final monthlyIncome = widget.controller.monthlyIncome.value;
      final monthlyExpense = widget.controller.monthlyExpense.value;
      final monthlyAssets = widget.controller.monthlyAssets.value;
      final balance = monthlyIncome - monthlyExpense - monthlyAssets;
      final savingsRate = monthlyIncome > 0 ? (balance / monthlyIncome * 100) : 0.0;
      final isPositive = balance >= 0;
      final isGoodSavings = balance >= monthlyIncome * 0.2;

      return Column(
        children: [
          _buildMainAmountCard(
            config: config,
            label: '이번 달 잔액',
            amount: balance,
            showChange: false,
            isNegative: !isPositive,
          ),
          const SizedBox(height: 20),
          _buildInsightSection(
            config: config,
            insights: [
              _InsightData(
                icon: Icons.savings_rounded,
                title: '저축률',
                value: '${savingsRate.toStringAsFixed(1)}%',
                color: const Color(0xFF2979FF),
              ),
              _InsightData(
                icon: Icons.account_balance_wallet_rounded,
                title: '재정 상태',
                value: isPositive ? '흑자 운영 중' : '적자 주의',
                color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              _InsightData(
                icon: Icons.lightbulb_rounded,
                title: '권장 사항',
                value: isGoodSavings
                    ? '훌륭한 저축률!'
                    : isPositive
                        ? '저축을 늘려보세요'
                        : '지출 관리 필요',
                color: isGoodSavings
                    ? const Color(0xFF10B981)
                    : isPositive
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildMainAmountCard({
    required _CardConfig config,
    required String label,
    required double amount,
    double? changePercent,
    bool showChange = true,
    bool isExpense = false,
    bool isNegative = false,
  }) {
    return AnimatedBuilder(
      animation: _countAnimation,
      builder: (context, child) {
        final animatedAmount = amount * _countAnimation.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                config.gradientColors[0],
                config.gradientColors[1],
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: config.accentColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 배경 패턴
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  config.icon,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (showChange && changePercent != null && changePercent != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (isExpense ? changePercent < 0 : changePercent > 0)
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${changePercent.abs().toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isNegative ? '-' : '',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        '₩',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _formatCurrencyFull(animatedAmount.abs()),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightSection({
    required _CardConfig config,
    required List<_InsightData> insights,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: config.gradientColors,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '인사이트',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: themeController.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...insights.asMap().entries.map((entry) {
          final index = entry.key;
          final insight = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(30 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildInsightCard(insight),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInsightCard(_InsightData insight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.isDarkMode
            ? insight.color.withOpacity(0.1)
            : insight.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: insight.color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  insight.color,
                  insight.color.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: insight.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              insight.icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: themeController.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: insight.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: insight.color.withOpacity(0.5),
            size: 20,
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
      return absAmount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }
  }

  String _formatCurrencyFull(double amount) {
    return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

// 카드 설정 클래스
class _CardConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color bgPatternColor;

  const _CardConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.bgPatternColor,
  });
}

// 인사이트 데이터 클래스
class _InsightData {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _InsightData({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}
