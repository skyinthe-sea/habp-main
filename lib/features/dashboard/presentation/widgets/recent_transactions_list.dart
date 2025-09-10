// lib/features/dashboard/presentation/widgets/recent_transactions_list.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/entities/transaction_with_category.dart';
import '../presentation/dashboard_controller.dart';
import 'date_range_transaction_dialog.dart';

class RecentTransactionsList extends StatelessWidget {
  final DashboardController controller;

  const RecentTransactionsList({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      if (controller.isRecentTransactionsLoading.value) {
        return Container(
          height: 200,
          alignment: Alignment.center,
          child: CircularProgressIndicator(
            color: themeController.primaryColor,
            strokeWidth: 3,
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: themeController.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 부분
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 타이틀 부분
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeController.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: themeController.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '최근 거래 내역',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: themeController.textPrimaryColor,
                            ),
                          ),
                          Text(
                            controller.getMonthYearString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: themeController.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 전체보기 버튼
                  Material(
                    color: themeController.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _showAllTransactionsDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              '전체보기',
                              style: TextStyle(
                                fontSize: 12,
                                color: themeController.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: themeController.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 거래 리스트 부분
            if (controller.recentTransactions.isEmpty)
              _buildEmptyState()
            else
              _buildDayGroupedTransactions(controller.recentTransactions),
          ],
        ),
      );
    });
  }

  // 빈 상태 표시 위젯
  Widget _buildEmptyState() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: themeController.textSecondaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '${controller.getMonthYearString()}의 거래 내역이 없습니다',
            style: TextStyle(
              color: themeController.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '우측 하단의 + 버튼을 눌러 거래를 추가해보세요',
            style: TextStyle(
              color: themeController.textSecondaryColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 일별 그룹화된 거래 리스트
  Widget _buildDayGroupedTransactions(List<TransactionWithCategory> transactions) {
    // 거래 내역을 날짜별로 그룹화
    final Map<String, List<TransactionWithCategory>> groupedTransactions = {};
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final DateFormat displayFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    // 날짜별로 그룹화
    for (var transaction in transactions) {
      final dateString = dateFormat.format(transaction.transactionDate);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    // 날짜 키를 정렬 (최신 날짜가 먼저 오도록)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // 표시할 최대 날짜 수 제한 (최근 5일)
    final limitedDates = sortedDates.take(5).toList();

    // 모든 투명도를 통합적으로 관리
    final List<double> dayOpacities = [1.0, 0.95, 0.9, 0.8, 0.7];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 8), // 하단 패딩 줄임
      itemCount: limitedDates.length,
      itemBuilder: (context, dayIndex) {
        final dateKey = limitedDates[dayIndex];
        final dayTransactions = groupedTransactions[dateKey]!;
        final date = dateFormat.parse(dateKey);
        final displayDate = displayFormat.format(date);

        // 날짜별 요약 정보 계산
        double dayIncome = 0;
        double dayExpense = 0;
        double dayFinance = 0;
        for (var tx in dayTransactions) {
          if (tx.categoryType == 'INCOME') {
            dayIncome += tx.amount.abs();
          } else if (tx.categoryType == 'EXPENSE') {
            dayExpense += tx.amount.abs();
          } else if (tx.categoryType == 'FINANCE') {
            dayFinance += tx.amount.abs();
          }
        }

        // 그날의 잔액 = 수입 - 지출
        final dayBalance = dayIncome - dayExpense;

        // 일별 영역에 투명도 적용
        final opacity = dayIndex < dayOpacities.length ? dayOpacities[dayIndex] : 0.6;

        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              // 날짜 헤더
              _buildDayHeader(displayDate, dayIncome, dayExpense, dayFinance, dayBalance),

              // 해당 날짜의 거래 내역
              ...dayTransactions.take(3).map((tx) => _buildTransactionItem(tx)).toList(),

              // 만약 해당 날짜의 거래가 3개 이상이면 "더보기" 표시
              if (dayTransactions.length > 3)
                _buildMoreTransactionsIndicator(dayTransactions.length - 3),

              // 날짜 구분선
              if (dayIndex < limitedDates.length - 1)
                const Divider(height: 16, thickness: 1),
            ],
          ),
        );
      },
    );
  }

  // 날짜 헤더 위젯 - 더 간결하게 수정
  Widget _buildDayHeader(String date, double income, double expense, double finance, double balance) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    // 수입/지출/재테크 포맷팅
    final formatter = NumberFormat('#,###');
    final formattedIncome = formatter.format(income);
    final formattedExpense = formatter.format(expense);
    final formattedFinance = formatter.format(finance);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6), // 상하 패딩 줄임
      decoration: BoxDecoration(
        color: themeController.isDarkMode 
            ? themeController.surfaceColor
            : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: themeController.isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade200, 
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 날짜 표시 - 더 작게 구성
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // 더 작게 조정
                decoration: BoxDecoration(
                  color: themeController.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 12, // 아이콘 크기 줄임
                  color: themeController.primaryColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(
                  fontSize: 13, // 글꼴 크기 줄임
                  fontWeight: FontWeight.w600,
                  color: themeController.textPrimaryColor,
                ),
              ),
            ],
          ),

          // 일일 요약 정보 - 태그형 디자인으로 간결하게
          Row(
            children: [
              // 수입
              if (income > 0)
                Container(
                  margin: const EdgeInsets.only(left: 4), // 좌측 마진 줄임
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 패딩 줄임
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode
                        ? AppColors.darkSuccess.withOpacity(0.2)
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+$formattedIncome',
                    style: TextStyle(
                      fontSize: 10, // 폰트 크기 줄임
                      fontWeight: FontWeight.w600,
                      color: themeController.isDarkMode
                          ? AppColors.darkSuccess
                          : Colors.green.shade700,
                    ),
                  ),
                ),

              // 지출
              if (expense > 0)
                Container(
                  margin: const EdgeInsets.only(left: 4), // 좌측 마진 줄임
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 패딩 줄임
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode
                        ? AppColors.darkError.withOpacity(0.2)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-$formattedExpense',
                    style: TextStyle(
                      fontSize: 10, // 폰트 크기 줄임
                      fontWeight: FontWeight.w600,
                      color: themeController.isDarkMode
                          ? AppColors.darkError
                          : Colors.red.shade700,
                    ),
                  ),
                ),

              // 재테크
              if (finance > 0)
                Container(
                  margin: const EdgeInsets.only(left: 4), // 좌측 마진 줄임
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // 패딩 줄임
                  decoration: BoxDecoration(
                    color: themeController.isDarkMode
                        ? AppColors.darkInfo.withOpacity(0.2)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '-$formattedFinance',
                    style: TextStyle(
                      fontSize: 10, // 폰트 크기 줄임
                      fontWeight: FontWeight.w600,
                      color: themeController.isDarkMode
                          ? AppColors.darkInfo
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 거래 항목 위젯 개선 - 더 심플하고 가로 배치로 변경
  Widget _buildTransactionItem(TransactionWithCategory transaction) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    // 금액 포맷팅
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs());

    // 카테고리 색상
    final categoryColor = _getCategoryColor(transaction.categoryType, themeController);

    // 수입인지 확인
    final isIncome = transaction.categoryType == 'INCOME';
    // 재테크인지 확인
    final isFinance = transaction.categoryType == 'FINANCE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 더 좁은 패딩으로 조정
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themeController.isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade100,
          ),
        ),
      ),
      child: Row(
        children: [
          // 카테고리 아이콘
          Container(
            width: 36, // 조금 더 작게 조정
            height: 36,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(transaction.categoryType, transaction.categoryName),
                color: categoryColor,
                size: 18,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 거래 내용
          Expanded(
            child: Text(
              transaction.description,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: themeController.textPrimaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 카테고리 라벨
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transaction.categoryName,
              style: TextStyle(
                fontSize: 11,
                color: categoryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 금액
          Text(
            (isIncome ? '+' : '-') + formattedAmount + '원',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isIncome 
                  ? (themeController.isDarkMode ? AppColors.darkSuccess : Colors.green.shade600)
                  : isFinance 
                      ? (themeController.isDarkMode ? AppColors.darkInfo : Colors.blue.shade600)
                      : (themeController.isDarkMode ? AppColors.darkError : Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // 더 많은 거래가 있음을 표시하는 위젯 - 더 작게 수정
  Widget _buildMoreTransactionsIndicator(int count) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6), // 더 적은 패딩
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? themeController.surfaceColor
              : Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '외 $count건 더보기',
              style: TextStyle(
                fontSize: 11, // 더 작은 폰트
                color: themeController.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 10,
              color: themeController.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // 카테고리 타입에 맞는 아이콘 반환
  IconData _getCategoryIcon(String categoryType, String categoryName) {
    switch (categoryType) {
      case 'INCOME':
        if (categoryName.contains('급여') || categoryName.contains('월급')) {
          return Icons.work_outline;
        } else if (categoryName.contains('용돈')) {
          return Icons.card_giftcard;
        } else if (categoryName.contains('이자')) {
          return Icons.account_balance;
        }
        return Icons.arrow_downward_rounded;

      case 'EXPENSE':
        if (categoryName.contains('식비') || categoryName.contains('음식')) {
          return Icons.restaurant;
        } else if (categoryName.contains('교통')) {
          return Icons.directions_bus;
        } else if (categoryName.contains('통신')) {
          return Icons.phone_android;
        } else if (categoryName.contains('월세') || categoryName.contains('주거')) {
          return Icons.home;
        } else if (categoryName.contains('쇼핑')) {
          return Icons.shopping_bag;
        } else if (categoryName.contains('의료')) {
          return Icons.healing;
        }
        return Icons.arrow_upward_rounded;

      case 'FINANCE':
        if (categoryName.contains('저축')) {
          return Icons.savings;
        } else if (categoryName.contains('투자')) {
          return Icons.trending_up;
        } else if (categoryName.contains('대출')) {
          return Icons.money;
        }
        return Icons.account_balance_wallet;

      default:
        return Icons.receipt_long;
    }
  }

  // 카테고리 유형에 맞는 색상 반환
  Color _getCategoryColor(String categoryType, ThemeController themeController) {
    if (themeController.isDarkMode) {
      switch (categoryType) {
        case 'INCOME':
          return AppColors.darkSuccess;
        case 'EXPENSE':
          return AppColors.darkError;
        case 'FINANCE':
          return AppColors.darkInfo;
        default:
          return Colors.grey;
      }
    } else {
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
  }

  // 전체 거래 목록 다이얼로그
  // Future<void> _showAllTransactionsDialog(BuildContext context) async {
  //   // 로딩 표시
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => Dialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       child: Container(
  //         width: 100,
  //         height: 100,
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             const SizedBox(
  //               width: 40,
  //               height: 40,
  //               child: CircularProgressIndicator(
  //                 color: AppColors.primary,
  //                 strokeWidth: 3,
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             Text(
  //               '거래 내역 불러오는 중...',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 color: Colors.grey.shade700,
  //               ),
  //             )
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   // 거래 내역 불러오기
  //   final allTransactions = await controller.getAllCurrentMonthTransactions();
  //
  //   // 로딩 다이얼로그 닫기
  //   if (context.mounted) Navigator.of(context).pop();
  //
  //   if (!context.mounted) return;
  //
  //   // 화면 크기 가져오기
  //   final screenSize = MediaQuery.of(context).size;
  //   final safeAreaInsets = MediaQuery.of(context).padding;
  //
  //   // 사용 가능한 안전한 높이 계산
  //   final safeHeight = screenSize.height - safeAreaInsets.top - safeAreaInsets.bottom;
  //
  //   // 다이얼로그 최대 높이 (화면의 80% 또는 최대 600px)
  //   final dialogMaxHeight = math.min(safeHeight * 0.8, 600.0);
  //
  //   // 상태 변수 선언
  //   String searchQuery = '';
  //   String selectedFilter = '전체';
  //   List<TransactionWithCategory> filteredTransactions = allTransactions;
  //
  //   // 모든 거래 내역 보여주는 다이얼로그
  //   showDialog(
  //     context: context,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setState) {
  //         // 거래 내역을 날짜별로 그룹화
  //         final Map<String, List<TransactionWithCategory>> groupedTransactions = {};
  //         final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
  //         final DateFormat displayFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');
  //
  //         // 날짜별로 그룹화
  //         for (var transaction in filteredTransactions) {
  //           final dateString = dateFormat.format(transaction.transactionDate);
  //           if (!groupedTransactions.containsKey(dateString)) {
  //             groupedTransactions[dateString] = [];
  //           }
  //           groupedTransactions[dateString]!.add(transaction);
  //         }
  //
  //         // 날짜 키를 정렬 (최신 날짜가 먼저 오도록)
  //         final sortedDates = groupedTransactions.keys.toList()
  //           ..sort((a, b) => b.compareTo(a));
  //
  //         return Dialog(
  //           backgroundColor: Colors.transparent,
  //           insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
  //           child: Container(
  //             width: double.maxFinite,
  //             constraints: BoxConstraints(
  //               maxHeight: dialogMaxHeight,
  //             ),
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.circular(20),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black.withOpacity(0.2),
  //                   blurRadius: 20,
  //                   spreadRadius: 2,
  //                 ),
  //               ],
  //             ),
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(20),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   // 다이얼로그 헤더
  //                   Container(
  //                     padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         begin: Alignment.topLeft,
  //                         end: Alignment.bottomRight,
  //                         colors: [
  //                           AppColors.primary.withOpacity(0.8),
  //                           AppColors.primaryDark,
  //                         ],
  //                       ),
  //                     ),
  //                     child: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       crossAxisAlignment: CrossAxisAlignment.center,
  //                       children: [
  //                         Expanded(
  //                           child: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Text(
  //                                 '${controller.getMonthYearString()} 거래 내역',
  //                                 style: const TextStyle(
  //                                   fontSize: 20,
  //                                   fontWeight: FontWeight.bold,
  //                                   color: Colors.white,
  //                                 ),
  //                                 overflow: TextOverflow.ellipsis,
  //                               ),
  //                               const SizedBox(height: 2),
  //                               Text(
  //                                 '총 ${filteredTransactions.length}건',
  //                                 style: TextStyle(
  //                                   fontSize: 13,
  //                                   color: Colors.white.withOpacity(0.9),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                         Material(
  //                           color: Colors.transparent,
  //                           borderRadius: BorderRadius.circular(24),
  //                           child: InkWell(
  //                             onTap: () => Navigator.of(context).pop(),
  //                             borderRadius: BorderRadius.circular(24),
  //                             child: Container(
  //                               padding: const EdgeInsets.all(8),
  //                               decoration: BoxDecoration(
  //                                 color: Colors.white.withOpacity(0.2),
  //                                 borderRadius: BorderRadius.circular(24),
  //                               ),
  //                               child: const Icon(
  //                                 Icons.close,
  //                                 color: Colors.white,
  //                                 size: 24,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //
  //                   // 검색창
  //                   Padding(
  //                     padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
  //                     child: Container(
  //                       height: 40,
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey.shade100,
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                       child: TextField(
  //                         style: const TextStyle(fontSize: 13),
  //                         decoration: InputDecoration(
  //                           hintText: '거래 내역 검색',
  //                           hintStyle: TextStyle(
  //                             color: Colors.grey.shade500,
  //                             fontSize: 13,
  //                           ),
  //                           prefixIcon: Icon(
  //                             Icons.search,
  //                             color: Colors.grey.shade500,
  //                             size: 18,
  //                           ),
  //                           border: InputBorder.none,
  //                           contentPadding: const EdgeInsets.symmetric(
  //                             horizontal: 12,
  //                             vertical: 8,
  //                           ),
  //                         ),
  //                         onChanged: (value) {
  //                           setState(() {
  //                             searchQuery = value;
  //                             filteredTransactions = _getFilteredTransactions(
  //                                 allTransactions,
  //                                 searchQuery,
  //                                 selectedFilter
  //                             );
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // 필터 칩
  //                   SizedBox(
  //                     height: 36,
  //                     child: Padding(
  //                       padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
  //                       child: ListView(
  //                         scrollDirection: Axis.horizontal,
  //                         children: [
  //                           _buildFilterChip(
  //                               '전체',
  //                               isSelected: selectedFilter == '전체',
  //                               onSelected: (selected) {
  //                                 setState(() {
  //                                   selectedFilter = '전체';
  //                                   filteredTransactions = _getFilteredTransactions(
  //                                       allTransactions,
  //                                       searchQuery,
  //                                       selectedFilter
  //                                   );
  //                                 });
  //                               }
  //                           ),
  //                           _buildFilterChip(
  //                               '수입',
  //                               isSelected: selectedFilter == '수입',
  //                               onSelected: (selected) {
  //                                 setState(() {
  //                                   selectedFilter = '수입';
  //                                   filteredTransactions = _getFilteredTransactions(
  //                                       allTransactions,
  //                                       searchQuery,
  //                                       selectedFilter
  //                                   );
  //                                 });
  //                               }
  //                           ),
  //                           _buildFilterChip(
  //                               '지출',
  //                               isSelected: selectedFilter == '지출',
  //                               onSelected: (selected) {
  //                                 setState(() {
  //                                   selectedFilter = '지출';
  //                                   filteredTransactions = _getFilteredTransactions(
  //                                       allTransactions,
  //                                       searchQuery,
  //                                       selectedFilter
  //                                   );
  //                                 });
  //                               }
  //                           ),
  //                           _buildFilterChip(
  //                               '재테크',
  //                               isSelected: selectedFilter == '재테크',
  //                               onSelected: (selected) {
  //                                 setState(() {
  //                                   selectedFilter = '재테크';
  //                                   filteredTransactions = _getFilteredTransactions(
  //                                       allTransactions,
  //                                       searchQuery,
  //                                       selectedFilter
  //                                   );
  //                                 });
  //                               }
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //
  //                   // 거래 내역 목록
  //                   Expanded(
  //                     child: filteredTransactions.isEmpty
  //                         ? Center(
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(
  //                             Icons.receipt_long_outlined,
  //                             size: 48,
  //                             color: Colors.grey.shade300,
  //                           ),
  //                           const SizedBox(height: 12),
  //                           Text(
  //                             searchQuery.isNotEmpty
  //                                 ? '검색 결과가 없습니다'
  //                                 : '${controller.getMonthYearString()}의 거래 내역이 없습니다',
  //                             style: TextStyle(
  //                               color: Colors.grey.shade500,
  //                               fontSize: 14,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     )
  //                         : ListView.builder(
  //                       itemCount: sortedDates.length,
  //                       itemBuilder: (context, index) {
  //                         final dateKey = sortedDates[index];
  //                         final dayTransactions = groupedTransactions[dateKey]!;
  //                         final date = dateFormat.parse(dateKey);
  //                         final displayDate = displayFormat.format(date);
  //
  //                         // 일별 요약 계산
  //                         double dayIncome = 0;
  //                         double dayExpense = 0;
  //                         double dayFinance = 0;  // 재테크 변수 추가
  //                         for (var tx in dayTransactions) {
  //                           if (tx.categoryType == 'INCOME') {
  //                             dayIncome += tx.amount.abs();
  //                           } else if (tx.categoryType == 'EXPENSE') {
  //                             dayExpense += tx.amount.abs();
  //                           } else if (tx.categoryType == 'FINANCE') {  // 재테크 합산 추가
  //                             dayFinance += tx.amount.abs();
  //                           }
  //                         }
  //
  //                         return Column(
  //                           crossAxisAlignment: CrossAxisAlignment.start,
  //                           children: [
  //                             // 날짜 헤더
  //                             Container(
  //                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                               color: Colors.grey.shade50,
  //                               child: Row(
  //                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                 children: [
  //                                   // 날짜
  //                                   Row(
  //                                     children: [
  //                                       Container(
  //                                         padding: const EdgeInsets.all(6),
  //                                         decoration: BoxDecoration(
  //                                           color: AppColors.primary.withOpacity(0.1),
  //                                           shape: BoxShape.circle,
  //                                         ),
  //                                         child: const Icon(
  //                                           Icons.calendar_today_rounded,
  //                                           size: 14,
  //                                           color: AppColors.primary,
  //                                         ),
  //                                       ),
  //                                       const SizedBox(width: 8),
  //                                       Text(
  //                                         displayDate,
  //                                         style: const TextStyle(
  //                                           fontSize: 14,
  //                                           fontWeight: FontWeight.w600,
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //
  //                                   // 일별 요약
  //                                   Row(
  //                                     children: [
  //                                       if (dayIncome > 0)
  //                                         Container(
  //                                           margin: const EdgeInsets.only(left: 8),
  //                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                                           decoration: BoxDecoration(
  //                                             color: Colors.green.shade50,
  //                                             borderRadius: BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             '+${NumberFormat('#,###').format(dayIncome)}',
  //                                             style: TextStyle(
  //                                               fontSize: 10,
  //                                               fontWeight: FontWeight.w600,
  //                                               color: Colors.green.shade700,
  //                                             ),
  //                                           ),
  //                                         ),
  //
  //                                       if (dayExpense > 0)
  //                                         Container(
  //                                           margin: const EdgeInsets.only(left: 8),
  //                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                                           decoration: BoxDecoration(
  //                                             color: Colors.red.shade50,
  //                                             borderRadius: BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             '-${NumberFormat('#,###').format(dayExpense)}',
  //                                             style: TextStyle(
  //                                               fontSize: 10,
  //                                               fontWeight: FontWeight.w600,
  //                                               color: Colors.red.shade700,
  //                                             ),
  //                                           ),
  //                                         ),
  //
  //                                       // 재테크 요약 추가
  //                                       if (dayFinance > 0)
  //                                         Container(
  //                                           margin: const EdgeInsets.only(left: 8),
  //                                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                                           decoration: BoxDecoration(
  //                                             color: Colors.blue.shade50,
  //                                             borderRadius: BorderRadius.circular(8),
  //                                           ),
  //                                           child: Text(
  //                                             '-${NumberFormat('#,###').format(dayFinance)}',
  //                                             style: TextStyle(
  //                                               fontSize: 10,
  //                                               fontWeight: FontWeight.w600,
  //                                               color: Colors.blue.shade700,
  //                                             ),
  //                                           ),
  //                                         ),
  //                                     ],
  //                                   ),
  //                                 ],
  //                               ),
  //                             ),
  //
  //                             // 해당 날짜의 모든 거래
  //                             ...dayTransactions.map((tx) {
  //                               // 시간 표시 포맷팅
  //                               final timeFormat = DateFormat('a h:mm', 'ko_KR');
  //                               final time = timeFormat.format(tx.transactionDate);
  //
  //                               // 금액 포맷팅
  //                               final formattedAmount = NumberFormat('#,###').format(tx.amount.abs());
  //
  //                               // 카테고리 색상
  //                               final categoryColor = _getCategoryColor(tx.categoryType);
  //
  //                               // 수입인지 확인
  //                               final isIncome = tx.categoryType == 'INCOME';
  //
  //                               return Container(
  //                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  //                                 decoration: BoxDecoration(
  //                                   border: Border(
  //                                     bottom: BorderSide(color: Colors.grey.shade100),
  //                                   ),
  //                                 ),
  //                                 child: Row(
  //                                   children: [
  //                                     // 카테고리 아이콘
  //                                     Container(
  //                                       width: 36,
  //                                       height: 36,
  //                                       decoration: BoxDecoration(
  //                                         color: categoryColor.withOpacity(0.1),
  //                                         borderRadius: BorderRadius.circular(10),
  //                                       ),
  //                                       child: Center(
  //                                         child: Icon(
  //                                           _getCategoryIcon(tx.categoryType, tx.categoryName),
  //                                           color: categoryColor,
  //                                           size: 18,
  //                                         ),
  //                                       ),
  //                                     ),
  //
  //                                     const SizedBox(width: 12),
  //
  //                                     // 거래 정보
  //                                     Expanded(
  //                                       child: Column(
  //                                         crossAxisAlignment: CrossAxisAlignment.start,
  //                                         children: [
  //                                           Row(
  //                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                             children: [
  //                                               // 거래 내용
  //                                               Expanded(
  //                                                 child: Text(
  //                                                   tx.description,
  //                                                   style: const TextStyle(
  //                                                     fontSize: 13,
  //                                                     fontWeight: FontWeight.w500,
  //                                                   ),
  //                                                   overflow: TextOverflow.ellipsis,
  //                                                 ),
  //                                               ),
  //
  //                                               // 금액
  //                                               Text(
  //                                                 (isIncome ? '+' : (tx.categoryType == 'FINANCE' ? '-' : '-')) + formattedAmount + '원',
  //                                                 style: TextStyle(
  //                                                   fontSize: 13,
  //                                                   fontWeight: FontWeight.w600,
  //                                                   color: isIncome ? Colors.green.shade600 :
  //                                                   tx.categoryType == 'FINANCE' ? Colors.blue.shade600 :
  //                                                   Colors.red.shade600,
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //
  //                                           const SizedBox(height: 3),
  //
  //                                           // 시간과 카테고리
  //                                           Row(
  //                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                                             children: [
  //                                               // 시간
  //                                               Text(
  //                                                 time,
  //                                                 style: TextStyle(
  //                                                   fontSize: 11,
  //                                                   color: Colors.grey.shade600,
  //                                                 ),
  //                                               ),
  //
  //                                               // 카테고리
  //                                               Container(
  //                                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //                                                 decoration: BoxDecoration(
  //                                                   color: categoryColor.withOpacity(0.1),
  //                                                   borderRadius: BorderRadius.circular(6),
  //                                                 ),
  //                                                 child: Text(
  //                                                   tx.categoryName,
  //                                                   style: TextStyle(
  //                                                     fontSize: 10,
  //                                                     color: categoryColor,
  //                                                     fontWeight: FontWeight.w500,
  //                                                   ),
  //                                                 ),
  //                                               ),
  //                                             ],
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               );
  //                             }).toList(),
  //
  //                             // 날짜 구분선
  //                             if (index < sortedDates.length - 1)
  //                               const Divider(height: 1, thickness: 4, color: Color(0xFFF5F5F5)),
  //                           ],
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }

  Future<void> _showAllTransactionsDialog(BuildContext context) async {
    // 날짜 범위 선택 다이얼로그 바로 표시
    showDialog(
      context: context,
      builder: (context) => DateRangeTransactionDialog(controller: controller),
    );
  }

  // 필터 칩 위젯
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
        onSelected: onSelected,
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

  // 거래 필터링 메서드
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
}