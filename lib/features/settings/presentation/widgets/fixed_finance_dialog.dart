import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../../../core/util/thousands_formatter.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../controllers/settings_controller.dart';
import 'package:table_calendar/table_calendar.dart';

class SettingHistoryItem {
  final String id;
  final double amount;
  final int day;
  final DateTime effectiveFrom;
  final bool isGlobalSetting;
  final bool isCurrentSetting;

  SettingHistoryItem({
    required this.id,
    required this.amount,
    required this.day,
    required this.effectiveFrom,
    required this.isGlobalSetting,
    this.isCurrentSetting = false,
  });
}

class FixedFinanceDialog extends StatefulWidget {
  const FixedFinanceDialog({Key? key}) : super(key: key);

  @override
  State<FixedFinanceDialog> createState() => _FixedFinanceDialogState();
}

class _FixedFinanceDialogState extends State<FixedFinanceDialog> with SingleTickerProviderStateMixin {
  late final SettingsController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Finance color theme - using theme controller for consistency

  // Map to cache latest transactions for categories without settings
  final Map<int, List<Map<String, dynamic>>> _categoryTransactionHistory = {};
  bool _isLoadingTransactions = true;

  // Create mode
  bool _isCreateMode = false;

  // Detail view mode
  bool _isDetailViewMode = false;
  CategoryWithSettings? _selectedCategory;
  List<SettingHistoryItem>? _selectedHistoricalSettings;

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

  // Helper method to show delete confirmation dialog
  Future<bool?> _showDeleteConfirmDialog(SettingHistoryItem item) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('설정 삭제'),
          content: Text(
            '${DateFormat('yyyy년 M월 d일').format(item.effectiveFrom)}부터 적용된 설정을 삭제하시겠습니까?'
                '\n\n삭제 후에는 이전 설정이 적용됩니다.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(
                '삭제',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to perform the actual delete operation
  Future<void> _performDeleteSetting(SettingHistoryItem item, List<SettingHistoryItem> historyItems) async {
    try {
      // Extract the ID from the prefix
      final idString = item.id.split('_')[1];
      final id = int.parse(idString);

      // 데이터베이스에서 실제 삭제 작업 수행
      await _deleteFixedTransactionSetting(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("삭제 중 오류가 발생했습니다: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load transaction history for each category
  Future<void> _loadTransactionHistory() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    final dbHelper = DBHelper();
    final db = await dbHelper.database;

    for (final category in _controller.financeCategories) {
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
  List<SettingHistoryItem> _getHistoricalSettings(CategoryWithSettings category) {
    final List<SettingHistoryItem> historyItems = [];

    // Add the transaction record as the initial "global" setting if available
    final transactionRecords = _categoryTransactionHistory[category.id] ?? [];

    // Find the earliest transaction record
    Map<String, dynamic>? earliestTransaction;
    for (final record in transactionRecords) {
      if (record.containsKey('transaction_date')) {
        if (earliestTransaction == null || DateTime.parse(record['transaction_date'].toString())
            .isBefore(DateTime.parse(earliestTransaction['transaction_date'].toString()))) {
          earliestTransaction = record;
        }
      }
    }

    // Check if there are only transaction records without fixed settings
    final bool onlyTransactionRecords = category.settings.isEmpty && earliestTransaction != null;

    // Add the global setting from transaction record if available
    if (earliestTransaction != null) {
      historyItems.add(SettingHistoryItem(
        id: 'global_${earliestTransaction['id']}',
        amount: (earliestTransaction['amount'] is String)
            ? double.parse(earliestTransaction['amount'])
            : earliestTransaction['amount'],
        day: (earliestTransaction['transaction_num'] is String)
            ? int.parse(earliestTransaction['transaction_num'])
            : earliestTransaction['transaction_num'],
        effectiveFrom: DateTime.parse(earliestTransaction['transaction_date'].toString()),
        isGlobalSetting: true,
        // If this is the only setting (no fixed_transaction_setting data), it should be the current setting
        isCurrentSetting: onlyTransactionRecords,
      ));
    }

    // Add all fixed transaction settings
    for (final setting in category.settings) {
      historyItems.add(SettingHistoryItem(
        id: 'setting_${setting.id}',
        amount: setting.amount,
        day: setting.effectiveFrom.day,
        effectiveFrom: setting.effectiveFrom,
        isGlobalSetting: false,
      ));
    }

    // Sort by effective from date
    historyItems.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

    return historyItems;
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

  void showNumberFormatAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Text('숫자만 입력 가능합니다'),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
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
            if (_controller.isLoadingFinance.value || _isLoadingTransactions) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 300,
                decoration: BoxDecoration(
                  color: themeController.cardColor,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Get.find<ThemeController>().financeColor),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '고정 금융 정보를 불러오는 중...',
                        style: TextStyle(
                          fontSize: 16,
                          color: themeController.textSecondaryColor,
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
                color: themeController.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: themeController.isDarkMode
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.2),
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
            Get.find<ThemeController>().financeColor,
            Get.find<ThemeController>().financeColor.withOpacity(0.8),
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
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.credit_card_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDetailViewMode
                              ? (_selectedCategory?.name ?? '고정 금융 상세')
                              : '고정 금융 관리',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isDetailViewMode
                              ? '금융 변경 이력 및 관리'
                              : '매월 반복되는 금융을 관리하세요',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Income stats summary - Only show when not in detail view
                if (!_isDetailViewMode && !_isCreateMode)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(10),
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
                                  '등록된 고정 금융',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_controller.financeCategories.length}개',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '총 월 금융',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _calculateTotalMonthlyIncome(),
                                    style: const TextStyle(
                                      fontSize: 14,
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
                const SizedBox(height: 6),
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

    for (final category in _controller.financeCategories) {
      // fixed_transaction_setting에 설정이 있는지 확인
      final effectiveSetting = _getEffectiveSettingForDate(category, now);
      if (effectiveSetting != null) {
        total += effectiveSetting.amount;
      } else {
        // transaction_record2에서 데이터 찾기
        final transactionRecords = _categoryTransactionHistory[category.id] ?? [];
        Map<String, dynamic>? earliestTransaction;

        for (final record in transactionRecords) {
          if (record.containsKey('transaction_date') && record.containsKey('transaction_num')) {
            if (earliestTransaction == null) {
              earliestTransaction = record;
            } else {
              final currentDate = DateTime.parse(record['transaction_date'].toString());
              final earliestDate = DateTime.parse(earliestTransaction['transaction_date'].toString());
              if (currentDate.isBefore(earliestDate)) {
                earliestTransaction = record;
              }
            }
          }
        }

        if (earliestTransaction != null) {
          final amount = (earliestTransaction['amount'] is String)
              ? double.parse(earliestTransaction['amount'])
              : earliestTransaction['amount'];
          total += amount;
        }
      }
    }

    return '₩ ${NumberFormat('#,###').format(total)}';
  }

  // Create form with calendar - now with proper scrolling
  Widget _buildCreateForm() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Get.find<ThemeController>().financeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      color: Get.find<ThemeController>().financeColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '새 고정 금융 추가',
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
                '금융 이름',
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
                    borderSide: BorderSide(color: Get.find<ThemeController>().financeColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '금융 이름을 입력해주세요';
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
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
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
                //   // 숫자와 콤마 외의 문자가 입력된 경우에만 경고 표시
                //   if (value.isNotEmpty && !RegExp(r'^[0-9,]*$').hasMatch(value)) {
                //     // 키보드가 열려 있으면 닫기
                //     FocusManager.instance.primaryFocus?.unfocus();
                //
                //     // 경고 메시지 표시
                //     showNumberFormatAlert(context);
                //   }
                // },
                decoration: InputDecoration(
                  hintText: '숫자만 입력',
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.account_balance, color: Colors.green),
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
                        color: _isValidAmount ? Get.find<ThemeController>().financeColor : Colors.red.shade500,
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
                '설정한 날짜부터 금융이 등록됩니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Calendar for selecting effective from date
              Container(
                decoration: BoxDecoration(
                  color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeController.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    // Calendar for create form with fixed height to prevent overflow
                    SizedBox(
                      height: 300,
                      child: Material(
                        color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TableCalendar(
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
                          setState(() {
                            _effectiveFromDate = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Get.find<ThemeController>().financeColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Get.find<ThemeController>().financeColor,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(color: themeController.textPrimaryColor),
                          weekendTextStyle: TextStyle(color: themeController.textPrimaryColor),
                          outsideTextStyle: TextStyle(color: themeController.textSecondaryColor),
                        ),
                        headerVisible: false,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: '월',
                        },
                        // 여기에 추가 👇
                        availableGestures: AvailableGestures.none,
                        rowHeight: 40,
                        daysOfWeekHeight: 20,
                        ),
                      ),
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
              const SizedBox(height: 24), // Add extra padding at the bottom
            ],
          ),
        ),
      ),
    );
  }

  // List of fixed income categories
  Widget _buildCategoryList() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    if (_controller.financeCategories.isEmpty) {
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
                '등록된 고정 금융이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '새로운 고정 금융을 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('고정 금융 추가하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.find<ThemeController>().financeColor,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListView.builder(
        itemCount: _controller.financeCategories.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final category = _controller.financeCategories[index];

          // 1. 먼저 fixed_transaction_setting에서 현재 유효한 설정을 찾음
          final currentSetting = _getEffectiveSettingForDate(category, now);

          // 2. 다음 예정된 설정이 있는지 확인
          FixedTransactionSetting? nextSetting;
          final futureSettings = category.settings
              .where((setting) => setting.effectiveFrom.isAfter(now))
              .toList();

          if (futureSettings.isNotEmpty) {
            futureSettings.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
            nextSetting = futureSettings.first;
          }

          // 3. 표시할 금액과 날짜 정보 초기화
          double? displayAmount;
          String displayDate = '';
          bool hasScheduledChange = false;

          // 4. fixed_transaction_setting에 설정이 있으면 해당 값 사용
          if (currentSetting != null) {
            displayAmount = currentSetting.amount;
            displayDate = '매월 ${currentSetting.effectiveFrom.day}일';
            hasScheduledChange = nextSetting != null;
          }
          // 5. fixed_transaction_setting에 설정이 없으면 transaction_record2 확인
          else {
            // transaction_record2 데이터 확인
            final transactionRecords = _categoryTransactionHistory[category.id] ?? [];
            Map<String, dynamic>? earliestTransaction;

            for (final record in transactionRecords) {
              if (record.containsKey('transaction_date')) {
                // transaction_record2 테이블의 레코드인 경우만 확인
                if (record.containsKey('transaction_num')) {
                  if (earliestTransaction == null) {
                    earliestTransaction = record;
                  } else {
                    final currentDate = DateTime.parse(record['transaction_date'].toString());
                    final earliestDate = DateTime.parse(earliestTransaction['transaction_date'].toString());
                    if (currentDate.isBefore(earliestDate)) {
                      earliestTransaction = record;
                    }
                  }
                }
              }
            }

            // 기본 설정값이 있으면 사용
            if (earliestTransaction != null) {
              displayAmount = (earliestTransaction['amount'] is String)
                  ? double.parse(earliestTransaction['amount'])
                  : earliestTransaction['amount'];

              final day = (earliestTransaction['transaction_num'] is String)
                  ? int.parse(earliestTransaction['transaction_num'])
                  : earliestTransaction['transaction_num'];

              displayDate = '매월 ${day}일';
              hasScheduledChange = nextSetting != null;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Get.find<ThemeController>().financeColor.withOpacity(0.1),
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
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Category icon
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.green.shade400,
                                  Get.find<ThemeController>().financeColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.shade300.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Title and date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayDate.isEmpty ? '날짜 미설정' : displayDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),

                                // Show notification of scheduled change if available
                                if (hasScheduledChange) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
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
                                          size: 12,
                                          color: Colors.amber.shade800,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '예정된 변경 있음',
                                          style: TextStyle(
                                            fontSize: 10,
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

                          // Amount - 더 많은 공간 확보
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (displayAmount != null)
                                  Text(
                                    '₩ ${NumberFormat('#,###').format(displayAmount)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Get.find<ThemeController>().financeColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.end,
                                  )
                                else
                                  Text(
                                    '금액 미설정',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // View details button
                    Container(
                      width: double.infinity,
                      height: 36,
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
                            size: 14,
                            color: Get.find<ThemeController>().financeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '기록 및 설정 보기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Get.find<ThemeController>().financeColor,
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
    if (_selectedCategory == null) {
      return const Center(child: Text('데이터를 찾을 수 없습니다.'));
    }

    final category = _selectedCategory!;
    final historyItems = _getHistoricalSettings(category);

    // Find current effective setting
    final now = DateTime.now();
    SettingHistoryItem? currentSetting;

    for (int i = historyItems.length - 1; i >= 0; i--) {
      if (historyItems[i].effectiveFrom.isBefore(now) ||
          historyItems[i].effectiveFrom.isAtSameMomentAs(now)) {
        currentSetting = historyItems[i];
        break;
      }
    }

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
                  Get.find<ThemeController>().financeColor.withOpacity(0.1),
                  Get.find<ThemeController>().financeColor.withOpacity(0.2),
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
                        color: Get.find<ThemeController>().financeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
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
                            '고정 금융 항목',
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

                // Display the current effective setting in column layout
                Column(
                  children: [
                    _buildInfoCard(
                      title: '금액',
                      value: currentSetting != null
                          ? '₩ ${NumberFormat('#,###').format(currentSetting.amount)}'
                          : '금액 미설정',
                      icon: Icons.account_balance,
                      iconColor: Get.find<ThemeController>().financeColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      title: '받는 날짜',
                      value: currentSetting != null
                          ? '매월 ${currentSetting.day}일'
                          : '날짜 미설정',
                      icon: Icons.calendar_today,
                      iconColor: Get.find<ThemeController>().financeColor,
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
              const Spacer(),
              Text(
                '오른쪽으로 스와이프하여 삭제',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Settings history timeline with swipe-to-delete
          historyItems.isEmpty
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
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              final item = historyItems[index];
              final isFirstItem = index == 0;
              final isLastItem = index == historyItems.length - 1;
              // Use the item's isCurrentSetting property if it's a global setting with transaction_record2 only,
              // otherwise use the currentSetting check
              final isCurrentSetting = item.isCurrentSetting || currentSetting?.id == item.id;

              // Don't allow deleting the global/initial setting
              if (item.isGlobalSetting) {
                return _buildHistoryItem(
                  item: item,
                  isFirstItem: isFirstItem,
                  isLastItem: isLastItem,
                  isCurrentSetting: isCurrentSetting,
                );
              }

              // For fixed transaction settings, allow swipe to delete
              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (direction) async {
                  return await _showDeleteConfirmDialog(item);
                },
                onDismissed: (direction) async {
                  await _performDeleteSetting(item, historyItems);
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete_sweep,
                    color: Colors.red.shade700,
                  ),
                ),
                child: GestureDetector(
                  onLongPress: () async {
                    final shouldDelete = await _showDeleteConfirmDialog(item);
                    if (shouldDelete == true) {
                      setState(() {
                        historyItems.removeWhere((setting) => setting.id == item.id);
                      });
                      await _performDeleteSetting(item, historyItems);
                    }
                  },
                  child: _buildHistoryItem(
                    item: item,
                    isFirstItem: isFirstItem,
                    isLastItem: isLastItem,
                    isCurrentSetting: isCurrentSetting,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required SettingHistoryItem item,
    required bool isFirstItem,
    required bool isLastItem,
    required bool isCurrentSetting,
  }) {
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
                    color: isCurrentSetting
                        ? Get.find<ThemeController>().financeColor
                        : Colors.green.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLastItem)
                  Container(
                    width: 2,
                    height: 70,
                    color: Get.find<ThemeController>().financeColor.withOpacity(0.4),
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
                color: isCurrentSetting
                    ? Get.find<ThemeController>().financeColor.withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentSetting
                      ? Get.find<ThemeController>().financeColor.withOpacity(0.4)
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
                        item.isGlobalSetting
                            ? '전체 설정'
                            : DateFormat('yyyy년 M월 d일부터').format(item.effectiveFrom),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentSetting
                              ? Get.find<ThemeController>().financeColor
                              : Colors.grey[700],
                        ),
                      ),
                      Text(
                        isCurrentSetting ? '현재 설정' : '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Get.find<ThemeController>().financeColor,
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
                              '₩ ${NumberFormat('#,###').format(item.amount)}',
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
                              '매월 ${item.day}일',
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
  }

// Add the method to delete a fixed transaction setting
  Future<void> _deleteFixedTransactionSetting(int settingId) async {
    try {
      // 로딩 표시
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
        barrierDismissible: false,
      );

      final dbHelper = DBHelper();
      final db = await dbHelper.database;

      // 설정 삭제
      await db.delete(
        'fixed_transaction_setting',
        where: 'id = ?',
        whereArgs: [settingId],
      );

      // 데이터 리로드
      await _controller.loadFixedFinanceCategories();
      await _loadTransactionHistory();

      // 로딩 다이얼로그 닫기
      Get.back();

      // 선택된 카테고리 및 이력 업데이트
      if (_selectedCategory != null) {
        final categoryId = _selectedCategory!.id;
        CategoryWithSettings? updatedCategory;

        for (var cat in _controller.financeCategories) {
          if (cat.id == categoryId) {
            updatedCategory = cat;
            break;
          }
        }

        if (updatedCategory != null) {
          setState(() {
            _selectedCategory = updatedCategory;
            _selectedHistoricalSettings = null; // 다시 _getHistoricalSettings로 구성됨
          });
        }
      }

      // 이벤트 발생 - EventBusService 사용
      Get.find<EventBusService>().emitFixedIncomeChanged();

      // 성공 메시지 표시
      final ThemeController themeController = Get.find<ThemeController>();
      Get.snackbar(
        '삭제 완료',
        '설정이 성공적으로 삭제되었습니다.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 오류 메시지 표시
      final ThemeController themeController = Get.find<ThemeController>();
      Get.snackbar(
        '오류',
        '설정 삭제 중 문제가 발생했습니다: $e',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Get the amount for current month based on effective setting
  String _getCurrentMonthAmount(CategoryWithSettings category) {
    final now = DateTime.now(); // Use current date instead of first day of month
    final effectiveSetting = _getEffectiveSettingForDate(category, now);

    if (effectiveSetting != null) {
      return '₩ ${NumberFormat('#,###').format(effectiveSetting.amount)}';
    }

    return '금액 미설정';
  }

  // Get the date for current month based on effective setting
  String _getCurrentMonthDate(CategoryWithSettings category) {
    final now = DateTime.now(); // Use current date instead of first day of month
    final effectiveSetting = _getEffectiveSettingForDate(category, now);

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
    final ThemeController themeController = Get.find<ThemeController>();
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
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: themeController.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                  ),
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
                    // Fixed height calendar to prevent overflow
                    SizedBox(
                      height: 280,
                      child: Material(
                        color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TableCalendar(
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
                            color: themeController.isDarkMode ? Colors.red.shade400.withOpacity(0.3) : Colors.red.shade200,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: themeController.isDarkMode ? Colors.red.shade400 : Colors.red.shade600,
                            shape: BoxShape.circle,
                          ),
                          defaultTextStyle: TextStyle(color: themeController.textPrimaryColor),
                          weekendTextStyle: TextStyle(color: themeController.textPrimaryColor),
                          outsideTextStyle: TextStyle(color: themeController.textSecondaryColor),
                        ),
                        headerVisible: false,
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: '월',
                        },
                        // Make calendar more compact
                        availableGestures: AvailableGestures.none,
                        rowHeight: 40,
                        daysOfWeekHeight: 20,
                        ),
                      ),
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
        ],
      ),
    );
  }

  // Bottom action buttons based on current mode
  Widget _buildBottomActions() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    if (_isDetailViewMode) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeController.cardColor,
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
                  backgroundColor: Get.find<ThemeController>().financeColor,
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
                  side: BorderSide(
                    color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _isDeleteMode ? '취소' : '돌아가기',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeController.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (!_isDeleteMode) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  _confirmDeleteAllData();  // 기존의 _isDeleteMode = true 대신 새로운 메서드 호출
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeController.cardColor,
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
                  side: BorderSide(
                    color: themeController.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeController.textSecondaryColor,
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
                      type: 'FINANCE',
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

                      final ThemeController themeController = Get.find<ThemeController>();
                      Get.snackbar(
                        '성공',
                        '고정 금융이 추가되었습니다',
                        backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(12),
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      final ThemeController themeController = Get.find<ThemeController>();
                      Get.snackbar(
                        '오류',
                        '이미 존재하는 이름이거나 추가 중 오류가 발생했습니다',
                        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(12),
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.find<ThemeController>().financeColor,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeController.cardColor,
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
                label: const Text('새 고정 금융 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.find<ThemeController>().financeColor,
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
            if (_controller.financeCategories.isNotEmpty) ...[
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
                    color: themeController.textSecondaryColor,
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

  void _confirmDeleteAllData() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    if (_selectedCategory == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeController.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '${_selectedCategory!.name} 완전히 삭제',
          style: TextStyle(
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 고정 금융 항목을 완전히 삭제하시겠습니까?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '주의:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 이 항목의 모든 과거 기록이 삭제됩니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 모든 설정 이력이 삭제됩니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• 이 작업은 되돌릴 수 없습니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllCategoryData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '완전히 삭제',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  Future<void> _deleteAllCategoryData() async {
    final ThemeController themeController = Get.find<ThemeController>();
    
    if (_selectedCategory == null) return;

    try {
      // 로딩 표시
      Get.dialog(
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeController.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade700),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '삭제 중...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final dbHelper = DBHelper();
      final db = await dbHelper.database;
      final categoryId = _selectedCategory!.id;

      // 1. fixed_transaction_setting 테이블에서 모든 설정 삭제
      await db.delete(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 2. transaction_record2 테이블에서 모든 거래 기록 삭제
      await db.delete(
        'transaction_record2',
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 3. category 테이블에서 카테고리 자체를 삭제 (또는 is_deleted 플래그 설정)
      await db.delete(
        'category',
        where: 'id = ?',
        whereArgs: [categoryId],
      );

      // 4. 데이터 다시 로드
      await _controller.loadFixedFinanceCategories();
      await _loadTransactionHistory();

      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 상세 보기 화면 닫기
      setState(() {
        _isDetailViewMode = false;
        _selectedCategory = null;
        _selectedHistoricalSettings = null;
        _isDeleteMode = false;
      });

      // 이벤트 발생 - EventBusService 사용
      Get.find<EventBusService>().emitFixedIncomeChanged();

      // 성공 메시지 표시
      Get.snackbar(
        '삭제 완료',
        '${_selectedCategory?.name ?? "고정 금융"} 항목이 완전히 삭제되었습니다.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 오류 메시지 표시
      final ThemeController themeController = Get.find<ThemeController>();
      Get.snackbar(
        '오류',
        '삭제 중 문제가 발생했습니다: $e',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Show update dialog for adding a new setting
  void _showUpdateDialog(CategoryWithSettings category) {
    final ThemeController themeController = Get.find<ThemeController>();
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
          backgroundColor: themeController.cardColor,
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
                // 최대 높이 제약 추가 - 화면 높이의 80%로 제한
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
                            Colors.blue.shade600,
                            Get.find<ThemeController>().financeColor,
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
                                        color: Get.find<ThemeController>().financeColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                        border: Border.all(color: Get.find<ThemeController>().financeColor.withOpacity(0.4), width: 1),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Get.find<ThemeController>().financeColor.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: Get.find<ThemeController>().financeColor,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '저장 완료!',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Get.find<ThemeController>().financeColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '설정이 성공적으로 적용되었습니다',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Get.find<ThemeController>().financeColor,
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
                                            valueColor: AlwaysStoppedAnimation<Color>(Get.find<ThemeController>().financeColor),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '저장 중...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Get.find<ThemeController>().financeColor,
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
                                  //   // 유효성 검사 - 반드시 콤마가 제거된 값으로만 검사
                                  //   setState(() {
                                  //     isValidAmount = plainValue.isEmpty || (double.tryParse(plainValue) != null && double.parse(plainValue) > 0);
                                  //   });
                                  //
                                  //   // 숫자와 콤마 외의 문자가 입력된 경우에만 경고 표시
                                  //   if (value.isNotEmpty && !RegExp(r'^[0-9,]*$').hasMatch(value)) {
                                  //     showNumberFormatAlert(context);
                                  //   }
                                  // },
                                  decoration: InputDecoration(
                                    hintText: '금액 입력',
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    prefixIcon: const Icon(Icons.account_balance, color: Colors.green),
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
                                        color: isValidAmount ? Get.find<ThemeController>().financeColor : Colors.red[400]!,
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
                                        child: Material(
                                          color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
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
                                              color: Get.find<ThemeController>().financeColor.withOpacity(0.3),
                                              shape: BoxShape.circle,
                                            ),
                                            selectedDecoration: BoxDecoration(
                                              color: Get.find<ThemeController>().financeColor,
                                              shape: BoxShape.circle,
                                            ),
                                            defaultTextStyle: TextStyle(fontSize: 13, color: themeController.textPrimaryColor),
                                            weekendTextStyle: TextStyle(
                                              fontSize: 13,
                                              color: themeController.textPrimaryColor,
                                            ),
                                            outsideTextStyle: TextStyle(fontSize: 13, color: themeController.textSecondaryColor),
                                            selectedTextStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            todayTextStyle: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                          headerVisible: false,
                                          calendarFormat: CalendarFormat.month,
                                          availableCalendarFormats: const {
                                            CalendarFormat.month: '월',
                                          },
                                          availableGestures: AvailableGestures.none,
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
                                backgroundColor: Get.find<ThemeController>().financeColor,
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
                                  final ThemeController themeController = Get.find<ThemeController>();
                                  Get.snackbar(
                                    '오류',
                                    '올바른 금액을 입력해주세요',
                                    backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
                                  );
                                  return;
                                }

                                // Check if there's a change
                                if (amount == defaultAmount && selectedDate.day == defaultDay) {
                                  final ThemeController themeController = Get.find<ThemeController>();
                                  Get.snackbar(
                                    '알림',
                                    '변경된 내용이 없습니다',
                                    backgroundColor: themeController.isDarkMode ? AppColors.darkInfo : AppColors.info,
                                  );
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
                                  await _controller.loadFixedFinanceCategories();

                                  // Find the updated category from the controller
                                  CategoryWithSettings? updatedCategory;
                                  for (var cat in _controller.financeCategories) {
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
                                  final ThemeController themeController = Get.find<ThemeController>();
                                  Get.snackbar(
                                    '성공',
                                    '${category.name}의 설정이 ${DateFormat('yyyy년 M월 d일').format(selectedDate)}부터 ${NumberFormat('#,###').format(amount)}원으로 변경되었습니다.',
                                    backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
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

                                  final ThemeController themeController = Get.find<ThemeController>();
                                  Get.snackbar(
                                    '오류',
                                    '설정 업데이트에 실패했습니다.',
                                    backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
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
      await _controller.loadFixedFinanceCategories();
      await _loadTransactionHistory();

      // 7. Exit detail view
      setState(() {
        _isDetailViewMode = false;
        _isDeleteMode = false;
        _selectedCategory = null;
        _selectedHistoricalSettings = null;
      });

      // 8. Show success message
      final ThemeController themeController = Get.find<ThemeController>();
      Get.snackbar(
        '삭제 완료',
        '${_deleteFromDate.toString().substring(0, 10)} 이후의 ${_selectedCategory!.name} 고정 금융이 삭제되었습니다.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Show error message
      final ThemeController themeController = Get.find<ThemeController>();
      Get.snackbar(
        '오류',
        '삭제 중 문제가 발생했습니다: $e',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}

// 확장 함수로 다이얼로그 표시 쉽게 만들기
extension FixedFinanceDialogExtension on GetInterface {
  Future<void> showFixedFinanceDialog() {
    return Get.dialog(
      const FixedFinanceDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}