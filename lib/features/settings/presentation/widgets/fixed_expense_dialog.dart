import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/util/thousands_formatter.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../controllers/settings_controller.dart';
import 'package:table_calendar/table_calendar.dart';

class FixedExpenseDialog extends StatefulWidget {
  const FixedExpenseDialog({Key? key}) : super(key: key);

  @override
  State<FixedExpenseDialog> createState() => _FixedExpenseDialogState();
}

class _FixedExpenseDialogState extends State<FixedExpenseDialog> with SingleTickerProviderStateMixin {
  late final SettingsController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Map to cache transaction history for categories
  final Map<int, List<Map<String, dynamic>>> _categoryTransactionHistory = {};
  bool _isLoadingTransactions = true;

  // Create mode
  bool _isCreateMode = false;

  // Detail view mode
  bool _isDetailViewMode = false;
  CategoryWithSettings? _selectedCategory;
  List<FixedTransactionSetting>? _selectedHistoricalSettings;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  DateTime _effectiveFromDate = DateTime.now();
  bool _isValidAmount = true;

  // For delete mode
  bool _isDeleteMode = false;
  DateTime _deleteFromDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _loadTransactionHistory();

    // Initialize the selected date
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _effectiveFromDate = DateTime(now.year, now.month, 1);
    _deleteFromDate = DateTime(now.year, now.month, 1);

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Load transaction history for each category
  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    final dbHelper = DBHelper();
    final db = await dbHelper.database;

    for (final category in _controller.expenseCategories) {
      // Get all settings for the category
      final List<Map<String, dynamic>> settings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [category.id],
        orderBy: 'effective_from DESC',
      );

      // Get all transactions for the category
      final List<Map<String, dynamic>> transactions = await db.query(
        'transaction_record2',
        where: 'category_id = ?',
        whereArgs: [category.id],
        orderBy: 'transaction_date DESC',
      );

      // Store the history
      _categoryTransactionHistory[category.id] = [...settings, ...transactions];
    }

    setState(() {
      _isLoadingTransactions = false;
    });
  }

  // Get the most recent settings effective for a given date
  FixedTransactionSetting? _getEffectiveSettingForDate(CategoryWithSettings category, DateTime date) {
    final effectiveSettings = category.settings
        .where((setting) =>
    DateTime.parse(setting.effectiveFrom.toIso8601String())
        .isBefore(date) ||
        DateTime.parse(setting.effectiveFrom.toIso8601String())
            .isAtSameMomentAs(date))
        .toList();

    if (effectiveSettings.isNotEmpty) {
      effectiveSettings.sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
      return effectiveSettings.first;
    }

    return null;
  }

  // Get all historical settings for a category
  List<FixedTransactionSetting> _getHistoricalSettings(CategoryWithSettings category) {
    final List<FixedTransactionSetting> settings = List.from(category.settings);
    settings.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
    return settings;
  }

  void _validateAmount(String value) {
    setState(() {
      if (value.isEmpty) {
        _isValidAmount = true;
        return;
      }

      final amount = double.tryParse(value);
      _isValidAmount = amount != null && amount > 0;
    });
  }

  void _showCategoryDetail(CategoryWithSettings category) {
    setState(() {
      _isDetailViewMode = true;
      _selectedCategory = category;
      _selectedHistoricalSettings = _getHistoricalSettings(category);
    });
  }

  void _exitDetailView() {
    setState(() {
      _isDetailViewMode = false;
      _selectedCategory = null;
      _selectedHistoricalSettings = null;
      _isDeleteMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(() {
            if (_controller.isLoadingExpense.value || _isLoadingTransactions) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.cate4),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '고정 지출 정보를 불러오는 중...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),

                        // Main content based on mode
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.1),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: _isCreateMode
                                ? _buildCreateForm()
                                : _isDetailViewMode
                                ? _isDeleteMode
                                ? _buildDeleteConfirmation()
                                : _buildCategoryDetailView()
                                : _buildCategoryList(),
                          ),
                        ),

                        // Bottom actions
                        _buildBottomActions(),
                      ],
                    ),

                    // Floating close button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: InkWell(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey[800],
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Header with title and statistics
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cate4.withOpacity(0.85),
            AppColors.cate4,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background design elements
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.money_off_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isDetailViewMode
                                ? (_selectedCategory?.name ?? '고정 지출 상세')
                                : '고정 지출 관리',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDetailViewMode
                                ? '지출 변경 이력 및 관리'
                                : '매월 반복되는 지출을 관리하세요',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Income stats summary - Only show when not in detail view
                if (!_isDetailViewMode && !_isCreateMode)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '등록된 고정 지출',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_controller.expenseCategories.length}개',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 36,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '총 월 지출',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _calculateTotalMonthlyExpense(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calculate total monthly expense based on current month
  String _calculateTotalMonthlyExpense() {
    double total = 0;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    for (final category in _controller.expenseCategories) {
      final effectiveSetting = _getEffectiveSettingForDate(category, currentMonth);
      if (effectiveSetting != null) {
        total += effectiveSetting.amount;
      }
    }

    return '₩ ${NumberFormat('#,###').format(total)}';
  }

  // Create form with calendar
  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cate4.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.cate4,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '새 고정 지출 추가',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Name field
            const Text(
              '지출 이름',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '예: 월세, 통신비, 구독료 등',
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: Icon(Icons.payment, color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.cate4, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '지출 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Amount field
            const Text(
              '금액',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                ThousandsFormatter(),
              ],
              // onChanged: (value) {
              //   // 콤마를 제거한 순수 숫자 값 얻기
              //   final plainValue = value.replaceAll(',', '');
              //
              //   setState(() {
              //     _isValidAmount = plainValue.isEmpty ||
              //         (double.tryParse(plainValue) != null &&
              //             double.parse(plainValue) > 0);
              //   });
              //
              //   // 숫자가 아닌 문자가 입력된 경우 즉시 경고 표시
              //   if (!RegExp(r'^[0-9,]*$').hasMatch(value)) {
              //     // 키보드가 열려 있으면 닫기
              //     FocusManager.instance.primaryFocus?.unfocus();
              //
              //     // 경고 메시지 표시
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       SnackBar(
              //         content: Row(
              //           children: [
              //             Icon(Icons.warning_amber_rounded, color: Colors.white),
              //             SizedBox(width: 10),
              //             Text('숫자만 입력 가능합니다'),
              //           ],
              //         ),
              //         backgroundColor: AppColors.cate4,
              //         behavior: SnackBarBehavior.floating,
              //         duration: Duration(seconds: 2),
              //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              //         margin: EdgeInsets.all(10),
              //       ),
              //     );
              //   }
              // },
              decoration: InputDecoration(
                hintText: '숫자만 입력',
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: Icon(Icons.money_off, color: AppColors.cate4),
                prefixText: '₩ ',
                prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _isValidAmount ? Colors.grey[200]! : Colors.red.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: _isValidAmount ? AppColors.cate4 : Colors.red.shade500,
                      width: 2
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                errorText: !_isValidAmount && _amountController.text.isNotEmpty
                    ? '유효한 금액을 입력해주세요'
                    : null,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '금액을 입력해주세요';
                }
                final amount = double.tryParse(value.replaceAll(',', ''));
                if (amount == null || amount <= 0) {
                  return '유효한 금액을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Effective from date
            const Text(
              '시작 날짜',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '설정한 날짜부터 지출이 등록됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),

            // Calendar for selecting effective from date
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy년 M월').format(_effectiveFromDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () {
                                setState(() {
                                  _effectiveFromDate = DateTime(
                                    _effectiveFromDate.year,
                                    _effectiveFromDate.month - 1,
                                    _effectiveFromDate.day,
                                  );
                                });
                              },
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                setState(() {
                                  _effectiveFromDate = DateTime(
                                    _effectiveFromDate.year,
                                    _effectiveFromDate.month + 1,
                                    _effectiveFromDate.day,
                                  );
                                });
                              },
                              iconSize: 24,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Calendar for create form
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _effectiveFromDate,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDate, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _effectiveFromDate = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      // Update the displayed month when swiping
                      setState(() {
                        _effectiveFromDate = focusedDay;
                      });
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.cate4.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: AppColors.cate4,
                        shape: BoxShape.circle,
                      ),
                    ),
                    availableGestures: AvailableGestures.none,
                    headerVisible: false,
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: '월',
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '선택한 날짜: ${DateFormat('yyyy년 M월 d일').format(_selectedDate)}부터 적용',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // List of fixed expense categories
  Widget _buildCategoryList() {
    if (_controller.expenseCategories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '등록된 고정 지출이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '새로운 고정 지출을 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('고정 지출 추가하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cate4,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  setState(() {
                    _isCreateMode = true;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: ListView.builder(
        itemCount: _controller.expenseCategories.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final category = _controller.expenseCategories[index];

          // Get current effective setting
          final currentSetting = _getEffectiveSettingForDate(category, currentMonth);

          // Get next scheduled setting if available
          FixedTransactionSetting? nextSetting;
          final futureSettings = category.settings
              .where((setting) => setting.effectiveFrom.isAfter(currentMonth))
              .toList();

          if (futureSettings.isNotEmpty) {
            futureSettings.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
            nextSetting = futureSettings.first;
          }

          // Display amount and date
          double? displayAmount;
          String displayDate = '';
          bool hasScheduledChange = false;

          if (currentSetting != null) {
            displayAmount = currentSetting.amount;
            displayDate = '매월 ${currentSetting.effectiveFrom.day}일';
            hasScheduledChange = nextSetting != null;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.red.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showCategoryDetail(category),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Category icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.cate4.withOpacity(0.8),
                                  AppColors.cate4,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cate4.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.money_off_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Title and date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  displayDate,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),

                                // Show notification of scheduled change if available
                                if (hasScheduledChange) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.amber.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '예정된 변경 있음',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade800,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (displayAmount != null)
                                Text(
                                  '₩ ${NumberFormat('#,###').format(displayAmount)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.cate4,
                                  ),
                                )
                              else
                                Text(
                                  '금액 미설정',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // View details button
                    Container(
                      width: double.infinity,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 16,
                            color: AppColors.cate4,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '기록 및 설정 보기',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.cate4,
                            ),
                          ),
                        ],
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

  // Category detail view with history
  Widget _buildCategoryDetailView() {
    if (_selectedCategory == null || _selectedHistoricalSettings == null) {
      return const Center(child: Text('데이터를 찾을 수 없습니다.'));
    }

    final category = _selectedCategory!;
    final settings = _selectedHistoricalSettings!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade50,
                  Colors.red.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.cate4,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.money_off,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '고정 지출 항목',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Current month settings display
                const Text(
                  '현재 설정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Display the current effective setting
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: '금액',
                        value: _getCurrentMonthAmount(category),
                        icon: Icons.money_off,
                        iconColor: AppColors.cate4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        title: '지출 날짜',
                        value: _getCurrentMonthDate(category),
                        icon: Icons.calendar_today,
                        iconColor: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // History title
          Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                '설정 변경 이력',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Settings history timeline
          settings.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '아직 변경 이력이 없습니다.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: settings.length,
            itemBuilder: (context, index) {
              final setting = settings[index];
              final isLastItem = index == settings.length - 1;
              final isFirstItem = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isFirstItem
                                  ? AppColors.cate4
                                  : AppColors.cate4.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLastItem)
                            Container(
                              width: 2,
                              height: 70,
                              color: Colors.red.shade200,
                            ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFirstItem
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirstItem
                                ? Colors.red.shade200
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('yyyy년 M월 d일부터').format(setting.effectiveFrom),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isFirstItem
                                        ? AppColors.cate4
                                        : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  isFirstItem ? '최신 설정' : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.cate4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Setting details
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '금액',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₩ ${NumberFormat('#,###').format(setting.amount)}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '날짜',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '매월 ${setting.effectiveFrom.day}일',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
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
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Get the amount for current month based on effective setting
  String _getCurrentMonthAmount(CategoryWithSettings category) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final effectiveSetting = _getEffectiveSettingForDate(category, currentMonth);

    if (effectiveSetting != null) {
      return '₩ ${NumberFormat('#,###').format(effectiveSetting.amount)}';
    }

    return '금액 미설정';
  }

  // Get the date for current month based on effective setting
  String _getCurrentMonthDate(CategoryWithSettings category) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final effectiveSetting = _getEffectiveSettingForDate(category, currentMonth);

    if (effectiveSetting != null) {
      return '매월 ${effectiveSetting.effectiveFrom.day}일';
    }

    return '날짜 미설정';
  }

  // Information card widget
  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Delete confirmation UI
  Widget _buildDeleteConfirmation() {
    if (_selectedCategory == null) {
      return const Center(child: Text('선택된 카테고리가 없습니다.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedCategory!.name} 삭제',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '특정 날짜 이후의 모든 기록이 삭제됩니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delete from date selector
          const Text(
            '삭제 시작일',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '선택한 날짜부터의 모든 기록이 삭제됩니다. 이전 데이터는 유지됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),

          // Calendar for selecting delete from date
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy년 M월').format(_deleteFromDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                _deleteFromDate = DateTime(
                                  _deleteFromDate.year,
                                  _deleteFromDate.month - 1,
                                  _deleteFromDate.day,
                                );
                              });
                            },
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                _deleteFromDate = DateTime(
                                  _deleteFromDate.year,
                                  _deleteFromDate.month + 1,
                                  _deleteFromDate.day,
                                );
                              });
                            },
                            iconSize: 24,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _deleteFromDate,
                  selectedDayPredicate: (day) {
                    return isSameDay(_deleteFromDate, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _deleteFromDate = selectedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.red.shade200,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.red.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
                  availableGestures: AvailableGestures.none,
                  headerVisible: false,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: '월',
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '삭제 시작일: ${DateFormat('yyyy년 M월 d일').format(_deleteFromDate)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Warning text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이 작업은 되돌릴 수 없습니다. 삭제된 데이터는 복구할 수 없습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isDeleteMode = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmDelete(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('삭제하기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom action buttons based on current mode
  Widget _buildBottomActions() {
    if (_isDetailViewMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            _isDeleteMode
                ? const SizedBox()
                : Expanded(
              child: ElevatedButton(
                onPressed: () => _showUpdateDialog(_selectedCategory!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cate4,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '새 설정 추가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (!_isDeleteMode) const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (_isDeleteMode) {
                    setState(() {
                      _isDeleteMode = false;
                    });
                  } else {
                    _exitDetailView();
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _isDeleteMode ? '취소' : '돌아가기',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (!_isDeleteMode) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isDeleteMode = true;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '삭제',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    } else if (_isCreateMode) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isCreateMode = false;
                    _nameController.clear();
                    _amountController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final amount = double.parse(_amountController.text.replaceAll(',', ''));

                    // Create the fixed transaction starting from the selected date
                    final success = await _controller.createNewFixedTransaction(
                      name: _nameController.text,
                      type: 'EXPENSE',
                      amount: amount,
                      effectiveFrom: _selectedDate,
                    );

                    if (success) {
                      setState(() {
                        _isCreateMode = false;
                        _nameController.clear();
                        _amountController.clear();
                      });

                      // Refresh data
                      await _loadTransactionHistory();

                      Get.snackbar(
                        '성공',
                        '고정 지출이 추가되었습니다',
                        backgroundColor: Colors.green[100],
                        borderRadius: 12,
                        margin: const EdgeInsets.all(12),
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      Get.snackbar(
                        '오류',
                        '이미 존재하는 이름이거나 추가 중 오류가 발생했습니다',
                        backgroundColor: Colors.red[100],
                        borderRadius: 12,
                        margin: const EdgeInsets.all(12),
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cate4,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '추가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('새 고정 지출 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cate4,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _isCreateMode = true;
                  });
                },
              ),
            ),
            if (_controller.expenseCategories.isNotEmpty) ...[
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text(
                  '닫기',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  // Show update dialog for adding a new setting
  void _showUpdateDialog(CategoryWithSettings category) {
    final TextEditingController amountController = TextEditingController();

    // Success state variables
    bool showSuccess = false;
    bool isLoading = false;

    // Get the last setting day
    int defaultDay = 1;
    double defaultAmount = 0;

    if (category.settings.isNotEmpty) {
      final latestSetting = category.settings.first;
      defaultDay = latestSetting.effectiveFrom.day;
      defaultAmount = latestSetting.amount;
      amountController.text = defaultAmount.toStringAsFixed(0);
    }

    // Set default date (current month with the default day)
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, defaultDay);
    DateTime effectiveFromDate = DateTime(now.year, now.month, 1);

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isValidAmount = amountController.text.isEmpty ||
                  (double.tryParse(amountController.text) != null &&
                      double.parse(amountController.text) > 0);

              return Container(
                width: 320,
                // 최대 높이 제약 추가 - 화면 높이의 70%로 제한
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.cate4.withOpacity(0.85),
                            AppColors.cate4,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '새 설정 추가',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      category.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Info text
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '새 설정은 선택한 날짜부터 적용되며, 이전 데이터는 유지됩니다.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content - Flexible로 감싸서 남은 공간을 차지하게 함
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Stack(
                          children: [
                            // Success overlay
                            if (showSuccess)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        border: Border.all(color: Colors.green.shade200, width: 1),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.green.shade700,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '저장 완료!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '설정이 성공적으로 적용되었습니다',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.green.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Loading overlay
                            if (isLoading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.cate4),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '저장 중...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.cate4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Main content
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Amount input
                                const Text(
                                  '새 금액',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: amountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                                    ThousandsFormatter(),
                                  ],
                                  // onChanged: (value) {
                                  //   // 콤마를 제거한 순수 숫자 값 얻기
                                  //   final plainValue = value.replaceAll(',', '');
                                  //
                                  //   // 유효성 검사
                                  //   setState(() {
                                  //     isValidAmount = plainValue.isEmpty || (int.tryParse(plainValue) != null && int.parse(plainValue) > 0);
                                  //   });
                                  //
                                  //   // 숫자가 아닌 문자가 입력된 경우 즉시 경고 표시
                                  //   if (!RegExp(r'^[0-9,]*$').hasMatch(value)) {
                                  //     showNumberFormatAlert(context);
                                  //   }
                                  // },
                                  decoration: InputDecoration(
                                    hintText: '금액 입력',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: Icon(Icons.attach_money, color: AppColors.cate4),
                                    prefixText: '₩ ',
                                    prefixStyle: const TextStyle(color: Colors.black87, fontSize: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: isValidAmount ? Colors.grey[200]! : Colors.red[300]!
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isValidAmount ? AppColors.cate4 : Colors.red[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    errorText: !isValidAmount && amountController.text.isNotEmpty
                                        ? '유효한 금액을 입력해주세요'
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Date selection
                                const Text(
                                  '적용 시작일',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '설정한 날짜부터 새 금액이 적용됩니다.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Calendar for selecting effective from date
                                // 캘린더 높이를 화면 크기에 따라 조정
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Month header with navigation
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('yyyy년 M월').format(effectiveFromDate),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_left),
                                                  onPressed: () {
                                                    setState(() {
                                                      effectiveFromDate = DateTime(
                                                        effectiveFromDate.year,
                                                        effectiveFromDate.month - 1,
                                                        1,
                                                      );
                                                    });
                                                  },
                                                  iconSize: 24,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const SizedBox(width: 16),
                                                IconButton(
                                                  icon: const Icon(Icons.chevron_right),
                                                  onPressed: () {
                                                    setState(() {
                                                      effectiveFromDate = DateTime(
                                                        effectiveFromDate.year,
                                                        effectiveFromDate.month + 1,
                                                        1,
                                                      );
                                                    });
                                                  },
                                                  iconSize: 24,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // 캘린더 크기를 기기 화면에 맞춰 조절
                                      SizedBox(
                                        // 최대 265, 최소 180으로 조정 (작은 화면에서도 동작)
                                        height: MediaQuery.of(context).size.height < 600 ? 180 :
                                        MediaQuery.of(context).size.height < 700 ? 220 : 265,
                                        child: TableCalendar(
                                          firstDay: DateTime.utc(2020, 1, 1),
                                          lastDay: DateTime.utc(2030, 12, 31),
                                          focusedDay: effectiveFromDate,
                                          selectedDayPredicate: (day) {
                                            return isSameDay(selectedDate, day);
                                          },
                                          onDaySelected: (selectedDay, focusedDay) {
                                            setState(() {
                                              selectedDate = selectedDay;
                                              effectiveFromDate = focusedDay;
                                            });
                                          },
                                          onPageChanged: (focusedDay) {
                                            setState(() {
                                              effectiveFromDate = focusedDay;
                                            });
                                          },
                                          calendarStyle: CalendarStyle(
                                            cellMargin: const EdgeInsets.all(2),
                                            cellPadding: const EdgeInsets.all(3),
                                            todayDecoration: BoxDecoration(
                                              color: AppColors.cate4.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            selectedDecoration: BoxDecoration(
                                              color: AppColors.cate4,
                                              shape: BoxShape.circle,
                                            ),
                                            defaultTextStyle: const TextStyle(fontSize: 13),
                                            weekendTextStyle: TextStyle(
                                              fontSize: 13,
                                              color: Colors.red.shade300,
                                            ),
                                            selectedTextStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            todayTextStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                            outsideTextStyle: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.withOpacity(0.5),
                                            ),
                                          ),
                                          availableGestures: AvailableGestures.none,
                                          headerVisible: false,
                                          calendarFormat: CalendarFormat.month,
                                          availableCalendarFormats: const {
                                            CalendarFormat.month: '월',
                                          },
                                          // 작은 화면에서 행 높이 줄이기
                                          rowHeight: MediaQuery.of(context).size.height < 700 ? 32 : 42,
                                          daysOfWeekHeight: 20,
                                          daysOfWeekStyle: DaysOfWeekStyle(
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                            ),
                                            weekdayStyle: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            weekendStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade300,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Info text at bottom
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '선택한 날짜: ${DateFormat('yyyy년 M월 d일').format(selectedDate)}부터 적용',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                          ],
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
                    ),

                    // Actions - 스크롤 영역 바깥에 고정
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cate4,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                // Validate inputs
                                final plainAmount = amountController.text.replaceAll(',', '');
                                final amount = double.tryParse(plainAmount);

                                if (amount == null || amount <= 0) {
                                  Get.snackbar('오류', '올바른 금액을 입력해주세요');
                                  return;
                                }

                                // Check if there's a change
                                if (amount == defaultAmount && selectedDate.day == defaultDay) {
                                  Get.snackbar('알림', '변경된 내용이 없습니다');
                                  return;
                                }

                                // Show loading indicator
                                setState(() {
                                  isLoading = true;
                                });

                                // Update the setting
                                final success = await _controller.updateFixedTransactionSetting(
                                  categoryId: category.id,
                                  amount: amount,
                                  effectiveFrom: selectedDate,
                                );

                                // Show result
                                if (success) {
                                  // Reload data
                                  await _controller.loadFixedExpenseCategories();

                                  // Find the updated category from the controller
                                  CategoryWithSettings? updatedCategory;
                                  for (var cat in _controller.expenseCategories) {
                                    if (cat.id == category.id) {
                                      updatedCategory = cat;
                                      break;
                                    }
                                  }

                                  // Update the parent state
                                  if (_selectedCategory != null && _selectedCategory!.id == category.id && updatedCategory != null) {
                                    // Update our parent widget's state to show the new setting immediately
                                    this.setState(() {
                                      _selectedCategory = updatedCategory;
                                      _selectedHistoricalSettings = _getHistoricalSettings(updatedCategory!);
                                    });
                                  }

                                  // Reload transaction history
                                  await _loadTransactionHistory();

                                  // Update dialog state with new values and show success indicator
                                  setState(() {
                                    defaultAmount = amount;
                                    defaultDay = selectedDate.day;
                                    amountController.text = amount.toStringAsFixed(0);
                                    showSuccess = true;
                                    isLoading = false;
                                  });

                                  // Show external snackbar
                                  Get.snackbar(
                                    '성공',
                                    '${category.name}의 설정이 ${DateFormat('yyyy년 M월 d일').format(selectedDate)}부터 ${NumberFormat('#,###').format(amount)}원으로 변경되었습니다.',
                                    backgroundColor: Colors.green[100],
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(12),
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );

                                  // Close the dialog after success message
                                  Future.delayed(const Duration(seconds: 1), () {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  });
                                } else {
                                  setState(() {
                                    isLoading = false;
                                  });

                                  Get.snackbar(
                                    '오류',
                                    '설정 업데이트에 실패했습니다.',
                                    backgroundColor: Colors.red[100],
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(12),
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              },
                              child: const Text(
                                '저장',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Helper function to show number format alert
  void showNumberFormatAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('숫자만 입력 가능합니다'),
          ],
        ),
        backgroundColor: AppColors.cate4,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  // Confirm deletion of fixed expense
  void _confirmDelete() async {
    if (_selectedCategory == null) return;

    try {
      final dbHelper = DBHelper();
      final db = await dbHelper.database;

      // 1. Get the category ID
      final categoryId = _selectedCategory!.id;

      // 2. Delete the settings after the selected date
      await db.delete(
        'fixed_transaction_setting',
        where: 'category_id = ? AND effective_from >= ?',
        whereArgs: [categoryId, _deleteFromDate.toIso8601String()],
      );

      // 3. Delete the transactions after the selected date
      await db.delete(
        'transaction_record2',
        where: 'category_id = ? AND transaction_date >= ?',
        whereArgs: [categoryId, _deleteFromDate.toIso8601String()],
      );

      // 4. Check if there are any remaining settings
      final remainingSettings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 5. If no remaining settings, mark the category as deleted
      if (remainingSettings.isEmpty) {
        await db.update(
          'category',
          {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [categoryId],
        );
      }

      // 6. Reload data
      await _controller.loadFixedExpenseCategories();
      await _loadTransactionHistory();

      // 7. Exit detail view
      setState(() {
        _isDetailViewMode = false;
        _isDeleteMode = false;
        _selectedCategory = null;
        _selectedHistoricalSettings = null;
      });

      // 8. Show success message
      Get.snackbar(
        '삭제 완료',
        '${_deleteFromDate.toString().substring(0, 10)} 이후의 ${_selectedCategory!.name} 고정 지출이 삭제되었습니다.',
        backgroundColor: Colors.green[100],
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      Get.snackbar(
        '오류',
        '삭제 중 문제가 발생했습니다: $e',
        backgroundColor: Colors.red[100],
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

// 확장 함수로 다이얼로그 표시 쉽게 만들기
extension FixedExpenseDialogExtension on GetInterface {
  Future<void> showFixedExpenseDialog() {
    return Get.dialog(
      const FixedExpenseDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}