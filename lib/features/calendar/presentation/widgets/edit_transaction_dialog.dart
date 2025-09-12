import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../domain/entities/calendar_transaction.dart';

class EditTransactionDialog extends StatefulWidget {
  final CalendarTransaction transaction;
  final Function(CalendarTransaction) onUpdate;

  const EditTransactionDialog({
    Key? key,
    required this.transaction,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _amountController = TextEditingController(
      text: NumberFormat('#,###').format(widget.transaction.amount.abs().toInt())
    );
    _selectedDate = DateTime(
      widget.transaction.transactionDate.year,
      widget.transaction.transactionDate.month,
      widget.transaction.transactionDate.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(widget.transaction.transactionDate);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그
  Future<void> _selectDate() async {
    final ThemeController themeController = Get.find<ThemeController>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: themeController.primaryColor,
              onPrimary: Colors.white,
              surface: themeController.cardColor,
              onSurface: themeController.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // 시간 선택 다이얼로그
  Future<void> _selectTime() async {
    final ThemeController themeController = Get.find<ThemeController>();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: themeController.primaryColor,
              onPrimary: Colors.white,
              surface: themeController.cardColor,
              onSurface: themeController.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // 수정 저장
  Future<void> _saveChanges() async {
    if (_descriptionController.text.trim().isEmpty) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '입력 오류',
            '거래 내용을 입력해주세요.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '입력 오류',
            '금액을 입력해주세요.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 금액 파싱 (콤마 제거)
      final amountStr = _amountController.text.replaceAll(',', '');
      final amount = double.parse(amountStr);
      
      // 거래 타입에 따라 부호 조정
      final finalAmount = widget.transaction.categoryType == 'EXPENSE' && amount > 0 
          ? -amount 
          : (widget.transaction.categoryType == 'INCOME' && amount < 0 ? amount.abs() : amount);

      // 날짜와 시간 결합
      final newDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 수정된 거래 정보 생성
      final updatedTransaction = CalendarTransaction(
        id: widget.transaction.id,
        categoryId: widget.transaction.categoryId,
        categoryName: widget.transaction.categoryName,
        categoryType: widget.transaction.categoryType,
        amount: finalAmount,
        description: _descriptionController.text.trim(),
        transactionDate: newDateTime,
        isFixed: widget.transaction.isFixed,
      );

      // 콜백 호출
      await widget.onUpdate(updatedTransaction);

      Get.back();
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '수정 완료',
            '거래 내역이 성공적으로 수정되었습니다.',
        backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
        colorText: AppColors.success,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } catch (e) {
      final ThemeController themeController = Get.find<ThemeController>();
            Get.snackbar(
            '오류',
            '거래 수정 중 오류가 발생했습니다: $e',
        backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            color: themeController.cardColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                _buildHeader(),
                
                // 내용
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 거래 내용 입력
                        _buildDescriptionField(),
                        
                        const SizedBox(height: 20),
                        
                        // 금액 입력
                        _buildAmountField(),
                        
                        const SizedBox(height: 20),
                        
                        // 날짜 및 시간 선택
                        _buildDateTimeFields(),
                        
                        const SizedBox(height: 30),
                        
                        // 저장 버튼
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    // 거래 타입에 따른 색상 설정
    Color headerColor;
    String headerTitle;
    
    switch (widget.transaction.categoryType) {
      case 'INCOME':
        headerColor = themeController.isDarkMode ? Colors.green.shade600 : Colors.green[300]!;
        headerTitle = '소득 수정';
        break;
      case 'EXPENSE':
        headerColor = themeController.isDarkMode ? Colors.red.shade600 : Colors.red[300]!;
        headerTitle = '지출 수정';
        break;
      case 'FINANCE':
        headerColor = themeController.isDarkMode ? Colors.blue.shade600 : Colors.blue[300]!;
        headerTitle = '재테크 수정';
        break;
      default:
        headerColor = themeController.primaryColor;
        headerTitle = '거래 수정';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [headerColor, headerColor.withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headerTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.transaction.categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white30,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '거래 내용',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeController.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
            color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
          ),
          child: TextField(
            controller: _descriptionController,
            style: TextStyle(
              fontSize: 16,
              color: themeController.textPrimaryColor,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: '거래 내용을 입력하세요',
              hintStyle: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '금액',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeController.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
            color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
          ),
          child: TextField(
            controller: _amountController,
            style: TextStyle(
              fontSize: 16,
              color: themeController.textPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              // 숫자에 콤마 추가하는 포맷터
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final number = int.tryParse(newValue.text.replaceAll(',', ''));
                if (number == null) return oldValue;
                final formatted = NumberFormat('#,###').format(number);
                return newValue.copyWith(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 16,
              ),
              suffix: Text(
                '원',
                style: TextStyle(
                  fontSize: 16,
                  color: themeController.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 및 시간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeController.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 날짜 선택
            Expanded(
              flex: 3,
              child: GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
                    color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: themeController.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          DateFormat('M월 d일').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: themeController.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 시간 선택
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
                    color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: themeController.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selectedTime.format(context),
                          style: TextStyle(
                            fontSize: 16,
                            color: themeController.textPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    // 거래 타입에 따른 버튼 그라데이션 색상 설정
    List<Color> gradientColors;
    switch (widget.transaction.categoryType) {
      case 'INCOME':
        gradientColors = [Colors.green[500]!, Colors.green[600]!];
        break;
      case 'EXPENSE':
        gradientColors = [Colors.red[500]!, Colors.red[600]!];
        break;
      case 'FINANCE':
        gradientColors = [Colors.blue[500]!, Colors.blue[600]!];
        break;
      default:
        gradientColors = [AppColors.primary, AppColors.primaryDark];
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isLoading ? [Colors.grey[400]!, Colors.grey[500]!] : gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading ? [] : [
          BoxShadow(
            color: gradientColors[1].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveChanges,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '수정 완료',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}