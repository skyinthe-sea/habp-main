import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../controllers/expense_controller.dart';

class QuickExpenseEntry extends StatefulWidget {
  final ExpenseController controller;
  final Function(int categoryId, double amount, String description, DateTime date) onExpenseAdded;

  const QuickExpenseEntry({
    Key? key,
    required this.controller,
    required this.onExpenseAdded,
  }) : super(key: key);

  @override
  State<QuickExpenseEntry> createState() => _QuickExpenseEntryState();
}

class _QuickExpenseEntryState extends State<QuickExpenseEntry> with SingleTickerProviderStateMixin {
  int? selectedCategoryId;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  late TabController _tabController;

  // 빠른 입력을 위한 자주 사용하는 금액 버튼
  final List<int> quickAmounts = [5000, 10000, 30000, 50000, 100000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 금액 입력 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 금액 포맷팅 함수
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';

    // 콤마와 문자 제거
    String onlyNums = value.replaceAll(RegExp(r'[^\d]'), '');

    // 숫자를 정수로 변환
    int amount = int.tryParse(onlyNums) ?? 0;

    // 천 단위 콤마 포맷팅
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _saveExpense() {
    if (selectedCategoryId == null) {
      Get.snackbar(
        '알림',
        '카테고리를 선택해주세요',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (amountController.text.isEmpty) {
      Get.snackbar(
        '알림',
        '금액을 입력해주세요',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final amount = double.parse(amountController.text.replaceAll(',', ''));
      if (amount <= 0) {
        Get.snackbar(
          '알림',
          '유효한 금액을 입력해주세요',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      // 지출 추가 함수 호출
      widget.onExpenseAdded(
        selectedCategoryId!,
        amount,
        descriptionController.text,
        selectedDate,
      );

      // 다이얼로그 닫기
      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        '오류',
        '지출 추가 중 오류가 발생했습니다',
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: '지출 입력'),
                          Tab(text: '최근 지출'),
                        ],
                        labelColor: AppColors.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primary,
                        indicatorSize: TabBarIndicatorSize.label,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // 지출 입력 탭
                    _buildExpenseInputTab(),

                    // 최근 지출 내역 탭 (복제하여 빠르게 입력)
                    _buildRecentExpensesTab(),
                  ],
                ),
              ),

              // 입력 버튼
              Container(
                margin: const EdgeInsets.only(top: 16),
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    '저장하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseInputTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 금액 입력
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '얼마를 쓰셨나요?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final formatted = _formatCurrency(value);
                    if (formatted != value) {
                      amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  }
                },
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixText: '원',
                  suffixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 빠른 금액 선택 버튼
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: quickAmounts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () {
                    amountController.text = _formatCurrency(quickAmounts[index].toString());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('${_formatCurrency(quickAmounts[index].toString())}원'),
                ),
              );
            },
          ),
        ),

        // 카테고리 선택
        const Text(
          '카테고리',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: Obx(() {
            final categories = widget.controller.variableCategories;

            if (categories.isEmpty) {
              return Center(
                child: Text(
                  '등록된 카테고리가 없습니다.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategoryId == category.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedCategoryId = category.id;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category.name),
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // 날짜 및 메모
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'hihi',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 메모 입력
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            hintText: '간단한 메모를 입력하세요 (선택사항)',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: 2,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildRecentExpensesTab() {
    // 실제 앱에서는 최근 지출 내역을 가져오는 로직 구현
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '최근 지출 내역이 여기에 표시됩니다',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '자주 사용하는 지출을 빠르게 입력할 수 있어요',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    // 카테고리 이름에 따른 아이콘 매핑
    switch (categoryName.toLowerCase()) {
      case '식비':
        return Icons.restaurant;
      case '교통비':
        return Icons.directions_bus;
      case '문화생활':
        return Icons.movie;
      case '쇼핑':
        return Icons.shopping_bag;
      case '카페':
        return Icons.coffee;
      case '술자리':
        return Icons.local_bar;
      default:
        return Icons.category;
    }
  }
}