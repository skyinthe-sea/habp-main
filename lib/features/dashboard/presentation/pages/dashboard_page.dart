// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/transaction_local_data_source.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_category_income.dart';
import '../../domain/usecases/get_category_finance.dart';
import '../../domain/usecases/get_monthly_summary.dart';
import '../../domain/usecases/get_monthly_expenses_trend.dart';
import '../../domain/usecases/get_category_expenses.dart';
import '../../domain/usecases/get_recent_transactions.dart';
import '../../domain/usecases/get_recent_transactions_for_range.dart';
import '../presentation/dashboard_controller.dart';
import '../widgets/monthly_summary_card.dart';
import '../widgets/monthly_expense_chart.dart';
import '../widgets/category_chart_tabs.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../challenge/presentation/widgets/challenge_progress_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late DashboardController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initController() {
    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = TransactionLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = TransactionRepositoryImpl(localDataSource: dataSource);

    final summaryUseCase = GetMonthlySummary(repository);
    final expensesTrendUseCase = GetMonthlyExpensesTrend(repository);
    final categoryExpensesUseCase = GetCategoryExpenses(repository);
    final categoryIncomeUseCase = GetCategoryIncome(repository);
    final categoryFinanceUseCase = GetCategoryFinance(repository);
    final recentTransactionsUseCase = GetRecentTransactions(repository);
    // 새로운 UseCase 추가
    final recentTransactionsForRangeUseCase = GetRecentTransactionsForRange(repository);
    final assetsUseCase = GetAssets(repository);

    dbHelper.printDatabaseInfo();

    _controller = DashboardController(
      getMonthlySummary: summaryUseCase,
      getMonthlyExpensesTrend: expensesTrendUseCase,
      getCategoryExpenses: categoryExpensesUseCase,
      getCategoryIncome: categoryIncomeUseCase,
      getCategoryFinance: categoryFinanceUseCase,
      getRecentTransactions: recentTransactionsUseCase,
      getRecentTransactionsForRange: recentTransactionsForRangeUseCase, // 새로운 UseCase 등록
      getAssets: assetsUseCase,
    );
    Get.put(_controller);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() => Scaffold(
      backgroundColor: themeController.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 고정된 월 선택 컨트롤러 영역
            _buildMonthSelectorBar(),

            // 스크롤 가능한 나머지 콘텐츠
            Expanded(
              child: PageTransitionSwitcher(
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  key: ValueKey<String>(_controller.getMonthYearString()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 월간 요약 카드 (월 선택 제외)
                      MonthlySummaryCard(controller: _controller, excludeMonthSelector: true),
                      const SizedBox(height: 10),

                      // 진행 중인 챌린지
                      const ChallengeProgressWidget(),

                      // 월별 지출 추이 차트
                      Container(
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
                        child: MonthlyExpenseChart(controller: _controller),
                      ),
                      const SizedBox(height: 10),

                      // 카테고리별 차트 (탭으로 전환 가능)
                      Container(
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
                        child: CategoryChartTabs(controller: _controller),
                      ),
                      const SizedBox(height: 10),

                      // 최근 거래 내역
                      Container(
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
                        child: RecentTransactionsList(controller: _controller),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildMonthSelectorBar() {
    final ThemeController themeController = Get.find<ThemeController>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: themeController.isDarkMode
            ? themeController.surfaceColor.withOpacity(0.95)
            : themeController.surfaceColor,
      ),
      child: _buildMonthSelector(),
    );
  }


  Widget _buildMonthSelector() {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final isCurrentMonth = _controller.selectedMonth.value.year == DateTime.now().year &&
          _controller.selectedMonth.value.month == DateTime.now().month;

      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeController.isDarkMode ? [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ] : [
                  Colors.white.withOpacity(0.9),
                  Colors.grey.shade50.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeController.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200.withOpacity(0.8),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: themeController.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 이전 달로 이동 버튼
                _buildNavigationButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: _controller.goToPreviousMonth,
                ),

                // 월 선택 및 현재 월 버튼
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 월 선택 드롭다운 버튼
                      _TrendyMonthButton(
                        monthYearString: _controller.getMonthYearString(),
                        onTap: () => _showMonthPickerDialog(context),
                        themeController: themeController,
                      ),

                      // 현재 월로 이동 버튼
                      const SizedBox(width: 8),
                      _TrendyTodayButton(
                        isCurrentMonth: isCurrentMonth,
                        onTap: _controller.goToCurrentMonth,
                        themeController: themeController,
                      ),
                    ],
                  ),
                ),

                // 다음 달로 이동 버튼
                _buildNavigationButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentMonth ? null : _controller.goToNextMonth,
                  isDisabled: isCurrentMonth,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _showMonthPickerDialog(BuildContext context) async {
    final ThemeController themeController = Get.find<ThemeController>();
    final initialDate = _controller.selectedMonth.value;
    int selectedYear = initialDate.year;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: themeController.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedYear--;
                      });
                    },
                  ),
                  Text('$selectedYear년', style: TextStyle(fontSize: 16, color: themeController.textPrimaryColor)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: selectedYear >= DateTime.now().year ? null : () {
                      setState(() {
                        selectedYear++;
                      });
                    },
                  ),
                ],
              ),
              content: SizedBox(
                width: 300,
                height: 180,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == initialDate.month && selectedYear == initialDate.year;
                    final isDisabled = selectedYear == DateTime.now().year && month > DateTime.now().month;

                    return InkWell(
                      onTap: isDisabled ? null : () {
                        Navigator.of(context).pop(DateTime(selectedYear, month, 1));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? themeController.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? themeController.primaryColor : 
                                   (themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$month월',
                            style: TextStyle(
                              color: isDisabled
                                  ? (themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
                                  : isSelected ? Colors.white : themeController.textPrimaryColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('취소', style: TextStyle(color: themeController.textSecondaryColor)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                      1,
                    ));
                  },
                  child: Text('오늘', style: TextStyle(color: themeController.primaryColor)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      _controller.selectedMonth.value = result;
    }
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    final ThemeController themeController = Get.find<ThemeController>();

    return _TrendyNavButton(
      icon: icon,
      onTap: onTap,
      isDisabled: isDisabled,
      themeController: themeController,
    );
  }
}

// 트렌디한 네비게이션 버튼 위젯
class _TrendyNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDisabled;
  final ThemeController themeController;

  const _TrendyNavButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
    required this.themeController,
  });

  @override
  State<_TrendyNavButton> createState() => _TrendyNavButtonState();
}

class _TrendyNavButtonState extends State<_TrendyNavButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isDisabled ? null : (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: widget.isDisabled ? null : (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: widget.isDisabled ? null : () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.isDisabled
                    ? (widget.themeController.isDarkMode
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade100)
                    : (_isPressed
                        ? widget.themeController.primaryColor.withOpacity(0.15)
                        : (widget.themeController.isDarkMode
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.shade100.withOpacity(0.8))),
                borderRadius: BorderRadius.circular(14),
                border: widget.isDisabled ? null : Border.all(
                  color: widget.themeController.isDarkMode
                      ? Colors.white.withOpacity(0.08)
                      : Colors.grey.shade200.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                color: widget.isDisabled
                    ? (widget.themeController.isDarkMode
                        ? Colors.grey.shade700
                        : Colors.grey.shade400)
                    : widget.themeController.primaryColor,
                size: 22,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 트렌디한 월 선택 버튼 위젯
class _TrendyMonthButton extends StatefulWidget {
  final String monthYearString;
  final VoidCallback onTap;
  final ThemeController themeController;

  const _TrendyMonthButton({
    required this.monthYearString,
    required this.onTap,
    required this.themeController,
  });

  @override
  State<_TrendyMonthButton> createState() => _TrendyMonthButtonState();
}

class _TrendyMonthButtonState extends State<_TrendyMonthButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.themeController.isDarkMode ? [
                    Colors.white.withOpacity(_isPressed ? 0.15 : 0.1),
                    Colors.white.withOpacity(_isPressed ? 0.08 : 0.05),
                  ] : [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.themeController.isDarkMode
                      ? Colors.white.withOpacity(0.12)
                      : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: _isPressed ? [] : [
                  BoxShadow(
                    color: widget.themeController.isDarkMode
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.themeController.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: widget.themeController.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.monthYearString,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: widget.themeController.textPrimaryColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: widget.themeController.textSecondaryColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 트렌디한 오늘 버튼 위젯
class _TrendyTodayButton extends StatefulWidget {
  final bool isCurrentMonth;
  final VoidCallback onTap;
  final ThemeController themeController;

  const _TrendyTodayButton({
    required this.isCurrentMonth,
    required this.onTap,
    required this.themeController,
  });

  @override
  State<_TrendyTodayButton> createState() => _TrendyTodayButtonState();
}

class _TrendyTodayButtonState extends State<_TrendyTodayButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = !widget.isCurrentMonth;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? widget.themeController.primaryColor.withOpacity(_isPressed ? 0.2 : 0.12)
                    : (widget.themeController.isDarkMode
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade200.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
                border: isActive ? Border.all(
                  color: widget.themeController.primaryColor.withOpacity(0.3),
                  width: 1,
                ) : null,
              ),
              child: Icon(
                Icons.today_rounded,
                size: 16,
                color: isActive
                    ? widget.themeController.primaryColor
                    : (widget.themeController.isDarkMode
                        ? Colors.grey.shade600
                        : Colors.grey.shade500),
              ),
            ),
          );
        },
      ),
    );
  }
}

// 페이지 전환 애니메이션을 위한 위젯
class PageTransitionSwitcher extends StatelessWidget {
  final Widget child;
  final Widget Function(Widget, Animation<double>) transitionBuilder;

  const PageTransitionSwitcher({
    Key? key,
    required this.child,
    required this.transitionBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: transitionBuilder,
      child: child,
    );
  }
}