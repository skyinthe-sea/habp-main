import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'date_selection_dialog.dart';
import 'calculator_dialog.dart';

/// Final dialog in the quick add flow
/// Allows inputting the transaction amount with improved UX
class AmountInputDialog extends StatefulWidget {
  const AmountInputDialog({Key? key}) : super(key: key);

  @override
  State<AmountInputDialog> createState() => _AmountInputDialogState();
}

class _AmountInputDialogState extends State<AmountInputDialog>
    with SingleTickerProviderStateMixin {
  // Animation controller for animations
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _saveEnabled = false;

  // Current amount stored as an integer
  int _currentAmount = 0;

  // Flag for highlight animation on amount changes
  bool _isHighlighted = false;

  // Preset amounts for quick selection (in KRW)
  final List<int> _presetAmounts = [
    1000, 5000, 10000, 50000, 100000
  ];

  // Step increments for +/- buttons
  final List<int> _incrementSteps = [
    100, 500, 1000, 5000, 10000, 50000
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Set focus to amount field after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_amountFocusNode);
      }
    });

    // Listen for changes to enable/disable save button
    _amountController.addListener(_updateSaveButtonState);

    // Initialize with a default amount of 0
    _amountController.text = '0';
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateSaveButtonState);
    _amountController.dispose();
    _descriptionController.dispose();
    _amountFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Updates the enabled state of the save button based on input validity
  void _updateSaveButtonState() {
    final text = _amountController.text.replaceAll(',', '');
    setState(() {
      _saveEnabled = text.isNotEmpty &&
          double.tryParse(text) != null &&
          double.parse(text) > 0;
    });
  }

  /// Formats the amount with comma separators
  String _formatAmount(String text) {
    if (text.isEmpty) return '0';

    final onlyNumbers = text.replaceAll(',', '');
    if (onlyNumbers.isEmpty) return '0';

    final intValue = int.tryParse(onlyNumbers);
    if (intValue == null) return text;

    return NumberFormat('#,###').format(intValue);
  }

  /// Updates amount with the new value and provides feedback
  void _updateAmount(int newAmount) {
    // Prevent negative amounts
    newAmount = newAmount < 0 ? 0 : newAmount;

    // Update current amount
    _currentAmount = newAmount;

    // Format and update text field
    final formattedAmount = _formatAmount(newAmount.toString());
    _amountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    // Visual highlight animation
    _showHighlightAnimation();
  }

  /// Shows a brief highlight animation on the amount field
  void _showHighlightAnimation() {
    setState(() {
      _isHighlighted = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isHighlighted = false;
        });
      }
    });
  }

  /// 계산기 다이얼로그 표시
  void _showCalculatorDialog() async {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    // 계산기 다이얼로그 표시하고 결과 기다리기
    final result = await showDialog<int>(
      context: context,
      builder: (context) => CalculatorDialog(
        initialValue: _currentAmount, // 현재 금액을 초기값으로 전달
      ),
    );

    // 결과가 있으면 금액 업데이트
    if (result != null) {
      _updateAmount(result);
    }
  }

  /// Determines the appropriate increment/decrement step based on current amount
  int _getSmartIncrement(bool isIncrement) {
    // For zero or very small amounts, use smallest increment
    if (_currentAmount < 1000) {
      return 100;
    }

    // Find appropriate step based on the amount's order of magnitude
    for (int i = _incrementSteps.length - 1; i >= 0; i--) {
      if (_currentAmount >= _incrementSteps[i] * 10) {
        // For large amounts, use a larger step
        return _incrementSteps[i];
      }
    }

    // Default increment
    return 1000;
  }

  /// Builds the amount input field with visual feedback
  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHighlighted
                ? AppColors.primary
                : _amountFocusNode.hasFocus
                ? AppColors.primary
                : Colors.grey.shade200,
            width: _isHighlighted ? 2.0 : 1.0,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            // 0으로 초기화하는 버튼 추가
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _updateAmount(0);
                  HapticFeedback.lightImpact();
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'C',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),

            // 금액 입력 필드 (확장)
            Expanded(
              child: TextField(
                controller: _amountController,
                focusNode: _amountFocusNode,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isHighlighted ? AppColors.primary : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '원',
                  suffixStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  // Parse current value
                  final cleanValue = value.replaceAll(',', '');
                  _currentAmount = int.tryParse(cleanValue) ?? 0;

                  // Format with commas
                  final formatted = _formatAmount(value);
                  if (formatted != value) {
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
              ),
            ),

            // 계산기 버튼 추가
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCalculatorDialog,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the quick amount selection buttons with add/subtract functionality
  Widget _buildQuickAmountButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // First row: 100, 1,000, 5,000
          Row(
            children: [
              // Subtraction side (left)
              _buildOperationButton(amount: 100, isAddition: false),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 1000, isAddition: false),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 5000, isAddition: false),

              // Center divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),

              // Addition side (right)
              _buildOperationButton(amount: 100, isAddition: true),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 1000, isAddition: true),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 5000, isAddition: true),
            ],
          ),

          const SizedBox(height: 8),

          // Second row: 10,000, 50,000, 100,000
          Row(
            children: [
              // Subtraction side (left)
              _buildOperationButton(amount: 10000, isAddition: false),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 50000, isAddition: false),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 100000, isAddition: false),

              // Center divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),

              // Addition side (right)
              _buildOperationButton(amount: 10000, isAddition: true),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 50000, isAddition: true),
              const SizedBox(width: 8),
              _buildOperationButton(amount: 100000, isAddition: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to build operation buttons
  Widget _buildOperationButton({required int amount, required bool isAddition}) {
    final Color backgroundColor = isAddition
        ? AppColors.primary.withOpacity(0.1)
        : Colors.grey.shade200;

    final Color textColor = isAddition
        ? AppColors.primary
        : Colors.grey.shade700;

    final IconData icon = isAddition ? Icons.add : Icons.remove;

    // Adjust font size based on digit count to prevent text wrapping
    double fontSize = 11.0;
    if (amount >= 100000) {
      fontSize = 9.0; // Smaller font for 100,000 to prevent line breaks
    }

    return Expanded(
      child: InkWell(
        onTap: () {
          if (isAddition) {
            _updateAmount(_currentAmount + amount);
          } else if (_currentAmount >= amount) {
            // Only subtract if the result won't be negative
            _updateAmount(_currentAmount - amount);
          } else {
            // If subtracting would result in negative, set to 0
            _updateAmount(0);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: textColor),
              const SizedBox(height: 2),
              Text(
                NumberFormat('#,###').format(amount),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog title and back button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '금액 입력',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: () {
                      // Go back to the previous dialog
                      Navigator.of(context).pop();

                      // Show the date selection dialog again
                      showGeneralDialog(
                        context: context,
                        pageBuilder: (_, __, ___) => const DateSelectionDialog(),
                        transitionBuilder: (context, animation, secondaryAnimation, child) {
                          final curve = CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          );

                          return ScaleTransition(
                            scale: curve,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 150),
                        barrierDismissible: true,
                        barrierLabel: '',
                        barrierColor: Colors.black.withOpacity(0.5),
                      );
                    },
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Transaction info
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
                        const Text(
                          '카테고리:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() => Text(
                            controller.transaction.value.categoryName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          '날짜:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Obx(() => Text(
                            DateFormat('yyyy년 MM월 dd일').format(
                                controller.transaction.value.transactionDate),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Amount input field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '금액',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 수정된 금액 입력 필드 (계산기 버튼 추가)
                  _buildAmountField(),
                ],
              ),

              const SizedBox(height: 16),

              // Quick amount selection buttons with add/subtract functionality
              _buildQuickAmountButtons(),

              const SizedBox(height: 16),

              // Description input field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '설명 (선택사항)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: '내용을 입력하세요',
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Save button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Obx(() => ElevatedButton(
                  onPressed: !_saveEnabled || controller.isLoading.value
                      ? null
                      : () async {
                    // Parse amount
                    final amount = double.parse(
                        _amountController.text.replaceAll(',', ''));
                    controller.setAmount(amount);

                    // Set description if provided
                    if (_descriptionController.text.isNotEmpty) {
                      controller
                          .setDescription(_descriptionController.text);
                    }

                    // Save transaction
                    final success = await controller.saveTransaction();

                    // Close dialog and show success message if successful
                    if (success) {
                      Navigator.of(context).pop();

                      // Show success snackbar
                      Get.snackbar(
                        '성공',
                        '거래가 추가되었습니다',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      );
                    } else {
                      // Show error message
                      Get.snackbar(
                        '오류',
                        '거래 추가에 실패했습니다',
                        snackPosition: SnackPosition.TOP,
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.3),
                    elevation: 2,
                  ),
                  child: controller.isLoading.value
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}