// lib/features/dashboard/presentation/widgets/date_range_transaction_dialog.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/entities/transaction_with_category.dart';
import '../presentation/dashboard_controller.dart';

class DateRangeTransactionDialog extends StatefulWidget {
  final DashboardController controller;

  const DateRangeTransactionDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<DateRangeTransactionDialog> createState() => _DateRangeTransactionDialogState();
}

class _DateRangeTransactionDialogState extends State<DateRangeTransactionDialog>
    with TickerProviderStateMixin {
  // 검색 및 필터링 상태
  String searchQuery = '';
  String selectedFilter = '전체';

  // 날짜 범위 상태
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  // 데이터 로딩 상태
  bool isLoading = false;
  List<TransactionWithCategory> transactions = [];

  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadInitialTransactions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialTransactions() async {
    setState(() => isLoading = true);
    try {
      transactions = await widget.controller.fetchTransactionsByDateRange(startDate, endDate, 500);
    } catch (e) {
      debugPrint('거래 내역 로드 오류: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 필터링된 거래 내역 가져오기
  List<TransactionWithCategory> get filteredTransactions {
    if (searchQuery.isEmpty && selectedFilter == '전체') return transactions;

    List<TransactionWithCategory> filtered = transactions;

    if (selectedFilter != '전체') {
      String categoryType = {'수입': 'INCOME', '지출': 'EXPENSE', '재테크': 'FINANCE'}[selectedFilter] ?? '';
      filtered = filtered.where((t) => t.categoryType == categoryType).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((t) =>
        t.description.toLowerCase().contains(query) ||
        t.categoryName.toLowerCase().contains(query) ||
        t.amount.toString().contains(query)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final screenSize = MediaQuery.of(context).size;
    final safeAreaInsets = MediaQuery.of(context).padding;
    final safeHeight = screenSize.height - safeAreaInsets.top - safeAreaInsets.bottom;
    final dialogMaxHeight = math.min(safeHeight * 0.85, 700.0);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: dialogMaxHeight),
              decoration: BoxDecoration(
                color: themeController.isDarkMode
                    ? const Color(0xFF1E1E1E).withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: themeController.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(themeController),
                  _buildDateSelector(themeController),
                  _buildSearchAndFilter(themeController),
                  if (isLoading)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: themeController.primaryColor,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    _buildTransactionList(themeController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 트렌디한 헤더
  Widget _buildHeader(ThemeController themeController) {
    final dateRange = '${DateFormat('M.d').format(startDate)} - ${DateFormat('M.d').format(endDate)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeController.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 세로선 + 제목
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeController.primaryColor,
                      themeController.primaryColor.withOpacity(0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '거래 내역',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: themeController.textPrimaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dateRange,
                        style: TextStyle(
                          fontSize: 13,
                          color: themeController.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeController.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${transactions.length}건',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: themeController.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          // 닫기 버튼
          _TrendyCloseButton(
            onTap: () => Navigator.of(context).pop(),
            themeController: themeController,
          ),
        ],
      ),
    );
  }

  // 날짜 선택 - 심플하게
  Widget _buildDateSelector(ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // 시작일
          Expanded(
            child: _TrendyDateButton(
              date: startDate,
              label: '시작',
              onTap: () => _selectDate(true),
              themeController: themeController,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: themeController.textSecondaryColor,
            ),
          ),
          // 종료일
          Expanded(
            child: _TrendyDateButton(
              date: endDate,
              label: '종료',
              onTap: () => _selectDate(false),
              themeController: themeController,
            ),
          ),
        ],
      ),
    );
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate(bool isStart) async {
    final themeController = Get.find<ThemeController>();
    final initialDate = isStart ? startDate : endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeController.primaryColor,
              onPrimary: Colors.white,
              surface: themeController.cardColor,
              onSurface: themeController.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          if (startDate.isAfter(endDate)) endDate = startDate;
        } else {
          endDate = picked;
          if (endDate.isBefore(startDate)) startDate = endDate;
        }
      });
      _refreshTransactions();
    }
  }

  // 검색 및 필터 - 심플하게
  Widget _buildSearchAndFilter(ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          // 검색창
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: themeController.isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeController.isDarkMode
                    ? Colors.white.withOpacity(0.08)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: TextField(
              style: TextStyle(
                fontSize: 14,
                color: themeController.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: '검색어 입력',
                hintStyle: TextStyle(
                  color: themeController.textSecondaryColor,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: themeController.textSecondaryColor,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          // 필터 칩
          Row(
            children: ['전체', '수입', '지출', '재테크'].map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TrendyFilterChip(
                  label: filter,
                  isSelected: isSelected,
                  onTap: () => setState(() => selectedFilter = filter),
                  themeController: themeController,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 거래 내역 리스트
  Widget _buildTransactionList(ThemeController themeController) {
    final filtered = filteredTransactions;

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: themeController.textSecondaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                searchQuery.isNotEmpty ? '검색 결과가 없습니다' : '거래 내역이 없습니다',
                style: TextStyle(
                  color: themeController.textSecondaryColor,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 날짜별 그룹화
    final grouped = <String, List<TransactionWithCategory>>{};
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var t in filtered) {
      final key = dateFormat.format(t.transactionDate);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final dayTransactions = grouped[dateKey]!;
          final date = dateFormat.parse(dateKey);
          final displayDate = DateFormat('M월 d일 (E)', 'ko_KR').format(date);

          return _TrendyDaySection(
            displayDate: displayDate,
            transactions: dayTransactions,
            themeController: themeController,
            isLast: index == sortedDates.length - 1,
          );
        },
      ),
    );
  }

  Future<void> _refreshTransactions() async {
    setState(() => isLoading = true);
    try {
      transactions = await widget.controller.fetchTransactionsByDateRange(startDate, endDate, 500);
    } catch (e) {
      debugPrint('거래 내역 새로고침 오류: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

// 트렌디한 닫기 버튼
class _TrendyCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final ThemeController themeController;

  const _TrendyCloseButton({required this.onTap, required this.themeController});

  @override
  State<_TrendyCloseButton> createState() => _TrendyCloseButtonState();
}

class _TrendyCloseButtonState extends State<_TrendyCloseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 100), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.themeController.isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: widget.themeController.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

// 트렌디한 날짜 버튼
class _TrendyDateButton extends StatefulWidget {
  final DateTime date;
  final String label;
  final VoidCallback onTap;
  final ThemeController themeController;

  const _TrendyDateButton({
    required this.date,
    required this.label,
    required this.onTap,
    required this.themeController,
  });

  @override
  State<_TrendyDateButton> createState() => _TrendyDateButtonState();
}

class _TrendyDateButtonState extends State<_TrendyDateButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 80), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: widget.themeController.isDarkMode
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.themeController.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.themeController.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('yyyy.MM.dd').format(widget.date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: widget.themeController.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: widget.themeController.primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 트렌디한 필터 칩
class _TrendyFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeController themeController;

  const _TrendyFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.themeController,
  });

  @override
  State<_TrendyFilterChip> createState() => _TrendyFilterChipState();
}

class _TrendyFilterChipState extends State<_TrendyFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 80), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.themeController.primaryColor.withOpacity(0.15)
                  : (widget.themeController.isDarkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.isSelected
                    ? widget.themeController.primaryColor.withOpacity(0.5)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                color: widget.isSelected
                    ? widget.themeController.primaryColor
                    : widget.themeController.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 일별 섹션
class _TrendyDaySection extends StatelessWidget {
  final String displayDate;
  final List<TransactionWithCategory> transactions;
  final ThemeController themeController;
  final bool isLast;

  const _TrendyDaySection({
    required this.displayDate,
    required this.transactions,
    required this.themeController,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // 일별 합계 계산
    double income = 0, expense = 0, finance = 0;
    for (var t in transactions) {
      if (t.categoryType == 'INCOME') income += t.amount.abs();
      else if (t.categoryType == 'EXPENSE') expense += t.amount.abs();
      else if (t.categoryType == 'FINANCE') finance += t.amount.abs();
    }

    return Column(
      children: [
        // 날짜 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: themeController.isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayDate,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: themeController.textPrimaryColor,
                ),
              ),
              Row(
                children: [
                  if (income > 0) _buildSummaryBadge('+${_formatAmount(income)}', const Color(0xFF2EAA87)),
                  if (expense > 0) _buildSummaryBadge('-${_formatAmount(expense)}', const Color(0xFFE57373)),
                  if (finance > 0) _buildSummaryBadge('-${_formatAmount(finance)}', const Color(0xFF5B8BD8)),
                ],
              ),
            ],
          ),
        ),
        // 거래 항목들
        ...transactions.map((t) => _TrendyTransactionItem(
          transaction: t,
          themeController: themeController,
        )),
        if (!isLast)
          Divider(
            height: 1,
            color: themeController.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.shade200,
          ),
      ],
    );
  }

  Widget _buildSummaryBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(amount % 10000 == 0 ? 0 : 1)}만';
    }
    return NumberFormat('#,###').format(amount);
  }
}

// 거래 항목
class _TrendyTransactionItem extends StatelessWidget {
  final TransactionWithCategory transaction;
  final ThemeController themeController;

  const _TrendyTransactionItem({
    required this.transaction,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.categoryType == 'INCOME';
    final isFinance = transaction.categoryType == 'FINANCE';
    final color = isIncome
        ? const Color(0xFF2EAA87)
        : isFinance
            ? const Color(0xFF5B8BD8)
            : const Color(0xFFE57373);
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // 카테고리 색상 인디케이터
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          // 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: themeController.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeController.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          // 금액
          Text(
            '${isIncome ? '+' : '-'}$formattedAmount원',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
