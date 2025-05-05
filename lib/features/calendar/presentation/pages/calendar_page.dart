// lib/features/calendar/presentation/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/calendar_local_data_source.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/usecases/get_month_transactions.dart';
import '../../domain/usecases/get_day_summary.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/calendar_filter_controller.dart';
import '../widgets/month_calendar_fullscreen.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/filter_modal.dart';
import '../widgets/filter_floating_button.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  late CalendarController _controller;
  late CalendarFilterController _filterController;
  late Future<void> _initFuture;

  @override
  bool get wantKeepAlive => true; // 페이지가 탭 간에 상태를 유지하도록 설정

  @override
  void initState() {
    super.initState();
    _filterController = _initFilterController();
    _controller = _initController();
    // 데이터 로드가 완료된 후에만 화면을 그리도록 Future 생성
    _initFuture = _loadInitialData();
  }

  CalendarFilterController _initFilterController() {
    // 필터 컨트롤러 초기화
    final dbHelper = DBHelper();
    return Get.put(
        CalendarFilterController(
          dbHelper: dbHelper,
        ),
        permanent: true
    );
  }

  CalendarController _initController() {
    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = CalendarLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = CalendarRepositoryImpl(localDataSource: dataSource);
    final getMonthTransactionsUseCase = GetMonthTransactions(repository);
    final getDaySummaryUseCase = GetDaySummary(repository);

    // 컨트롤러 초기화
    final controller = CalendarController(
      getMonthTransactions: getMonthTransactionsUseCase,
      getDaySummary: getDaySummaryUseCase,
      filterController: _filterController,
    );

    return Get.put(controller, permanent: true);
  }

  // 트랜잭션 다이얼로그 표시 메서드
  void _showTransactionDialog(DateTime date) {
    // 선택한 날짜에 거래가 있는지 확인
    final transactions = _controller.getEventsForDay(date);

    // 거래가 있을 때만 다이얼로그 표시
    if (transactions.isNotEmpty) {
      Get.dialog(
        TransactionDialog(
          controller: _controller,
          filterController: _filterController,
          date: date,
        ),
        barrierDismissible: true,
      );
    }
  }

  // 초기 데이터 로드 함수
  Future<void> _loadInitialData() async {
    print('초기 데이터 로드 시작');
    // 명시적으로 await를 사용하여 데이터 로드가 완료될 때까지 대기
    await _controller.fetchMonthEvents(DateTime.now());
    await _controller.fetchDaySummary(DateTime.now());
    print('초기 데이터 로드 완료');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필요

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // 데이터 로딩 중이면 로딩 화면 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        // 데이터 로드 완료 후 실제 캘린더 화면 표시
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Stack(
              children: [
                // 전체 화면을 차지하는 달력
                MonthCalendarFullscreen(
                  controller: _controller,
                  onDateTap: _showTransactionDialog,
                ),

                // 필터 플로팅 버튼
                FilterFloatingButton(controller: _filterController),

                // 필터 모달
                FilterModal(controller: _filterController),
              ],
            ),
          ),
        );
      },
    );
  }
}