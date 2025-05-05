// lib/features/dashboard/presentation/widgets/recent_transactions_list.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/transaction_with_category.dart';
import '../presentation/dashboard_controller.dart';

class RecentTransactionsList extends StatelessWidget {
  final DashboardController controller;

  const RecentTransactionsList({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isRecentTransactionsLoading.value) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _showAllTransactionsDialog(context);
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            '모두 보기',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 거래 목록
            if (controller.recentTransactions.isEmpty)
              Container(
                height: 180,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${controller.getMonthYearString()}의 거래 내역이 없습니다',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // 거래 목록 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            '날짜',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '내용',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            '카테고리',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            '금액',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: List.generate(
                      controller.recentTransactions.length > 8
                          ? 8
                          : controller.recentTransactions.length,
                          (index) {
                        final transaction = controller.recentTransactions[index];

                        // 투명도 적용 (5개 이후부터 점점 투명하게 처리)
                        double opacity = 1.0;
                        if (index == 5) opacity = 0.8;
                        else if (index == 6) opacity = 0.5;
                        else if (index == 7) opacity = 0.2;

                        return Opacity(
                          opacity: opacity,
                          child: Column(
                            children: [
                              _buildTransactionItem(transaction),
                              if (index < (controller.recentTransactions.length > 8 ? 7 : controller.recentTransactions.length - 1))
                                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // 하단 그라데이션 표시 (더 볼 내용이 있음을 암시)
                  if (controller.recentTransactions.length > 8)
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Future<void> _showAllTransactionsDialog(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '거래 내역 불러오는 중...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              )
            ],
          ),
        ),
      ),
    );

    // Fetch transactions for current month
    final allTransactions = await controller.getAllCurrentMonthTransactions();

    // Close loading dialog
    if (context.mounted) Navigator.of(context).pop();

    if (!context.mounted) return;

    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final safeAreaInsets = MediaQuery.of(context).padding;

    // 사용 가능한 안전한 높이 계산
    final safeHeight = screenSize.height - safeAreaInsets.top - safeAreaInsets.bottom;

    // 다이얼로그 최대 높이 (화면의 80% 또는 최대 600px)
    final dialogMaxHeight = math.min(safeHeight * 0.8, 600.0);

    // StatefulBuilder를 사용하여 다이얼로그 내부에서 상태 관리
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // 검색어 및 필터 상태 변수
          String searchQuery = '';
          String selectedFilter = '전체';

          // 검색 및 필터링된 트랜잭션 목록 계산
          List<TransactionWithCategory> filteredTransactions = _getFilteredTransactions(
              allTransactions,
              searchQuery,
              selectedFilter
          );

          // 검색어 변경 핸들러
          void onSearchChanged(String query) {
            setState(() {
              searchQuery = query;
              filteredTransactions = _getFilteredTransactions(
                  allTransactions,
                  searchQuery,
                  selectedFilter
              );
            });
          }

          // 필터 변경 핸들러
          void onFilterSelected(String filter) {
            setState(() {
              selectedFilter = filter;
              filteredTransactions = _getFilteredTransactions(
                  allTransactions,
                  searchQuery,
                  selectedFilter
              );
            });
          }

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Container(
              width: double.maxFinite,
              constraints: BoxConstraints(
                maxHeight: dialogMaxHeight,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dialog header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.8),
                            AppColors.primaryDark,
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${controller.getMonthYearString()} 거래 내역',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '총 ${allTransactions.length}건',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 검색창 - 이제 실제로 동작함
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: '거래 내역 검색',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: onSearchChanged, // 검색어 변경 시 호출
                        ),
                      ),
                    ),

                    // 필터 칩 - 이제 실제로 동작함
                    SizedBox(
                      height: 36,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildFilterChip(
                                '전체',
                                isSelected: selectedFilter == '전체',
                                onSelected: (_) => onFilterSelected('전체')
                            ),
                            _buildFilterChip(
                                '수입',
                                isSelected: selectedFilter == '수입',
                                onSelected: (_) => onFilterSelected('수입')
                            ),
                            _buildFilterChip(
                                '지출',
                                isSelected: selectedFilter == '지출',
                                onSelected: (_) => onFilterSelected('지출')
                            ),
                            _buildFilterChip(
                                '재테크',
                                isSelected: selectedFilter == '재테크',
                                onSelected: (_) => onFilterSelected('재테크')
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Column headers
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              '날짜',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '내용',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '카테고리',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '금액',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transaction list
                    Expanded(
                      child: filteredTransactions.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isNotEmpty
                                  ? '검색 결과가 없습니다'
                                  : '${controller.getMonthYearString()}의 거래 내역이 없습니다',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                          : Theme(
                        data: Theme.of(context).copyWith(
                          scrollbarTheme: ScrollbarThemeData(
                            thumbColor: MaterialStateProperty.all(
                              AppColors.primary.withOpacity(0.6),
                            ),
                            thickness: MaterialStateProperty.all(6),
                            radius: const Radius.circular(12),
                            minThumbLength: 80,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 트랜잭션 리스트
                            Scrollbar(
                              radius: const Radius.circular(10),
                              thickness: 6,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 60),
                                itemCount: filteredTransactions.length,
                                separatorBuilder: (context, index) =>
                                    Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  return _buildTransactionItem(filteredTransactions[index]);
                                },
                              ),
                            ),

                            // 스크롤 인디케이터
                            if (filteredTransactions.length > 5)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.8),
                                        Colors.white,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.swipe_vertical_outlined,
                                            size: 14,
                                            color: AppColors.primary.withOpacity(0.7),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '스크롤하여 더 보기',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<TransactionWithCategory> _getFilteredTransactions(
      List<TransactionWithCategory> transactions,
      String searchQuery,
      String selectedFilter
      ) {
    // 검색어와 필터가 없으면 모든 트랜잭션 반환
    if (searchQuery.isEmpty && selectedFilter == '전체') {
      return transactions;
    }

    // 먼저 필터 적용
    List<TransactionWithCategory> filtered = transactions;

    // 카테고리 타입으로 필터링
    if (selectedFilter != '전체') {
      String categoryType;

      // 필터 이름을 영문 카테고리 타입으로 변환
      switch (selectedFilter) {
        case '수입':
          categoryType = 'INCOME';
          break;
        case '지출':
          categoryType = 'EXPENSE';
          break;
        case '재테크':
          categoryType = 'FINANCE';
          break;
        default:
          categoryType = '';
      }

      filtered = filtered.where(
              (transaction) => transaction.categoryType == categoryType
      ).toList();
    }

    // 검색어가 있으면 추가 필터링
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();

      filtered = filtered.where((transaction) {
        // 내용, 카테고리명, 금액으로 검색
        return transaction.description.toLowerCase().contains(query) ||
            transaction.categoryName.toLowerCase().contains(query) ||
            transaction.amount.toString().contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildFilterChip(
      String label,
      {bool isSelected = false,
        required Function(bool) onSelected}
      ) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? AppColors.primary : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected, // 이제 콜백 사용
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        labelPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionWithCategory transaction) {
    // 날짜 포맷팅
    final dateFormat = DateFormat('M월 d일');
    final date = dateFormat.format(transaction.transactionDate);

    // 카테고리 색상
    final categoryColor = _getCategoryColor(transaction.categoryType);

    // 금액
    final formattedAmount =
    NumberFormat('#,###').format(transaction.amount.abs()).toString();
    final isIncome = transaction.categoryType == 'INCOME';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 패딩 줄임
      child: Row(
        children: [
          // 날짜
          SizedBox(
            width: 70,
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12, // 폰트 크기 줄임
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // 내용
          Expanded(
            flex: 3,
            child: Text(
              transaction.description,
              style: TextStyle(
                fontSize: 13, // 폰트 크기 줄임
                fontWeight: FontWeight.w500,
                color: Colors.grey[900],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 카테고리
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 패딩 줄임
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  transaction.categoryName,
                  style: TextStyle(
                    fontSize: 10, // 폰트 크기 줄임
                    fontWeight: FontWeight.w500,
                    color: categoryColor,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // 금액
          SizedBox(
            width: 90,
            child: Text(
              (isIncome ? '+' : '-') + formattedAmount + '원',
              style: TextStyle(
                fontSize: 12, // 폰트 크기 줄임
                fontWeight: FontWeight.w600,
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