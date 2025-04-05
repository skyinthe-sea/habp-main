// lib/features/calendar/presentation/widgets/day_transactions_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/calendar_transaction.dart';

class DayTransactionsList extends StatelessWidget {
  final CalendarController controller;
  final CalendarFilterController filterController;
  final bool nestedScrollEnabled;

  const DayTransactionsList({
    Key? key,
    required this.controller,
    required this.filterController,
    this.nestedScrollEnabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedDay = controller.selectedDay.value;
      final summary = controller.selectedDaySummary.value;

      // 현재 날짜
      DateTime today = DateTime.now();
      DateTime tomorrow = today.add(const Duration(days: 1));
      int tomorrowDay = tomorrow.day;

      // Check if selected date is in the future
      final isDateInFuture = selectedDay.isAfter(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        tomorrowDay,
      ));

      // Filter transactions based on current filter
      final transactions = summary.transactions.where((transaction) =>
          filterController.matchesFilter(
              transaction.categoryType,
              transaction.categoryId
          )
      ).toList();

      // Calculate filtered amounts for each type
      double filteredIncome = 0;
      double filteredExpense = 0;
      double filteredFinance = 0;

      for (var transaction in transactions) {
        if (transaction.categoryType == 'INCOME') {
          filteredIncome += transaction.amount;
        } else if (transaction.categoryType == 'EXPENSE') {
          filteredExpense += transaction.amount.abs();
        } else if (transaction.categoryType == 'FINANCE') {
          filteredFinance += transaction.amount;
        }
      }

      // Calculate total net amount (all types combined)
      final totalNet = filteredIncome - filteredExpense + filteredFinance;
      final netSign = totalNet >= 0 ? '+' : '-';
      final formattedTotalNet = '$netSign${NumberFormat('#,###').format(totalNet.abs().toInt())}원';

      // Format the selected date
      final formattedDate = DateFormat('yyyy년 M월 d일').format(selectedDay);

      // Check loading state
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Column(
        children: [
          // Header with date and total net amount
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // Change text based on date
                  '$formattedDate ${isDateInFuture ? '거래 예정' : '거래 내역'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Total net amount (always show as long as there are transactions)
                if (transactions.isNotEmpty)
                  Text(
                    formattedTotalNet,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: totalNet >= 0 ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
              ],
            ),
          ),

          // Filter status indicator (smaller and more subtle now)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _buildFilterStatusText(filterController),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary cards for income, expense, and finance
          if (filteredIncome > 0 || filteredExpense > 0 || filteredFinance != 0)
            _buildSummaryCards(filteredIncome, filteredExpense, filteredFinance),
          const SizedBox(height: 16),

          // Transaction list - 중첩 스크롤을 위해 Container로 변경
          Container(
            // 상위 스크롤과 함께 동작하도록 고정 높이 제거하고 스크롤 물리학 설정
            height: transactions.isEmpty ? 200 : null, // 빈 상태일 때만 최소 높이
            constraints: BoxConstraints(
              minHeight: 200, // 최소 높이 보장
              maxHeight: nestedScrollEnabled ? 500 : double.infinity, // 중첩 스크롤일 때는 최대 높이 제한
            ),
            child: transactions.isEmpty
                ? _buildEmptyState(filterController, isDateInFuture)
                : ListView.separated(
              // 중첩 스크롤 설정
              physics: nestedScrollEnabled
                  ? const ClampingScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(),
              shrinkWrap: nestedScrollEnabled, // 중첩 스크롤일 때 내용에 맞게 축소
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return _buildTransactionItem(transactions[index]);
              },
            ),
          ),
        ],
      );
    });
  }

  // Helper method to build the filter status text
  String _buildFilterStatusText(CalendarFilterController filterController) {
    final currentFilter = filterController.currentFilter.value;
    if (currentFilter.categoryType != null || currentFilter.selectedCategoryIds.isNotEmpty) {
      if (currentFilter.categoryType != null) {
        final filterName = currentFilter.categoryType == 'INCOME'
            ? '소득'
            : (currentFilter.categoryType == 'EXPENSE' ? '지출' : '재테크');
        if (currentFilter.selectedCategoryIds.isNotEmpty) {
          return '$filterName (${currentFilter.selectedCategoryIds.length}개 카테고리)';
        }
        return filterName;
      } else if (currentFilter.selectedCategoryIds.isNotEmpty) {
        return '${currentFilter.selectedCategoryIds.length}개 카테고리';
      }
    }
    return '전체';
  }

  // Helper method to build summary cards
  Widget _buildSummaryCards(double income, double expense, double finance) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Income card
            if (income > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '소득 ',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '+${NumberFormat('#,###').format(income.toInt())}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            // Expense card
            if (expense > 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '지출 ',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '-${NumberFormat('#,###').format(expense.toInt())}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

            // Finance card
            if (finance != 0)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '재테크 ',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      (finance >= 0 ? '+' : '-') +
                          '${NumberFormat('#,###').format(finance.abs().toInt())}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

            // Add a small padding at the end for better scrolling experience
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  // Helper method for empty state display
  Widget _buildEmptyState(CalendarFilterController filterController, bool isDateInFuture) {
    return Center(
      child: Padding(
        // Add bottom padding to ensure the empty state isn't hidden by the floating button
        padding: const EdgeInsets.only(bottom: 20, top: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 36,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              // Change empty state text based on date
              isDateInFuture ? '표시할 거래 예정이 없습니다.' : '표시할 거래 내역이 없습니다.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (filterController.currentFilter.value.categoryType != null ||
                filterController.currentFilter.value.selectedCategoryIds.isNotEmpty)
              TextButton(
                onPressed: filterController.resetFilter,
                child: Text(
                  '필터 초기화하기',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(CalendarTransaction transaction) {
    // 거래 시간 포맷팅
    final time = DateFormat('HH:mm').format(transaction.transactionDate);
    final isFixed = transaction.isFixed;

    // 금액 포맷팅
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs()).toString();
    final isIncome = transaction.amount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // 카테고리 아이콘
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction.categoryType).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getCategoryColor(transaction.categoryType),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 거래 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$time · ${transaction.categoryName}${isFixed ? ' · 고정' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // 금액
          Text(
            (isIncome ? '+' : '-') + '$formattedAmount원',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isIncome ? Colors.green[600] : Colors.grey[850],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryType) {
    switch (categoryType) {
      case 'INCOME':
        return Colors.green[600]!;
      case 'EXPENSE':
        return AppColors.primary;
      case 'FINANCE':
        return Colors.blue[600]!;
      default:
        return Colors.grey;
    }
  }
}