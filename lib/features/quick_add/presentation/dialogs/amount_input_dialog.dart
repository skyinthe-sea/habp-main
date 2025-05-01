import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../controllers/quick_add_controller.dart';
import 'date_selection_dialog.dart';

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isHighlighted
              ? AppColors.primary
              : _amountFocusNode.hasFocus
              ? AppColors.primary
              : Colors.grey.shade300,
          width: _isHighlighted ? 2.0 : 1.0,
        ),
        color: _isHighlighted ? AppColors.primary.withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          // Decrement button
          _buildIncrementButton(
            icon: Icons.remove,
            onPressed: () {
              final step = _getSmartIncrement(false);
              _updateAmount(_currentAmount - step);
            },
          ),

          // Amount text field
          Expanded(
            child: TextField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isHighlighted ? AppColors.primary : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: '원',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
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

          // Increment button
          _buildIncrementButton(
            icon: Icons.add,
            onPressed: () {
              final step = _getSmartIncrement(true);
              _updateAmount(_currentAmount + step);
            },
          ),
        ],
      ),
    );
  }

  /// Builds an increment/decrement button with visual effects
  Widget _buildIncrementButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Builds the quick amount selection buttons
  Widget _buildQuickAmountButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '빠른 선택',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetAmounts.map((amount) {
            // Check if this preset is the current selection
            final isSelected = _currentAmount == amount;

            return GestureDetector(
              onTap: () {
                _updateAmount(amount);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  NumberFormat('#,###').format(amount) + '원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
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

                  // Enhanced amount field with +/- buttons
                  _buildAmountField(),
                ],
              ),

              const SizedBox(height: 16),

              // Quick amount selection buttons
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.3),
                    elevation: 0,
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