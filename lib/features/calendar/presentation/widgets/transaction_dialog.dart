// lib/features/calendar/presentation/widgets/transaction_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/calendar_filter_controller.dart';
import '../../domain/entities/calendar_transaction.dart';

class TransactionDialog extends StatelessWidget {
  final CalendarController controller;
  final CalendarFilterController filterController;
  final DateTime date;

  const TransactionDialog({
    Key? key,
    required this.controller,
    required this.filterController,
    required this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다이얼로그가 표시될 때 해당 날짜의 거래 정보를 가져옴
    controller.fetchDaySummary(date);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Obx(() {
            final summary = controller.selectedDaySummary.value;

            // 현재 날짜
            DateTime today = DateTime.now();
            DateTime tomorrow = today.add(const Duration(days: 1));
            int tomorrowDay = tomorrow.day;

            // Check if selected date is in the future
            final isDateInFuture = date.isAfter(DateTime(
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

            // 거래 유형별 정렬
            transactions.sort((a, b) {
              // 먼저 카테고리 타입으로 정렬 (소득 -> 지출 -> 재테크)
              final typeOrder = {'INCOME': 0, 'EXPENSE': 1, 'FINANCE': 2};
              final typeCompare = typeOrder[a.categoryType]!.compareTo(typeOrder[b.categoryType]!);
              if (typeCompare != 0) return typeCompare;

              // 같은 유형이면 시간으로 정렬
              return a.transactionDate.compareTo(b.transactionDate);
            });

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

            // Format the selected date
            final formattedDate = DateFormat('yyyy년 M월 d일').format(date);

            // 요일 정보 추가
            final weekday = DateFormat('EEEE', 'ko_KR').format(date);

            // Check loading state
            if (controller.isLoading.value) {
              return Container(
                width: double.infinity,
                height: 250,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              );
            }

            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 헤더 섹션 - 그라데이션 배경과 날짜 정보
                  _buildDialogHeader(formattedDate, weekday, filteredIncome, filteredExpense, filteredFinance, totalNet),

                  // 트랜잭션 목록
                  _buildTransactionList(transactions, isDateInFuture),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // 다이얼로그 헤더 위젯 - 새로운 디자인 (그라데이션 배경)
  Widget _buildDialogHeader(String formattedDate, String weekday, double income, double expense, double finance, double totalNet) {
    // 헤더 배경색 결정 (소득이 많으면 녹색, 지출이 많으면 빨강, 그 외는 파랑)
    Color gradientStartColor;
    Color gradientEndColor;

    if (totalNet > 0) {
      // 소득이 큰 경우
      gradientStartColor = Colors.green[300]!;
      gradientEndColor = Colors.green[100]!;
    } else if (totalNet < 0) {
      // 지출이 큰 경우
      gradientStartColor = Colors.red[300]!;
      gradientEndColor = Colors.red[100]!;
    } else {
      // 그 외 경우 (재테크 또는 밸런스)
      gradientStartColor = AppColors.primary;
      gradientEndColor = AppColors.primary.withOpacity(0.5);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStartColor, gradientEndColor],
        ),
      ),
      child: Column(
        children: [
          // 헤더 상단 - 날짜 및 닫기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 날짜 및 요일 정보
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    weekday,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),

              // 닫기 버튼
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 금액 요약 - 세련된 디자인
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 총 금액 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '순액',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      NumberFormat('#,###').format(totalNet.abs()) + '원',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: totalNet >= 0 ? Colors.green[600] : Colors.red[600],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      totalNet >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: totalNet >= 0 ? Colors.green[600] : Colors.red[600],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 세부 금액 그리드 (소득, 지출, 재테크 구분)
                Row(
                  children: [
                    // 소득
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '소득',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${NumberFormat('#,###').format(income.toInt())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 수직 구분선
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),

                    // 지출
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '지출',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '-${NumberFormat('#,###').format(expense.toInt())}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 수직 구분선
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),

                    // 재테크
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            '재테크',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (finance >= 0 ? '+' : '') + NumberFormat('#,###').format(finance.toInt()),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 트랜잭션 목록 위젯
  Widget _buildTransactionList(List<CalendarTransaction> transactions, bool isDateInFuture) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDateInFuture ? Icons.event_available : Icons.event_busy,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              isDateInFuture ? '표시할 거래 예정이 없습니다.' : '표시할 거래 내역이 없습니다.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            if (filterController.currentFilter.value.categoryType != null ||
                filterController.currentFilter.value.selectedCategoryIds.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  filterController.resetFilter();
                  Get.back(); // 필터 초기화 후 다이얼로그 닫기
                },
                icon: const Icon(Icons.filter_alt_off, size: 16),
                label: const Text(
                  '필터 초기화하기',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
      );
    }

    // 그룹화된 트랜잭션 목록을 만들기 위한 Map
    final groupedTransactions = <String, List<CalendarTransaction>>{};

    // 트랜잭션을 유형별로 그룹화
    for (var transaction in transactions) {
      final type = transaction.categoryType;
      final typeName = type == 'INCOME' ? '소득' : (type == 'EXPENSE' ? '지출' : '재테크');

      if (!groupedTransactions.containsKey(typeName)) {
        groupedTransactions[typeName] = [];
      }

      groupedTransactions[typeName]!.add(transaction);
    }

    // 그룹 순서 정의 (소득, 지출, 재테크)
    final groupOrder = ['소득', '지출', '재테크'];

    // 순서에 따라 그룹 키 정렬
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => groupOrder.indexOf(a).compareTo(groupOrder.indexOf(b)));

    return Flexible(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        children: [
          // 각 그룹별로 섹션 생성
          for (final key in sortedKeys) ...[
            // 그룹 헤더
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Icon(
                    key == '소득'
                        ? Icons.arrow_upward
                        : (key == '지출' ? Icons.arrow_downward : Icons.swap_horiz),
                    size: 16,
                    color: key == '소득'
                        ? Colors.green[600]
                        : (key == '지출' ? Colors.red[600] : Colors.blue[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    key,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: key == '소득'
                          ? Colors.green[600]
                          : (key == '지출' ? Colors.red[600] : Colors.blue[600]),
                    ),
                  ),
                ],
              ),
            ),

            // 해당 그룹의 트랜잭션 목록
            ...groupedTransactions[key]!.map((transaction) => _buildTransactionItem(transaction)),
          ],

          // 하단 여백
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // 개별 트랜잭션 아이템 위젯
  Widget _buildTransactionItem(CalendarTransaction transaction) {
    // 거래 시간 포맷팅
    final time = DateFormat('HH:mm').format(transaction.transactionDate);
    final isFixed = transaction.isFixed;

    // 금액 포맷팅
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs()).toString();
    final isIncome = transaction.amount > 0;
    final isFinance = transaction.categoryType == 'FINANCE';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 카테고리 아이콘
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColorLight(transaction.categoryType),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(transaction.categoryType, transaction.categoryName),
                color: _getCategoryColor(transaction.categoryType),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 거래 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColorLight(transaction.categoryType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.categoryName,
                        style: TextStyle(
                          fontSize: 11,
                          color: _getCategoryColor(transaction.categoryType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isFixed)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '고정',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 금액
          Text(
            (isIncome || (isFinance && transaction.amount > 0) ? '+' : '-') + '$formattedAmount원',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isIncome || (isFinance && transaction.amount > 0)
                  ? Colors.green[600]
                  : (isFinance ? Colors.blue[600] : Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 타입에 따른 색상 반환
  Color _getCategoryColor(String categoryType) {
    switch (categoryType) {
      case 'INCOME':
        return Colors.green[600]!;
      case 'EXPENSE':
        return Colors.red[600]!;
      case 'FINANCE':
        return Colors.blue[600]!;
      default:
        return Colors.grey;
    }
  }

  // 카테고리 타입에 따른 밝은 배경색 반환
  Color _getCategoryColorLight(String categoryType) {
    switch (categoryType) {
      case 'INCOME':
        return Colors.green[50]!;
      case 'EXPENSE':
        return Colors.red[50]!;
      case 'FINANCE':
        return Colors.blue[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  // 카테고리 이름에 따른 아이콘 반환
  IconData _getCategoryIcon(String categoryType, String categoryName) {
    // 카테고리 타입별 기본 아이콘
    if (categoryType == 'INCOME') {
      if (categoryName.contains('급여')) return Icons.monetization_on;
      if (categoryName.contains('용돈')) return Icons.attach_money;
      if (categoryName.contains('이자')) return Icons.account_balance;
      return Icons.arrow_upward;
    }
    else if (categoryType == 'EXPENSE') {
      if (categoryName.contains('통신')) return Icons.phone_android;
      if (categoryName.contains('식비')) return Icons.restaurant;
      if (categoryName.contains('교통')) return Icons.directions_car;
      if (categoryName.contains('쇼핑')) return Icons.shopping_bag;
      if (categoryName.contains('의료')) return Icons.local_hospital;
      if (categoryName.contains('주거')) return Icons.home;
      if (categoryName.contains('월세')) return Icons.home;
      return Icons.arrow_downward;
    }
    else { // FINANCE
      if (categoryName.contains('적금')) return Icons.savings;
      if (categoryName.contains('투자')) return Icons.trending_up;
      if (categoryName.contains('대출')) return Icons.account_balance;
      return Icons.swap_horiz;
    }
  }
}