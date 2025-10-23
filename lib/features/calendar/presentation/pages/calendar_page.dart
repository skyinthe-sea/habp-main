// lib/features/calendar/presentation/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../data/datasources/calendar_local_data_source.dart';
import '../../data/repositories/calendar_repository_impl.dart';
import '../../domain/usecases/get_month_transactions.dart';
import '../../domain/usecases/get_day_summary.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/delete_transaction.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/calendar_filter_controller.dart';
import '../widgets/month_calendar_fullscreen.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/filter_modal.dart';
import '../widgets/filter_button.dart'; // Import our new filter button
import '../../../quick_add/presentation/services/save_animation_service.dart';

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
  bool get wantKeepAlive => true; // Keep page state between tabs

  @override
  void initState() {
    super.initState();
    // Initialize SaveAnimationController for marker pulse animations
    Get.put(SaveAnimationController(), permanent: true);
    _filterController = _initFilterController();
    _controller = _initController();
    // Create a Future to ensure data is loaded before rendering the screen
    _initFuture = _loadInitialData();
  }

  CalendarFilterController _initFilterController() {
    // Initialize filter controller
    final dbHelper = DBHelper();
    return Get.put(
        CalendarFilterController(
          dbHelper: dbHelper,
        ),
        permanent: true
    );
  }

  CalendarController _initController() {
    // Dependency injection
    final dbHelper = DBHelper();
    final dataSource = CalendarLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = CalendarRepositoryImpl(localDataSource: dataSource);
    final getMonthTransactionsUseCase = GetMonthTransactions(repository);
    final getDaySummaryUseCase = GetDaySummary(repository);
    final updateTransactionUseCase = UpdateTransaction(repository);
    final deleteTransactionUseCase = DeleteTransaction(repository);

    // Initialize controller
    final controller = CalendarController(
      getMonthTransactions: getMonthTransactionsUseCase,
      getDaySummary: getDaySummaryUseCase,
      updateTransaction: updateTransactionUseCase,
      deleteTransaction: deleteTransactionUseCase,
      filterController: _filterController,
    );

    return Get.put(controller, permanent: true);
  }

  // Show transaction dialog method
  void _showTransactionDialog(DateTime date) {
    // Check if there are transactions for the selected date
    final transactions = _controller.getEventsForDay(date);

    // Only show dialog if there are transactions
    Get.dialog(
      TransactionDialog(
        controller: _controller,
        filterController: _filterController,
        date: date,
      ),
      barrierDismissible: true,
    );
  }

  // Initial data load function
  Future<void> _loadInitialData() async {
    print('Loading initial data...');
    // Explicitly use await to wait for data loading to complete
    await _controller.fetchMonthEvents(DateTime.now());
    await _controller.fetchDaySummary(DateTime.now());
    print('Initial data load complete');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show loading screen while data is loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GetBuilder<ThemeController>(
            builder: (themeController) {
              return Center(
                child: CircularProgressIndicator(
                  color: themeController.primaryColor,
                ),
              );
            },
          );
        }

        // Show actual calendar screen after data is loaded
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            return Scaffold(
              backgroundColor: themeController.backgroundColor,
              body: SafeArea(
                child: Stack(
                  children: [
                    // Full-screen calendar with scroll support
                    MonthCalendarFullscreen(
                      controller: _controller,
                      onDateTap: _showTransactionDialog,
                    ),

                    // Modern filter button (our new implementation)
                    FilterButton(controller: _filterController),

                    // Filter modal (still used for detailed category filtering)
                    FilterModal(controller: _filterController),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}