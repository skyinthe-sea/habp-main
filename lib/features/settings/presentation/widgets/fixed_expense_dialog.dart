import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  // Map to cache latest transactions for categories without settings
  final Map<int, Map<String, dynamic>?> _latestTransactions = {};
  bool _isLoadingTransactions = true;

  // Create mode
  bool _isCreateMode = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late DateTime _selectedDate;

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
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

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
      // Only check transaction_record2 if no settings exist
      if (category.settings.isEmpty) {
        final List<Map<String, dynamic>> transactions = await db.query(
          'transaction_record2',
          where: 'category_id = ?',
          whereArgs: [category.id],
          orderBy: 'transaction_date DESC',
          limit: 1,
        );

        if (transactions.isNotEmpty) {
          _latestTransactions[category.id] = transactions.first;
        }
      }
    }

    setState(() {
      _isLoadingTransactions = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        content: Obx(() {
          if (_controller.isLoadingExpense.value || _isLoadingTransactions) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 300,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cate4.withOpacity(0.8),
                        AppColors.cate4,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '고정 지출 관리',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    '매월 반복되는 고정 지출을 관리합니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                // Create form or list
                if (_isCreateMode)
                  _buildCreateForm()
                else
                  _buildCategoryList(),

                // Bottom actions
                _buildBottomActions(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCreateForm() {

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '새 고정 지출 추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Name field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: '지출 이름',
              hintText: '예: 월세, 통신비, 구독료 등',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.payment),
            ),
          ),
          const SizedBox(height: 16),

          // Amount field
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: '금액',
              hintText: '숫자만 입력',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.money_off),
              prefixText: '₩ ',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Date selection field
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '매월 지출 날짜',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            '매월 ${_selectedDate.day}일',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Form action buttons
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isCreateMode = false;
                    _nameController.clear();
                    _amountController.clear();
                  });
                },
                child: const Text('취소'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cate4,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  // Validate form
                  if (_nameController.text.isEmpty) {
                    Get.snackbar('오류', '지출 이름을 입력해주세요');
                    return;
                  }

                  if (_amountController.text.isEmpty) {
                    Get.snackbar('오류', '금액을 입력해주세요');
                    return;
                  }

                  final amount = double.tryParse(_amountController.text);
                  if (amount == null || amount <= 0) {
                    Get.snackbar('오류', '유효한 금액을 입력해주세요');
                    return;
                  }

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
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '이미 존재하는 이름이거나 추가 중 오류가 발생했습니다',
                      backgroundColor: Colors.red[100],
                    );
                  }
                },
                child: const Text('추가하기'),
              ),
            ],
          ),
        ],
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
              Icon(
                Icons.money_off_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '등록된 고정 지출이 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '새로운 고정 지출을 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Flexible(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shrinkWrap: true,
        itemCount: _controller.expenseCategories.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final category = _controller.expenseCategories[index];
          final latestSetting = category.settings.isNotEmpty
              ? category.settings.first
              : null;
          final latestTransaction = _latestTransactions[category.id];

          return Dismissible(
            key: Key('expense-${category.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('삭제 확인'),
                  content: Text('${category.name} 고정 지출을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
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
                );
              } else {
                Get.snackbar(
                  '오류',
                  '삭제 중 문제가 발생했습니다.',
                  backgroundColor: Colors.red[100],
                );

                // 데이터 다시 로드
                await _controller.loadFixedExpenseCategories();
              }
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.cate4.withOpacity(0.2),
                child: Icon(
                  Icons.money_off,
                  color: AppColors.cate4,
                ),
              ),
              title: Text(
                category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: latestSetting != null
                  ? Text(
                '현재 금액: ${_formatCurrency(latestSetting.amount)}원\n'
                    '매월 ${latestSetting.effectiveFrom.day}일',
                style: const TextStyle(fontSize: 12),
              )
                  : latestTransaction != null
                  ? Text(
                '현재 금액: ${_formatCurrency(latestTransaction['amount'].abs())}원\n'
                    '매월 ${latestTransaction['transaction_num']}일',
                style: const TextStyle(fontSize: 12),
              )
                  : const Text('설정된 금액 없음'),
              trailing: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.cate4.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.cate4,
                    size: 20,
                  ),
                ),
                onPressed: () => _showUpdateDialog(category),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_isCreateMode)
            const SizedBox.shrink()
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('새 고정 지출 추가'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cate4,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                setState(() {
                  _isCreateMode = true;
                });
              },
            ),

          if (_isCreateMode)
            const SizedBox.shrink()
          else
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('닫기'),
            ),
        ],
      ),
    );
  }

  void _showUpdateDialog(CategoryWithSettings category) {
    final TextEditingController amountController = TextEditingController();

    // 기존 트랜잭션 날짜와 금액 정보 가져오기
    int initialDay = 1;

    // 기존 금액이 있으면 입력 필드에 설정
    if (category.settings.isNotEmpty) {
      amountController.text = category.settings.first.amount.toStringAsFixed(0);
      // 기존 설정의 날짜 추출
      initialDay = category.settings.first.effectiveFrom.day;
    } else {
      // 거래 내역에서 금액 가져오기
      final latestTransaction = _latestTransactions[category.id];
      if (latestTransaction != null) {
        final amount = latestTransaction['amount'];
        if (amount is num) {
          amountController.text = amount.abs().toStringAsFixed(0);
        }

        // transaction_num에서 일자 추출 (매월 고정 거래인 경우)
        final description = latestTransaction['description'] as String;
        final transactionNum = latestTransaction['transaction_num'].toString();

        if (description.contains('매월')) {
          initialDay = int.tryParse(transactionNum) ?? 1;
        }
      }
    }

    // 적용 시작 월 선택 (기본값은 현재 월)
    final now = DateTime.now();
    DateTime selectedDate = DateTime(now.year, now.month, initialDay);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${category.name} 설정 수정',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: Colors.grey[300]),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 금액 입력 필드
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(
                      labelText: '금액',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.money_off),
                      prefixText: '₩ ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // 적용 시작 날짜 선택
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '매월 지출 날짜',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 18),
                              const SizedBox(width: 12),
                              Text(
                                '매월 ${selectedDate.day}일',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cate4,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    // 입력값 검증
                    if (amountController.text.isEmpty) {
                      Get.snackbar('오류', '금액을 입력해주세요');
                      return;
                    }

                    final amount = double.tryParse(amountController.text);
                    if (amount == null) {
                      Get.snackbar('오류', '올바른 금액을 입력해주세요');
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
                      );
                    } else {
                      Get.snackbar(
                        '오류',
                        '설정 업데이트에 실패했습니다.',
                        backgroundColor: Colors.red[100],
                      );
                    }
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
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
    );
  }
}