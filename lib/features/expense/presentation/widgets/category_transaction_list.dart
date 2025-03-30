import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class CategoryTransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const CategoryTransactionList({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###', 'ko_KR');

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 지출 내역이 없습니다',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // 거래 내역을 날짜별로 그룹화
    Map<String, List<Map<String, dynamic>>> groupedTransactions = {};

    for (var transaction in transactions) {
      final date = DateTime.parse(transaction['transaction_date']);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      if (!groupedTransactions.containsKey(dateKey)) {
        groupedTransactions[dateKey] = [];
      }

      groupedTransactions[dateKey]!.add(transaction);
    }

    // 날짜 정렬
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final dateTransactions = groupedTransactions[dateKey]!;

        // 날짜 형식 변환
        final date = DateTime.parse(dateKey);
        final formattedDate = DateFormat('M월 d일 (E)', 'ko_KR').format(date);

        // 해당 날짜의 총 지출액
        final dailyTotal = dateTransactions.fold<double>(
            0, (sum, item) => sum + item['amount'].abs());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${currencyFormat.format(dailyTotal.toInt())}원',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // 거래 내역 리스트
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dateTransactions.length,
              itemBuilder: (context, index) {
                final transaction = dateTransactions[index];
                final amount = transaction['amount'].abs();
                final time = DateFormat('a h:mm', 'ko_KR').format(
                    DateTime.parse(transaction['transaction_date']));

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      transaction['description'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Text(
                      '-${currencyFormat.format(amount.toInt())}원',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 구분선
            if (dateIndex < sortedDates.length - 1)
              Divider(
                color: Colors.grey.withOpacity(0.2),
                thickness: 1,
                height: 32,
              ),
          ],
        );
      },
    );
  }
}