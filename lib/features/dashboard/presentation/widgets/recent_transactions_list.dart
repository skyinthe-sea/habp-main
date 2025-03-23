import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/transaction_with_category.dart';
import '../presentation/dashboard_controller.dart';

class RecentTransactionsList extends StatelessWidget {
  final DashboardController controller;

  const RecentTransactionsList({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isRecentTransactionsLoading.value) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 거래 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: 모든 거래 내역을 보여주는 페이지로 이동
                    debugPrint('모두 보기 버튼 클릭 - 기능 추가 필요');
                  },
                  child: const Text(
                    '모두 보기 →',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 거래 목록 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '날짜',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    '내용',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '카테고리',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '금액',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 거래 목록
          if (controller.recentTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  '거래 내역이 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: controller.recentTransactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = controller.recentTransactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
        ],
      );
    });
  }

  Widget _buildTransactionItem(TransactionWithCategory transaction) {
    // 날짜 포맷팅
    final dateFormat = DateFormat('M월 d일');
    final date = dateFormat.format(transaction.transactionDate);

    // 카테고리 색상
    final categoryColor = _getCategoryColor(transaction.categoryType);

    // 금액
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs()).toString();
    final isIncome = transaction.amount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // 날짜
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),

          // 내용
          Expanded(
            flex: 3,
            child: Text(
              transaction.description,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 카테고리
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.categoryName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: categoryColor,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 금액
          Expanded(
            flex: 2,
            child: Text(
              (isIncome ? '+' : '-') + formattedAmount + '원',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isIncome ? Colors.green[600] : Colors.grey[850],
              ),
              textAlign: TextAlign.right,
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