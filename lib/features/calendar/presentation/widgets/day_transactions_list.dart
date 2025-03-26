import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../../domain/entities/calendar_transaction.dart';

class DayTransactionsList extends StatelessWidget {
  final CalendarController controller;

  const DayTransactionsList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedDay = controller.selectedDay.value;
      final summary = controller.selectedDaySummary.value;
      final transactions = summary.transactions;

      // 선택된 날짜의 포맷팅
      final formattedDate = DateFormat('yyyy년 M월 d일').format(selectedDay);

      // 로딩 상태 확인
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return Column(
        children: [
          // 헤더: 날짜 및 버튼
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$formattedDate 거래 내역',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.add, size: 16),
                //   label: const Text('거래 추가'),
                //   style: ElevatedButton.styleFrom(
                //     backgroundColor: AppColors.primary,
                //     foregroundColor: Colors.white,
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //   ),
                //   onPressed: () {
                //     // TODO: 거래 추가 화면으로 이동
                //     debugPrint('거래 추가 버튼 클릭 - 기능 추가 필요');
                //   },
                // ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 요약 카드 (총 지출/수입)
          if (summary.expense > 0 || summary.income > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    '지출',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '-${NumberFormat('#,###').format(summary.expense.toInt())}원',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
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
              child: Text(
                '날짜를 선택하면 해당 날짜의 거래 내역이 표시됩니다.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
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