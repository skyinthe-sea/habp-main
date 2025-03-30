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

  const DayTransactionsList({
    Key? key,
    required this.controller,
    required this.filterController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedDay = controller.selectedDay.value;
      final summary = controller.selectedDaySummary.value;

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

      // Build filter status text
      String filterStatusText = _buildFilterStatusText(filterController);

      return Column(
        children: [
          // Header with date, filter status, and total net amount
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$formattedDate 거래 내역',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Filter status display
                    Row(
                      children: [
                        Icon(Icons.filter_list, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          filterStatusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
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
          const SizedBox(height: 16),

          // Summary cards for income, expense, and finance
          if (filteredIncome > 0 || filteredExpense > 0 || filteredFinance != 0)
            _buildSummaryCards(filteredIncome, filteredExpense, filteredFinance),
          const SizedBox(height: 16),

          // Transaction list
          Expanded(
            child: transactions.isEmpty
                ? _buildEmptyState(filterController)
                : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            : (currentFilter.categoryType == 'EXPENSE' ? '지출' : '금융');
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
    // Determine how many cards we need to show
    int cardCount = 0;
    if (income > 0) cardCount++;
    if (expense > 0) cardCount++;
    if (finance != 0) cardCount++;

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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '금융 ',
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
  Widget _buildEmptyState(CalendarFilterController filterController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '표시할 거래 내역이 없습니다.',
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
              child: const Text('필터 초기화하기'),
            ),
        ],
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