// lib/features/dashboard/presentation/widgets/date_range_transaction_dialog.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/entities/transaction_with_category.dart';
import '../presentation/dashboard_controller.dart';

class DateRangeTransactionDialog extends StatefulWidget {
  final DashboardController controller;

  const DateRangeTransactionDialog({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<DateRangeTransactionDialog> createState() => _DateRangeTransactionDialogState();
}

class _DateRangeTransactionDialogState extends State<DateRangeTransactionDialog> {
  // 검색 및 필터링 상태
  String searchQuery = '';
  String selectedFilter = '전체';

  // 날짜 범위 상태
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  // 날짜 선택 표시 상태
  bool showDatePicker = false;
  bool isStartDateActive = true; // true: 시작일 선택, false: 종료일 선택

  // 데이터 로딩 상태
  bool isLoading = false;
  List<TransactionWithCategory> transactions = [];

  // 캘린더 관련 상태
  int displayedMonth = DateTime.now().month;
  int displayedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadInitialTransactions();
  }

  // 초기 데이터 로드
  Future<void> _loadInitialTransactions() async {
    setState(() {
      isLoading = true;
    });

    // 먼저 선택된 날짜로 기본 데이터 로드
    try {
      transactions = await _loadTransactionsForDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('거래 내역 로드 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // 날짜 범위에 맞는 거래 내역 로드
  Future<List<TransactionWithCategory>> _loadTransactionsForDateRange(
      DateTime start, DateTime end) async {
    // 지정된 범위의 거래 내역 로드
    // fetchTransactionsByDateRange 메서드를 사용해 날짜 범위에 맞는 거래 내역 불러오기
    return await widget.controller.fetchTransactionsByDateRange(start, end, 500); // 최대 500건 제한
  }

  // 필터링된 거래 내역 가져오기
  List<TransactionWithCategory> get filteredTransactions {
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

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final safeAreaInsets = MediaQuery.of(context).padding;

    // 사용 가능한 안전한 높이 계산
    final safeHeight = screenSize.height - safeAreaInsets.top - safeAreaInsets.bottom;

    // 다이얼로그 최대 높이 (화면의 80% 또는 최대 600px)
    final dialogMaxHeight = math.min(safeHeight * 0.8, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
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
                // 다이얼로그 헤더
                _buildHeader(),

                // 날짜 선택 영역
                _buildDateSelector(),

                // 캘린더 선택기 (토글)
                if (showDatePicker) _buildCalendarPicker(),

                // 검색창
                _buildSearchBar(),

                // 필터 칩
                _buildFilterChips(),

                // 로딩 중이면 로딩 인디케이터 표시
                if (isLoading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  )
                else
                // 거래 내역 목록
                  _buildTransactionList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 헤더 위젯
  Widget _buildHeader() {
    final dateRange = startDate.year == endDate.year && startDate.month == endDate.month
        ? '${DateFormat('yyyy년 M월').format(startDate)} (${transactions.length}건)'
        : '${DateFormat('yyyy.M.d').format(startDate)} ~ ${DateFormat('yyyy.M.d').format(endDate)} (${transactions.length}건)';

    return Container(
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
                const Text(
                  '거래 내역 조회',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateRange,
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
    );
  }

  // 날짜 선택 위젯
  Widget _buildDateSelector() {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 범위 선택 타이틀
          const Row(
            children: [
              Icon(Icons.date_range, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                '조회 기간',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 날짜 선택 컨트롤
          Row(
            children: [
              // 시작 날짜 선택
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isStartDateActive = true;
                      showDatePicker = !showDatePicker;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isStartDateActive && showDatePicker
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isStartDateActive && showDatePicker
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(startDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isStartDateActive && showDatePicker
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isStartDateActive && showDatePicker
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: isStartDateActive && showDatePicker
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 날짜 범위 구분 기호
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 10,
                height: 1,
                color: Colors.grey.shade400,
              ),

              // 종료 날짜 선택
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isStartDateActive = false;
                      showDatePicker = !showDatePicker;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: !isStartDateActive && showDatePicker
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: !isStartDateActive && showDatePicker
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFormat.format(endDate),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: !isStartDateActive && showDatePicker
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: !isStartDateActive && showDatePicker
                                ? AppColors.primary
                                : Colors.black87,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: !isStartDateActive && showDatePicker
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 날짜 범위 바로가기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 날짜 바로가기 버튼들
              Row(
                children: [
                  _buildDateRangeButton('오늘', () {
                    final today = DateTime.now();
                    setState(() {
                      startDate = today;
                      endDate = today;
                      showDatePicker = false;
                    });
                    _refreshTransactions();
                  }),
                  _buildDateRangeButton('7일', () {
                    final today = DateTime.now();
                    setState(() {
                      startDate = today.subtract(const Duration(days: 6));
                      endDate = today;
                      showDatePicker = false;
                    });
                    _refreshTransactions();
                  }),
                  _buildDateRangeButton('30일', () {
                    final today = DateTime.now();
                    setState(() {
                      startDate = today.subtract(const Duration(days: 29));
                      endDate = today;
                      showDatePicker = false;
                    });
                    _refreshTransactions();
                  }),
                  _buildDateRangeButton('이번달', () {
                    final today = DateTime.now();
                    setState(() {
                      startDate = DateTime(today.year, today.month, 1);
                      endDate = today;
                      showDatePicker = false;
                    });
                    _refreshTransactions();
                  }),
                ],
              ),

              // 검색 버튼
              ElevatedButton(
                onPressed: () {
                  // 날짜 선택 모드 종료
                  setState(() {
                    showDatePicker = false;
                  });
                  // 트랜잭션 새로고침
                  _refreshTransactions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 16),
                    SizedBox(width: 4),
                    Text('검색', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 날짜 범위 바로가기 버튼
  Widget _buildDateRangeButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  // 캘린더 선택기 위젯
  Widget _buildCalendarPicker() {
    // 현재 표시중인 월의 날짜 목록 계산
    List<DateTime> daysInMonth = _getDaysInMonth(displayedYear, displayedMonth);

    // 현재 날짜
    final today = DateTime.now();

    // 활성화된 날짜 (시작일 또는 종료일)
    final activeDate = isStartDateActive ? startDate : endDate;

    return Container(
      height: 320, // 높이 제한
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 컨텐츠에 맞게 크기 조정
        children: [
          // 캘린더 헤더 (월, 년도 선택)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 이전 월 버튼
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    if (displayedMonth == 1) {
                      displayedMonth = 12;
                      displayedYear--;
                    } else {
                      displayedMonth--;
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              // 현재 표시 중인 월/년도
              GestureDetector(
                onTap: () {
                  // 오늘 날짜의 월로 점프
                  setState(() {
                    displayedMonth = DateTime.now().month;
                    displayedYear = DateTime.now().year;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '$displayedYear년 $displayedMonth월',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 다음 월 버튼 (현재 월 이후는 비활성화)
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: (displayedYear > today.year ||
                    (displayedYear == today.year && displayedMonth >= today.month))
                    ? null
                    : () {
                  setState(() {
                    if (displayedMonth == 12) {
                      displayedMonth = 1;
                      displayedYear++;
                    } else {
                      displayedMonth++;
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: (displayedYear > today.year ||
                    (displayedYear == today.year && displayedMonth >= today.month))
                    ? Colors.grey.shade300
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 요일 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('일', style: TextStyle(fontSize: 12, color: Colors.red)),
              Text('월', style: TextStyle(fontSize: 12)),
              Text('화', style: TextStyle(fontSize: 12)),
              Text('수', style: TextStyle(fontSize: 12)),
              Text('목', style: TextStyle(fontSize: 12)),
              Text('금', style: TextStyle(fontSize: 12)),
              Text('토', style: TextStyle(fontSize: 12, color: Colors.blue)),
            ],
          ),

          const SizedBox(height: 4),

          // 날짜 그리드 - Expanded로 감싸서 남은 공간을 모두 차지하도록 함
          Expanded(
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(), // 스크롤 허용
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2, // 비율 조정으로 높이 축소
                mainAxisSpacing: 1,   // 행 간격 축소
                crossAxisSpacing: 1,  // 열 간격 축소
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final day = daysInMonth[index];
                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                // 선택된 날짜 범위 내인지 확인
                final isInRange = day.isAfter(startDate.subtract(const Duration(days: 1))) &&
                    day.isBefore(endDate.add(const Duration(days: 1)));

                // 시작일 또는 종료일과 일치하는지 확인
                final isStartDate = day.year == startDate.year &&
                    day.month == startDate.month &&
                    day.day == startDate.day;
                final isEndDate = day.year == endDate.year &&
                    day.month == endDate.month &&
                    day.day == endDate.day;

                // 현재 활성화된 날짜와 일치하는지 확인
                final isActiveDate = day.year == activeDate.year &&
                    day.month == activeDate.month &&
                    day.day == activeDate.day;

                // 미래 날짜인지 확인 (선택 불가)
                final isFutureDate = day.isAfter(today);

                // 현재 월에 속하지 않는 날짜 (이전/다음 월의 날짜)
                final isOtherMonth = day.month != displayedMonth;

                // 일요일은 빨간색, 토요일은 파란색으로 표시
                final textColor = isFutureDate || isOtherMonth
                    ? Colors.grey.shade300
                    : day.weekday == 7  // 일요일
                    ? Colors.red.shade300
                    : day.weekday == 6  // 토요일
                    ? Colors.blue.shade300
                    : Colors.black87;

                return InkWell(
                  onTap: isFutureDate || isOtherMonth
                      ? null
                      : () {
                    setState(() {
                      if (isStartDateActive) {
                        // 시작일 변경 - 종료일보다 이후면 종료일도 함께 변경
                        startDate = DateTime(day.year, day.month, day.day);
                        if (startDate.isAfter(endDate)) {
                          endDate = startDate;
                        }

                        // 시작일 선택 후 자동으로 종료일 선택으로 전환
                        isStartDateActive = false;
                      } else {
                        // 종료일 변경 - 시작일보다 이전이면 시작일도 함께 변경
                        endDate = DateTime(day.year, day.month, day.day);
                        if (endDate.isBefore(startDate)) {
                          startDate = endDate;
                        }
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1), // 마진 축소
                    decoration: BoxDecoration(
                      color: isActiveDate
                          ? AppColors.primary
                          : isStartDate || isEndDate
                          ? AppColors.primary.withOpacity(0.7)
                          : isInRange
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6), // 테두리 반경 축소
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 1)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 11, // 폰트 크기 축소
                          fontWeight: isToday || isStartDate || isEndDate || isActiveDate
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActiveDate || isStartDate || isEndDate
                              ? Colors.white
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 캘린더 도움말 (범례) - 축소
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 오늘 표시
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text('오늘', style: TextStyle(fontSize: 9)),
                  ],
                ),
                const SizedBox(width: 10),

                // 선택된 날짜 표시
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text('선택된 날짜', style: TextStyle(fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 월의 모든 날짜를 가져오는 함수 (이전/다음 월의 날짜 포함)
  List<DateTime> _getDaysInMonth(int year, int month) {
    List<DateTime> days = [];

    // 해당 월의 첫 날
    final firstDayOfMonth = DateTime(year, month, 1);

    // 해당 월의 마지막 날
    final lastDayOfMonth = DateTime(year, month + 1, 0);

    // 첫 날의 요일 (1: 월요일, 7: 일요일)
    int firstWeekday = firstDayOfMonth.weekday;
    if (firstWeekday == 7) firstWeekday = 0;  // 일요일을 0으로 조정

    // 이전 월의 날짜들을 추가 (첫 주의 빈 칸을 채움)
    for (int i = 0; i < firstWeekday; i++) {
      days.add(firstDayOfMonth.subtract(Duration(days: firstWeekday - i)));
    }

    // 현재 월의 모든 날짜 추가
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      days.add(DateTime(year, month, i));
    }

    // 다음 월의 날짜들 추가 (마지막 주 채우기)
    final remainingDays = 42 - days.length;  // 6주(42일)로 캘린더 통일
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDayOfMonth.add(Duration(days: i)));
    }

    return days;
  }

  // 검색창 위젯
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
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
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  // 필터 칩 위젯
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
                '전체',
                isSelected: selectedFilter == '전체',
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = '전체';
                  });
                }
            ),
            _buildFilterChip(
                '수입',
                isSelected: selectedFilter == '수입',
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = '수입';
                  });
                }
            ),
            _buildFilterChip(
                '지출',
                isSelected: selectedFilter == '지출',
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = '지출';
                  });
                }
            ),
            _buildFilterChip(
                '재테크',
                isSelected: selectedFilter == '재테크',
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = '재테크';
                  });
                }
            ),
          ],
        ),
      ),
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

  // 거래 내역 리스트 위젯
  Widget _buildTransactionList() {
    final filtered = filteredTransactions;

    if (filtered.isEmpty) {
      return Expanded(
        child: Center(
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
                    : '해당 기간의 거래 내역이 없습니다',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 거래 내역을 날짜별로 그룹화
    final Map<String, List<TransactionWithCategory>> groupedTransactions = {};
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final DateFormat displayFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

    // 날짜별로 그룹화
    for (var transaction in filtered) {
      final dateString = dateFormat.format(transaction.transactionDate);
      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }
      groupedTransactions[dateString]!.add(transaction);
    }

    // 날짜 키를 정렬 (최신 날짜가 먼저 오도록)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Expanded(
      child: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final dayTransactions = groupedTransactions[dateKey]!;
          final date = dateFormat.parse(dateKey);
          final displayDate = displayFormat.format(date);

          // 일별 요약 계산
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 날짜 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.grey.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 날짜
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // 일별 요약
                    Row(
                      children: [
                        if (dayIncome > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+${NumberFormat('#,###').format(dayIncome)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),

                        if (dayExpense > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${NumberFormat('#,###').format(dayExpense)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),

                        if (dayFinance > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '-${NumberFormat('#,###').format(dayFinance)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // 해당 날짜의 모든 거래
              ...dayTransactions.map((tx) => _buildTransactionItem(tx)).toList(),

              // 날짜 구분선
              if (index < sortedDates.length - 1)
                const Divider(height: 1, thickness: 4, color: Color(0xFFF5F5F5)),
            ],
          );
        },
      ),
    );
  }

  // 거래 항목 위젯
  Widget _buildTransactionItem(TransactionWithCategory transaction) {
    // 시간 표시 포맷팅
    final timeFormat = DateFormat('a h:mm', 'ko_KR');
    final time = timeFormat.format(transaction.transactionDate);

    // 금액 포맷팅
    final formattedAmount = NumberFormat('#,###').format(transaction.amount.abs());

    // 카테고리 색상
    final categoryColor = _getCategoryColor(transaction.categoryType);

    // 수입인지 확인
    final isIncome = transaction.categoryType == 'INCOME';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // 카테고리 아이콘
          Container(
            width: 36,
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

          // 거래 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 거래 내용
                    Expanded(
                      child: Text(
                        transaction.description,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 금액
                    Text(
                      (isIncome ? '+' : (transaction.categoryType == 'FINANCE' ? '-' : '-')) + formattedAmount + '원',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.green.shade600 :
                        transaction.categoryType == 'FINANCE' ? Colors.blue.shade600 :
                        Colors.red.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                // 시간과 카테고리
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 시간
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    // 카테고리
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        transaction.categoryName,
                        style: TextStyle(
                          fontSize: 10,
                          color: categoryColor,
                          fontWeight: FontWeight.w500,
                        ),
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

  // 트랜잭션 새로고침
  Future<void> _refreshTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final newTransactions = await _loadTransactionsForDateRange(startDate, endDate);
      setState(() {
        transactions = newTransactions;
      });
    } catch (e) {
      debugPrint('거래 내역 새로고침 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}