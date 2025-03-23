import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/calendar_transaction.dart';
import '../../domain/entities/day_summary.dart';
import '../../domain/usecases/get_month_transactions.dart';
import '../../domain/usecases/get_day_summary.dart';

class CalendarController extends GetxController {
  final GetMonthTransactions getMonthTransactions;
  final GetDaySummary getDaySummary;

  CalendarController({
    required this.getMonthTransactions,
    required this.getDaySummary,
  });

  // 캘린더 관련 상태
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final RxMap<DateTime, List<CalendarTransaction>> events = RxMap<DateTime, List<CalendarTransaction>>();

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // 선택된 날짜의 요약 정보
  final Rx<DaySummary> selectedDaySummary = DaySummary(date: DateTime.now()).obs;

  @override
  void onInit() {
    super.onInit();
    fetchMonthEvents(focusedDay.value);
    fetchDaySummary(selectedDay.value);
  }

  // 달력 월 변경 시 호출되는 메서드
  void onPageChanged(DateTime day) {
    focusedDay.value = day;
    fetchMonthEvents(day);
  }

  // 날짜 선택 시 호출되는 메서드
  void onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    this.selectedDay.value = selectedDay;
    this.focusedDay.value = focusedDay;
    fetchDaySummary(selectedDay);
  }

  // 해당 월의 거래 내역 가져오기
  // 월별 거래 내역 가져오기
  Future<void> fetchMonthEvents(DateTime month) async {
    print('fetchMonthEvents 호출됨: ${month.year}년 ${month.month}월');
    isLoading.value = true;

    try {
      final result = await getMonthTransactions.execute(month);
      events.value = result;
      print('이벤트 로드 완료: ${events.length}일에 거래 있음');

      // 이 함수가 완료되기 전에 update() 호출
      update();
      return; // 명시적으로 완료를 반환
    } catch (e) {
      print('월별 거래 내역 가져오기 오류: $e');
      throw e; // 오류 전파 (FutureBuilder에서 감지하기 위해)
    } finally {
      isLoading.value = false;
    }
  }

  // 선택된 날짜의 요약 정보 가져오기
  Future<void> fetchDaySummary(DateTime date) async {
    try {
      final result = await getDaySummary.execute(date);
      selectedDaySummary.value = result;
      debugPrint('${date.year}/${date.month}/${date.day} 요약: 수입 ${result.income}, 지출 ${result.expense}');
    } catch (e) {
      debugPrint('일별 요약 가져오기 오류: $e');
    }
  }

  // 해당 날짜에 이벤트가 있는지 확인
  List<CalendarTransaction> getEventsForDay(DateTime day) {
    // 날짜만 비교하기 위해 시간 정보 제거
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return events[normalizedDay] ?? [];
  }

  // 해당 날짜의 수입 합계
  double getDayIncome(DateTime day) {
    final transactions = getEventsForDay(day);
    double income = 0;
    for (var transaction in transactions) {
      if (transaction.categoryType == 'INCOME') {
        income += transaction.amount;
      }
    }
    return income;
  }

  // 해당 날짜의 지출 합계
  double getDayExpense(DateTime day) {
    final transactions = getEventsForDay(day);
    double expense = 0;
    for (var transaction in transactions) {
      if (transaction.categoryType == 'EXPENSE') {
        expense += transaction.amount.abs();
      }
    }
    return expense;
  }
}