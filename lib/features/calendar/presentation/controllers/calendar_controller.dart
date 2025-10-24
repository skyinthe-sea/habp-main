import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../domain/entities/calendar_transaction.dart';
import '../../domain/entities/day_summary.dart';
import '../../domain/usecases/get_month_transactions.dart';
import '../../domain/usecases/get_day_summary.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import 'calendar_filter_controller.dart';

class CalendarController extends GetxController {

  final GetMonthTransactions getMonthTransactions;
  final GetDaySummary getDaySummary;
  final UpdateTransaction updateTransaction;
  final DeleteTransaction deleteTransaction;
  final CalendarFilterController filterController;

  CalendarController({
    required this.getMonthTransactions,
    required this.getDaySummary,
    required this.updateTransaction,
    required this.deleteTransaction,
    required this.filterController, // 필터 컨트롤러 추가
  });

  // 캘린더 관련 상태
  final Rx<DateTime> focusedDay = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;
  final RxMap<DateTime, List<CalendarTransaction>> events = RxMap<DateTime, List<CalendarTransaction>>();

  // 로딩 상태
  final RxBool isLoading = false.obs;

  // 선택된 날짜의 요약 정보
  final Rx<DaySummary> selectedDaySummary = DaySummary(date: DateTime.now()).obs;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 트랜잭션 변경 이벤트 구독
    ever(_eventBusService.transactionChanged, (_) {
      debugPrint('거래 변경 이벤트 감지됨: 캘린더 데이터 새로고침');
      fetchMonthEvents(focusedDay.value);
      fetchDaySummary(selectedDay.value);
    });

    // 고정 소득 변경 이벤트 구독 추가
    // === 이 부분을 추가해야 함 (시작) ===
    ever(_eventBusService.fixedIncomeChanged, (_) {
      debugPrint('고정 소득 변경 이벤트 감지됨: 캘린더 데이터 새로고침');
      fetchMonthEvents(focusedDay.value);
      fetchDaySummary(selectedDay.value);
    });
    // === 이 부분을 추가해야 함 (끝) ===

    // 필터 변경 이벤트 구독
    ever(filterController.filterChanged, (_) {
      debugPrint('필터 변경 이벤트 감지됨: 캘린더 데이터 필터링');
      fetchMonthEvents(focusedDay.value);
      fetchDaySummary(selectedDay.value);
    });

    fetchMonthEvents(focusedDay.value);
    fetchDaySummary(selectedDay.value);
  }

  @override
  void onClose() {
    // 필요한 정리 작업 수행
    super.onClose();
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
    // print('fetchMonthEvents 호출됨: ${month.year}년 ${month.month}월');
    isLoading.value = true;

    try {
      final result = await getMonthTransactions.execute(month);

      // 새로운 Map을 생성하여 할당 (참조 변경 확실히 하기)
      final newEvents = Map<DateTime, List<CalendarTransaction>>.from(result);
      events.value = newEvents;

      // 강제로 업데이트 트리거하기
      events.refresh();

      print('이벤트 로드 완료: ${events.length}일에 거래 있음');

      // GetBuilder를 사용하는 위젯들을 위한 업데이트
      update();

      // 약간의 지연 후 한 번 더 새로고침 시도 (UI 업데이트 보장)
      Future.delayed(const Duration(milliseconds: 100), () {
        events.refresh();
        update();
      });

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

  // 해당 날짜에 이벤트가 있는지 확인 (필터링 적용)
  List<CalendarTransaction> getEventsForDay(DateTime day) {
    // 날짜만 비교하기 위해 시간 정보 제거
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final dayEvents = events[normalizedDay] ?? [];

    // 필터링 적용
    return dayEvents.where((transaction) =>
        filterController.matchesFilter(
            transaction.categoryType,
            transaction.categoryId
        )
    ).toList();
  }

  // 해당 날짜의 수입 합계 (필터링 적용)
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

  // 해당 날짜의 지출 합계 (필터링 적용)
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

  // Get finance amount for a specific day
  double getDayFinance(DateTime day) {
    final transactions = getEventsForDay(day);
    double finance = 0;
    for (var transaction in transactions) {
      if (transaction.categoryType == 'FINANCE') {
        finance += transaction.amount;
      }
    }
    return finance;
  }

  // 거래 수정
  Future<void> updateTransactionRecord(CalendarTransaction transaction) async {
    try {
      isLoading.value = true;

      debugPrint('📝 [CalendarController] Updating transaction: ${transaction.description}');
      debugPrint('📝 [CalendarController] Transaction imagePath: ${transaction.imagePath}');

      // 거래 수정 실행
      await updateTransaction.call(transaction);

      // 데이터 새로고침
      await fetchMonthEvents(focusedDay.value);
      await fetchDaySummary(selectedDay.value);

      // 이벤트 버스로 변경 알림
      _eventBusService.emitTransactionChanged();

      debugPrint('✅ [CalendarController] 거래 수정 완료: ${transaction.description}');
    } catch (e) {
      debugPrint('❌ [CalendarController] 거래 수정 오류: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // 거래 삭제
  Future<void> deleteTransactionRecord(CalendarTransaction transaction) async {
    try {
      isLoading.value = true;
      
      // 거래 삭제 실행
      await deleteTransaction.call(transaction);
      
      // 데이터 새로고침
      await fetchMonthEvents(focusedDay.value);
      await fetchDaySummary(selectedDay.value);
      
      // 이벤트 버스로 변경 알림
      _eventBusService.emitTransactionChanged();
      
      debugPrint('거래 삭제 완료: ${transaction.description}');
    } catch (e) {
      debugPrint('거래 삭제 오류: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }
}