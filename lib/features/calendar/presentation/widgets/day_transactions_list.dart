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

      // 필터에 맞는 거래만 가져오기
      final transactions = summary.transactions.where((transaction) =>
          filterController.matchesFilter(
              transaction.categoryType,
              transaction.categoryId
          )
      ).toList();

      // 필터링된 수입/지출 계산
      double filteredIncome = 0;
      double filteredExpense = 0;
      for (var transaction in transactions) {
        if (transaction.categoryType == 'INCOME') {
          filteredIncome += transaction.amount;
        } else if (transaction.categoryType == 'EXPENSE') {
          filteredExpense += transaction.amount.abs();
        }
      }

      // 선택된 날짜의 포맷팅
      final formattedDate = DateFormat('yyyy년 M월 d일').format(selectedDay);

      // 순 잔액 계산 (소득 - 지출)
      final netBalance = filteredIncome - filteredExpense;
      final isPositive = netBalance >= 0;
      final netBalanceStr = isPositive
          ? '+${NumberFormat('#,###').format(netBalance.abs().toInt())}원'
          : '-${NumberFormat('#,###').format(netBalance.abs().toInt())}원';

      // 로딩 상태 확인
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      // 필터 상태 표시를 위한 문자열
      String filterStatusText = '';
      final currentFilter = filterController.currentFilter.value;
      if (currentFilter.categoryType != null || currentFilter.selectedCategoryIds.isNotEmpty) {
        if (currentFilter.categoryType != null) {
          final filterName = currentFilter.categoryType == 'INCOME'
              ? '소득'
              : (currentFilter.categoryType == 'EXPENSE' ? '지출' : '금융');
          filterStatusText = filterName;

          if (currentFilter.selectedCategoryIds.isNotEmpty) {
            filterStatusText += ' (${currentFilter.selectedCategoryIds.length}개 카테고리)';
          }
        } else if (currentFilter.selectedCategoryIds.isNotEmpty) {
          filterStatusText = '${currentFilter.selectedCategoryIds.length}개 카테고리';
        }
      } else {
        filterStatusText = '전체';
      }

      return Column(
        children: [
          // 헤더: 날짜 및 순 잔액
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
                    // 필터 상태 표시
                    Row(
                      children: [
                        Icon(
                            Icons.filter_list,
                            size: 14,
                            color: Colors.grey[600]
                        ),
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
                // 순 잔액 표시 (소득과 지출이 모두 있는 경우에만)
                if (filteredIncome > 0 && filteredExpense > 0)
                  Text(
                    netBalanceStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green[600] : Colors.red[600],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 요약 카드 (총 지출/수입)
          if (filteredExpense > 0 || filteredIncome > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // 소득 섹션 (소득이 있는 경우 표시)
                  if (filteredIncome > 0)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: filteredExpense > 0 ? const EdgeInsets.only(right: 4) : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '소득 ',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '+${NumberFormat('#,###').format(filteredIncome.toInt())}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 지출 섹션 (지출이 있는 경우 표시)
                  if (filteredExpense > 0)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: filteredIncome > 0 ? const EdgeInsets.only(left: 4) : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '지출 ',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '-${NumberFormat('#,###').format(filteredExpense.toInt())}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // 거래 목록
          Expanded(
            child: transactions.isEmpty
                ? Center(
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
            )
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