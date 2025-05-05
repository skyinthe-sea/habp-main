import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../controllers/settings_controller.dart';

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

  // Map to cache latest transactions for categories without settings
  final Map<int, Map<String, dynamic>?> _latestTransactions = {};
  bool _isLoadingTransactions = true;

  // Create mode
  bool _isCreateMode = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  bool _isValidAmount = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<SettingsController>();
    _loadLatestTransactions();

    // Initialize the selected date
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);

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

  // Load latest transactions for categories that don't have settings
  Future<void> _loadLatestTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    // Create a new instance of DBHelper (this is safe since it's a singleton)
    final dbHelper = DBHelper();
    final db = await dbHelper.database;

    for (final category in _controller.expenseCategories) {
      // 1. fixed_transaction_setting에서 최신 설정 가져오기
      final List<Map<String, dynamic>> settings = await db.query(
        'fixed_transaction_setting',
        where: 'category_id = ?',
        whereArgs: [category.id],
        orderBy: 'effective_from DESC',
        limit: 1,
      );

      // 2. transaction_record2에서 실제 거래 정보 가져오기
      final List<Map<String, dynamic>> transactions = await db.query(
        'transaction_record2',
        where: 'category_id = ?',
        whereArgs: [category.id],
        orderBy: 'transaction_date DESC',
        limit: 1,
      );

      // 최신 설정과 거래 정보 비교 후 저장
      if (settings.isNotEmpty) {
        // 최신 설정 정보가 있는 경우, 이를 우선 사용
        final settingAmount = settings.first['amount'] as double;
        final settingDate = DateTime.parse(settings.first['effective_from']);

        if (transactions.isNotEmpty) {
          // 거래 정보도 있는 경우 최신 설정의 금액과 비교
          final transactionAmount = (transactions.first['amount'] as double).abs();

          // 금액이 다르면 로그 출력 (디버깅용)
          if (settingAmount != transactionAmount) {
            debugPrint('경고: 카테고리 ${category.id}의 설정 금액($settingAmount)과 거래 금액($transactionAmount)이 다릅니다!');
          }
        }
      }

      // 거래 정보 저장 (고정거래 표시용)
      if (transactions.isNotEmpty) {
        _latestTransactions[category.id] = transactions.first;
      }
    }

    setState(() {
      _isLoadingTransactions = false;
    });
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
                        // Redesigned Header
                        _buildHeader(),

                        // Main content (Create form or list)
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

  // Redesigned sleek header
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
          // Background design elements (decorative circles)
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '고정 지출 관리',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '매월 반복되는 지출을 설정하세요',
                            style: TextStyle(
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

                // Expense stats summary
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _isCreateMode ? 0 : 72, // Increased height to fix overflow
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(_isCreateMode ? 0 : 12),
                    child: _isCreateMode
                        ? const SizedBox()
                        : Row(
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
                                overflow: TextOverflow.ellipsis, // Prevent text overflow
                              ),
                              const SizedBox(height: 6), // Increased spacing
                              Text(
                                '${_controller.expenseCategories.length}개',
                                style: const TextStyle(
                                  fontSize: 16, // Smaller font size
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
                                  overflow: TextOverflow.ellipsis, // Prevent text overflow
                                ),
                                const SizedBox(height: 6), // Increased spacing
                                Text(
                                  _calculateTotalMonthlyExpense(),
                                  style: const TextStyle(
                                    fontSize: 16, // Smaller font size
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
                const SizedBox(height: 8), // Added extra padding at the bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalMonthlyExpense() {
    double total = 0;
    for (final category in _controller.expenseCategories) {
      if (category.settings.isNotEmpty) {
        total += category.settings.first.amount;
      } else {
        // Use transaction amount if available
        final transaction = _latestTransactions[category.id];
        if (transaction != null) {
          final amount = transaction['amount'];
          if (amount is num) {
            total += amount.abs().toDouble();
          }
        }
      }
    }
    return '₩ ${NumberFormat('#,###').format(total)}';
  }

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

            // Name field with enhanced styling
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

            // Amount field with enhanced styling
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
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '유효한 금액을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Date selection with enhanced styling
            const Text(
              '매월 지출 날짜',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppColors.cate4,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.cate4,
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '매월 ${_selectedDate.day}일',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: ListView.builder(
        itemCount: _controller.expenseCategories.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final category = _controller.expenseCategories[index];

          // settings가 있으면 최신 설정의 금액을 사용
          // 없으면 transaction_record2에서 금액 가져오기
          double? displayAmount;
          String displayDate = '';

          if (category.settings.isNotEmpty) {
            // 최신 설정 사용
            final latestSetting = category.settings.first;
            displayAmount = latestSetting.amount;
            displayDate = '매월 ${latestSetting.effectiveFrom.day}일';
          } else {
            // 거래 내역에서 금액 가져오기
            final latestTransaction = _latestTransactions[category.id];
            if (latestTransaction != null) {
              final amount = latestTransaction['amount'];
              if (amount is num) {
                displayAmount = amount.abs().toDouble();
              }

              final transactionNum = latestTransaction['transaction_num'].toString();
              displayDate = '매월 $transactionNum일';
            }
          }

          return Dismissible(
            key: Key('expense-${category.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 28),
                      const SizedBox(width: 12),
                      const Text('삭제 확인'),
                    ],
                  ),
                  content: Text('${category.name} 고정 지출을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('취소',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('삭제'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              final success = await _controller.deleteFixedTransactionCategory(category.id);
              if (success) {
                Get.snackbar(
                  '삭제 완료',
                  '${category.name} 고정 지출이 삭제되었습니다.',
                  backgroundColor: Colors.green[100],
                  borderRadius: 12,
                  margin: const EdgeInsets.all(12),
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              } else {
                Get.snackbar(
                  '오류',
                  '삭제 중 문제가 발생했습니다.',
                  backgroundColor: Colors.red[100],
                  borderRadius: 12,
                  margin: const EdgeInsets.all(12),
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );

                // 데이터 다시 로드
                await _controller.loadFixedExpenseCategories();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.red.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon with rounded background
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.cate4.withOpacity(0.8),
                                AppColors.cate4,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
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
                            size: 24,
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                displayDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
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

                  // Edit button at the bottom
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showUpdateDialog(category),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.cate4,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '수정하기',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.cate4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
      child: _isCreateMode
          ? Row(
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

                  // Create the fixed transaction
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
      )
          : Row(
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

  void _showUpdateDialog(CategoryWithSettings category) {
    final TextEditingController amountController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // 기존 설정/트랜잭션 날짜와 금액 정보 가져오기
    int initialDay = 1;
    double initialAmount = 0;

    // 우선 순위: 1. 최신 설정 2. 최신 거래
    if (category.settings.isNotEmpty) {
      // 설정 정보가 있으면 이를 우선 사용
      final latestSetting = category.settings.first;
      amountController.text = latestSetting.amount.toStringAsFixed(0);
      initialDay = latestSetting.effectiveFrom.day;
      initialAmount = latestSetting.amount;
      debugPrint('카테고리 ${category.id}의 최신 설정 금액: $initialAmount, 날짜: $initialDay일');
    } else {
      // 거래 내역에서 금액 가져오기
      final latestTransaction = _latestTransactions[category.id];
      if (latestTransaction != null) {
        final amount = latestTransaction['amount'];
        if (amount is num) {
          initialAmount = amount.abs().toDouble();
          amountController.text = initialAmount.toStringAsFixed(0);
        }

        // transaction_num에서 일자 추출 (매월 고정 거래인 경우)
        final description = latestTransaction['description'] as String;
        final transactionNum = latestTransaction['transaction_num'].toString();

        if (description.contains('매월')) {
          initialDay = int.tryParse(transactionNum) ?? 1;
        }

        debugPrint('카테고리 ${category.id}의 최신 거래 금액: $initialAmount, 날짜: $initialDay일');
      }
    }

    // 적용 시작 날짜 선택 (기본값은 현재 월, 선택된 일)
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, initialDay);
    bool isValidAmount = true;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: EdgeInsets.zero,
                title: null,
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with category name
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
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
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: Row(
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
                                    '지출 설정 수정',
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
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Current settings display
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '현재 설정',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
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
                                            const SizedBox(height: 4),
                                            Text(
                                              '₩ ${NumberFormat('#,###').format(initialAmount)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        height: 30,
                                        width: 1,
                                        color: Colors.grey[300],
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 16),
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
                                              const SizedBox(height: 4),
                                              Text(
                                                '매월 $initialDay일',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // New amount input
                            const Text(
                              '새 금액',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
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
                                  borderSide: BorderSide(color: isValidAmount ? Colors.grey[200]! : Colors.red.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                      color: isValidAmount ? AppColors.cate4 : Colors.red.shade500,
                                      width: 2
                                  ),
                                ),
                                errorText: !isValidAmount && amountController.text.isNotEmpty
                                    ? '유효한 금액을 입력해주세요'
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isEmpty) {
                                    isValidAmount = true;
                                    return;
                                  }

                                  final amount = double.tryParse(value);
                                  isValidAmount = amount != null && amount > 0;
                                });
                              },
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

                            // New date selection
                            const Text(
                              '새로운 날짜',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.light(
                                          primary: AppColors.cate4,
                                          onPrimary: Colors.white,
                                          onSurface: Colors.black,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.cate4,
                                          ),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                        Icons.calendar_today_rounded,
                                        color: Colors.grey[600],
                                        size: 20
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '매월 ${selectedDate.day}일',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.grey[600]
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cate4,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                // 입력값 검증
                                final amount = double.tryParse(amountController.text);
                                if (amount == null) {
                                  Get.snackbar('오류', '올바른 금액을 입력해주세요');
                                  return;
                                }

                                // 금액이 변경되었는지 확인
                                if (amount == initialAmount && selectedDate.day == initialDay) {
                                  Get.snackbar('알림', '변경된 내용이 없습니다');
                                  Navigator.pop(context);
                                  return;
                                }

                                // 설정 업데이트 (전체 날짜 정보 전달)
                                final success = await _controller.updateFixedTransactionSetting(
                                  categoryId: category.id,
                                  amount: amount,
                                  effectiveFrom: selectedDate, // 일자 정보 포함된 전체 날짜
                                );

                                // 대화상자 닫기
                                Navigator.pop(context);

                                // 결과 표시
                                if (success) {
                                  Get.snackbar(
                                    '성공',
                                    '${category.name}의 금액이 ${_formatDate(selectedDate)}부터 ${_formatCurrency(amount)}원으로 수정되었습니다.',
                                    backgroundColor: Colors.green[100],
                                    borderRadius: 12,
                                    margin: const EdgeInsets.all(12),
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 2),
                                  );

                                  // 데이터 다시 로드 (UI 갱신을 위해)
                                  _loadLatestTransactions();
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
              );
            },
          ),
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###').format(amount);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
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