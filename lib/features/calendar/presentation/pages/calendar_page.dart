import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/calendar_local_data_source.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/usecases/get_month_transactions.dart';
import '../../domain/usecases/get_day_summary.dart';
import '../controllers/calendar_controller.dart';
import '../widgets/month_calendar.dart';
import '../widgets/day_transactions_list.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with AutomaticKeepAliveClientMixin {
  late CalendarController _controller;
  late Future<void> _initFuture;

  @override
  bool get wantKeepAlive => true; // 페이지가 탭 간에 상태를 유지하도록 설정

  @override
  void initState() {
    super.initState();
    _controller = _initController();
    // 데이터 로드가 완료된 후에만 화면을 그리도록 Future 생성
    _initFuture = _loadInitialData();
  }

  CalendarController _initController() {
    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = CalendarLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = CalendarRepositoryImpl(localDataSource: dataSource);
    final getMonthTransactionsUseCase = GetMonthTransactions(repository);
    final getDaySummaryUseCase = GetDaySummary(repository);

    // 컨트롤러 초기화
    return Get.put(
        CalendarController(
          getMonthTransactions: getMonthTransactionsUseCase,
          getDaySummary: getDaySummaryUseCase,
        ),
        permanent: true
    );
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
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              title: const Text(
                '캘린더',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 데이터 로드 완료 후 실제 캘린더 화면 표시
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              '캘린더',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_outlined, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Text(
                    'KM',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: GetBuilder<CalendarController>(
                init: _controller,
                builder: (controller) {
                  return Column(
                    children: [
                      // 월간 캘린더 (스크롤되지 않는 고정 영역)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: MonthCalendar(controller: controller),
                      ),

                      // 거래 내역 (스크롤 가능한 영역)
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: DayTransactionsList(controller: controller),
                        ),
                      ),
                    ],
                  );
                }
            ),
          ),
        );
      },
    );
  }
}