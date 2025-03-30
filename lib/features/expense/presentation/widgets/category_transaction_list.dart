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

    // 디버깅: 받은 트랜잭션 데이터 출력
    debugPrint('CategoryTransactionList - 받은 거래 내역 수: ${transactions.length}');
    for (var tx in transactions) {
      debugPrint('거래 내역 항목: $tx');
    }

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

    // 필터링: 금액이 음수인 항목만 표시 (지출만 보여주기)
    final expenseTransactions = transactions.where((tx) {
      final amount = tx['amount'];
      return amount is num && amount < 0;
    }).toList();

    // 필터링 후 거래가 없는 경우
    if (expenseTransactions.isEmpty) {
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
              '이 카테고리의 지출 내역이 없습니다',
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

    for (var transaction in expenseTransactions) {
      DateTime date;
      try {
        date = DateTime.parse(transaction['transaction_date']);
      } catch (e) {
        debugPrint('날짜 형식 오류: ${transaction['transaction_date']}');
        // 날짜 파싱 오류 시 현재 날짜 사용
        date = DateTime.now();
      }

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
            0, (sum, item) => sum + (item['amount'] as num).abs());

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
                      color: Colors.red,
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
                final amount = (transaction['amount'] as num).abs();

                // 시간 형식 변환 (transaction_date가 ISO 형식이라고 가정)
                String time;
                try {
                  final transactionDate = DateTime.parse(transaction['transaction_date']);
                  time = DateFormat('a h:mm', 'ko_KR').format(transactionDate);
                } catch (e) {
                  // 날짜 파싱 실패 시 빈 시간 표시
                  time = '';
                }

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
                      transaction['description'] != null && transaction['description'].toString().isNotEmpty
                          ? transaction['description']
                          : '설명 없음',
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