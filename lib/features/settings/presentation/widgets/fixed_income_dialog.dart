import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../controllers/settings_controller.dart';
import 'package:table_calendar/table_calendar.dart';

class FixedIncomeDialog extends StatefulWidget {
  const FixedIncomeDialog({Key? key}) : super(key: key);

  @override
  State<FixedIncomeDialog> createState() => _FixedIncomeDialogState();
}

class _FixedIncomeDialogState extends State<FixedIncomeDialog> with SingleTickerProviderStateMixin {
  late final SettingsController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Map to cache latest transactions for categories without settings
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

    for (final category in _controller.incomeCategories) {
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
            if (_controller.isLoadingIncome.value || _isLoadingTransactions) {
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '고정 소득 정보를 불러오는 중...',
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
            Colors.green.shade600,
            Colors.green.shade800,
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
                        Icons.attach_money_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDetailViewMode
                              ? (_selectedCategory?.name ?? '고정 소득 상세')
                              : '고정 소득 관리',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDetailViewMode
                              ? '소득 변경 이력 및 관리'
                              : '매월 반복되는 소득을 관리하세요',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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
                                  '등록된 고정 소득',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_controller.incomeCategories.length}개',
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
                                    '총 월 소득',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _calculateTotalMonthlyIncome(),
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

  // Calculate total monthly income based on current month
  String _calculateTotalMonthlyIncome() {
    double total = 0;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);

    for (final category in _controller.incomeCategories) {
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
                    color: Colors.green.shade700.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '새 고정 소득 추가',
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
              '소득 이름',
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
                hintText: '예: 월급, 용돈 등',
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: Icon(Icons.account_balance_wallet, color: Colors.grey[600]),
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
                  borderSide: BorderSide(color: Colors.green.shade700, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '소득 이름을 입력해주세요';
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
              keyboardType: TextInputType.number,
              onChanged: _validateAmount,
              decoration: InputDecoration(
                hintText: '숫자만 입력',
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
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
                      color: _isValidAmount ? Colors.green.shade700 : Colors.red.shade500,
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
                final amount = double.tryParse(value);
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
              '설정한 날짜부터 소득이 등록됩니다.',
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
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.green.shade200,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                      ),
                    ),
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

  // List of fixed income categories
  Widget _buildCategoryList() {
    if (_controller.incomeCategories.isEmpty) {
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
                '등록된 고정 소득이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '새로운 고정 소득을 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('고정 소득 추가하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
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
        itemCount: _controller.incomeCategories.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final category = _controller.incomeCategories[index];

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
                  Colors.green.shade50,
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
                                  Colors.green.shade400,
                                  Colors.green.shade700,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade300.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.attach_money_rounded,
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
                                    color: Colors.green.shade700,
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
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '기록 및 설정 보기',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
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
                  Colors.green.shade50,
                  Colors.green.shade100,
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
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.attach_money,
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
                            '고정 소득 항목',
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
                        icon: Icons.attach_money,
                        iconColor: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        title: '받는 날짜',
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
                                  ? Colors.green.shade700
                                  : Colors.green.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLastItem)
                            Container(
                              width: 2,
                              height: 70,
                              color: Colors.green.shade200,
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
                              ? Colors.green.shade50
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFirstItem
                                ? Colors.green.shade200
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
                                        ? Colors.green.shade700
                                        : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  isFirstItem ? '최신 설정' : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
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
                  backgroundColor: Colors.green.shade700,
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
                    final amount = double.parse(_amountController.text);

                    // Create the fixed transaction starting from the selected date
                    final success = await _controller.createNewFixedTransaction(
                      name: _nameController.text,
                      type: 'INCOME',
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
                        '고정 소득이 추가되었습니다',
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
                  backgroundColor: Colors.green.shade700,
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
                label: const Text('새 고정 소득 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
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
            if (_controller.incomeCategories.isNotEmpty) ...[
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
    final TextEditingController dayController = TextEditingController();

    // Get the last setting day
    int defaultDay = 1;
    double defaultAmount = 0;

    if (category.settings.isNotEmpty) {
      final latestSetting = category.settings.first;
      defaultDay = latestSetting.effectiveFrom.day;
      defaultAmount = latestSetting.amount;
      amountController.text = defaultAmount.toStringAsFixed(0);
    }

    dayController.text = defaultDay.toString();

    // Set default date (current month with the default day)
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, defaultDay);

    // For effective month selection
    int selectedYear = now.year;
    int selectedMonth = now.month;

    // Create date from selected values
    void updateSelectedDate() {
      // Make sure day is valid for the month
      int day = int.tryParse(dayController.text) ?? defaultDay;
      int maxDaysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
      if (day > maxDaysInMonth) day = maxDaysInMonth;

      selectedDate = DateTime(selectedYear, selectedMonth, day);
    }

    showDialog(
      context: context,
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

              bool isValidDay = dayController.text.isEmpty ||
                  (int.tryParse(dayController.text) != null &&
                      int.parse(dayController.text) > 0 &&
                      int.parse(dayController.text) <= 31);

              return Container(
                width: 320,
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
                            Colors.green.shade600,
                            Colors.green.shade800,
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

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
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
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '금액 입력',
                              filled: true,
                              fillColor: Colors.grey[50],
                              prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
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
                                  color: isValidAmount ? Colors.green.shade700 : Colors.red[400]!,
                                  width: 2,
                                ),
                              ),
                              errorText: !isValidAmount ? '유효한 금액을 입력해주세요' : null,
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
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
                          const SizedBox(height: 8),

                          // Year/Month selection row
                          Row(
                            children: [
                              // Year dropdown
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedYear,
                                      items: List.generate(11, (index) {
                                        final year = DateTime.now().year - 5 + index;
                                        return DropdownMenuItem(
                                          value: year,
                                          child: Text(
                                            '$year년',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedYear = value;
                                            updateSelectedDate();
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.arrow_drop_down),
                                      isExpanded: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Month dropdown
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: selectedMonth,
                                      items: List.generate(12, (index) {
                                        return DropdownMenuItem(
                                          value: index + 1,
                                          child: Text(
                                            '${index + 1}월',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        );
                                      }),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedMonth = value;
                                            updateSelectedDate();
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.arrow_drop_down),
                                      isExpanded: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Day input
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: dayController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '일',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: isValidDay ? Colors.grey[200]! : Colors.red[300]!
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isValidDay ? Colors.green.shade700 : Colors.red[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    errorText: !isValidDay ? '!' : null,
                                    errorStyle: const TextStyle(
                                      height: 0,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value.isNotEmpty && int.tryParse(value) != null) {
                                        updateSelectedDate();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date preview
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedYear}년 ${selectedMonth}월 ${int.tryParse(dayController.text) ?? defaultDay}일부터 적용',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
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
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                // Validate inputs
                                final amount = double.tryParse(amountController.text);
                                final day = int.tryParse(dayController.text);

                                if (amount == null || amount <= 0) {
                                  Get.snackbar('오류', '올바른 금액을 입력해주세요');
                                  return;
                                }

                                if (day == null || day <= 0 || day > 31) {
                                  Get.snackbar('오류', '올바른 날짜를 입력해주세요');
                                  return;
                                }

                                // Validate date
                                final maxDaysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
                                if (day > maxDaysInMonth) {
                                  Get.snackbar('오류', '$selectedMonth월은 $maxDaysInMonth일까지만 있습니다.');
                                  return;
                                }

                                // Update selected date with validated day
                                final validatedDate = DateTime(selectedYear, selectedMonth, day);

                                // Check if there's a change
                                if (amount == defaultAmount && validatedDate.day == defaultDay) {
                                  Get.snackbar('알림', '변경된 내용이 없습니다');
                                  Navigator.pop(context);
                                  return;
                                }

                                // Update the setting
                                final success = await _controller.updateFixedTransactionSetting(
                                  categoryId: category.id,
                                  amount: amount,
                                  effectiveFrom: validatedDate,
                                );

                                // Close dialog
                                Navigator.pop(context);

                                // Show result
                                if (success) {
                                  // Reload data
                                  await _controller.loadFixedIncomeCategories();
                                  await _loadTransactionHistory();

                                  // Refresh the selected category settings if in detail view
                                  if (_selectedCategory != null && _selectedCategory!.id == category.id) {
                                    setState(() {
                                      _selectedHistoricalSettings = _getHistoricalSettings(category);
                                    });
                                  }

                                  Get.snackbar(
                                    '성공',
                                    '${category.name}의 설정이 ${DateFormat('yyyy년 M월 d일').format(validatedDate)}부터 ${NumberFormat('#,###').format(amount)}원으로 변경되었습니다.',
                                    backgroundColor: Colors.green[100],
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(12),
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );
                                } else {
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

  // Confirm deletion of fixed income
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
      await _controller.loadFixedIncomeCategories();
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
        '${_deleteFromDate.toString().substring(0, 10)} 이후의 ${_selectedCategory!.name} 고정 소득이 삭제되었습니다.',
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
extension FixedIncomeDialogExtension on GetInterface {
  Future<void> showFixedIncomeDialog() {
    return Get.dialog(
      const FixedIncomeDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}