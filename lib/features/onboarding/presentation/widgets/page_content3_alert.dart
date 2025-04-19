// lib/features/onboarding/presentation/widgets/page_content3_alert.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/expense_category.dart';
import '../../data/models/expense_entry.dart';
import '../controllers/onboarding_controller.dart';
import '../widgets/blinking_text_button.dart';
import '../controllers/expense_controller.dart';
import '../../domain/services/onboarding_service.dart';
import 'date_grid.dart'; // Import our new date picker widget

class PageContent3Alert extends StatefulWidget {
  const PageContent3Alert({Key? key}) : super(key: key);

  @override
  State<PageContent3Alert> createState() => _PageContent3AlertState();
}

class _PageContent3AlertState extends State<PageContent3Alert>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final ExpenseController _expenseController = ExpenseController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final OnboardingService _onboardingService = OnboardingService();

  final controller = Get.find<OnboardingController>();

  bool _isEditing = false;
  bool _isUpdating = false;
  ExpenseEntry? _selectedEntry;
  bool _isSaving = false;

  // Selected values
  String _selectedIncomeType = '저축';
  String _selectedFrequency = '매월';
  int _selectedDay = 5;

  // Dropdown options
  final List<String> _incomeTypes = ['저축', '펀드', '주식', '연금투자'];
  // Only monthly frequency is active, weekly and daily are commented out
  final List<String> _frequencies = ['매월'/*, '매주', '매일'*/];
  final List<String> _customIncomeTypes = [];

  static const Color primaryColor = Color(0xFFE495C0);

  @override
  void initState() {
    super.initState();

    // Animation controller setup (faster animation)
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // Reduced from 500ms
      vsync: this,
    );

    // Custom animation curve for pop effect
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);

    // Load custom income types
    _loadCustomIncomeTypes();

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  // Load custom income types
  void _loadCustomIncomeTypes() {
    final customTypes = _expenseController.getCustomIncomeTypes();
    if (customTypes.isNotEmpty) {
      setState(() {
        _customIncomeTypes.clear();
        // 소득 관련 항목만 필터링 (지출이나 재테크 항목은 제외)
        _customIncomeTypes.addAll(customTypes.where(
                (type) => !['저축', '펀드', '주식', '연금투자'].contains(type)
        ));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();

    // Save custom types
    if (_customIncomeTypes.isNotEmpty) {
      _expenseController.saveCustomIncomeTypes(_customIncomeTypes);
    }

    super.dispose();
  }

  // Format input with commas for thousands
  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', ''));
    if (number == null) return value;
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  // Switch to editing mode
  void _startEditing([ExpenseEntry? entry]) {
    setState(() {
      _isEditing = true;
      _isUpdating = entry != null;
      _selectedEntry = entry;

      if (entry != null) {
        // Set values from existing entry
        _selectedIncomeType = entry.incomeType;
        _selectedFrequency = entry.frequency;
        _selectedDay = entry.day;

        // Remove commas and set
        _textController.text = entry.amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},',
        );
      } else {
        _textController.clear();
      }
    });

    // Focus and show keyboard with slight delay
    Future.delayed(const Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_focusNode);
      // Force keyboard to show
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  // Exit editing mode
  void _stopEditing() {
    setState(() {
      _isEditing = false;
      _isUpdating = false;
      _selectedEntry = null;
      _textController.clear();
    });
    _focusNode.unfocus();
  }

  // Add expense
  void _addExpense() async {
    if (_textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final newEntry = ExpenseEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: amount,
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          createdAt: DateTime.now(),
        );

        // Save to memory
        _expenseController.addEntry(newEntry);

        // Save to DB
        await _onboardingService.saveIncomeInfo(
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          amount: amount.toDouble() * -1, // Store as negative
          type: ExpenseCategoryType.FINANCE,
        );

        _stopEditing();
        setState(() {});
      } catch (e) {
        debugPrint('재테크 정보 저장 중 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '저장에 실패했습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Update expense
  void _updateExpense() async {
    if (_selectedEntry == null || _textController.text.isEmpty) return;

    final amountText = _textController.text.replaceAll(',', '');
    final amount = int.tryParse(amountText);

    if (amount != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final updatedEntry = ExpenseEntry(
          id: _selectedEntry!.id,
          amount: amount,
          incomeType: _selectedIncomeType,
          frequency: _selectedFrequency,
          day: _selectedDay,
          createdAt: _selectedEntry!.createdAt,
          updatedAt: DateTime.now(),
        );

        // Update in memory
        _expenseController.updateEntry(updatedEntry);

        _stopEditing();
        setState(() {});
      } catch (e) {
        debugPrint('재테크 정보 수정 중 오류: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '수정에 실패했습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Delete confirmation
  void _confirmDelete() {
    if (_selectedEntry == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isSaving = true;
              });

              try {
                // Delete from memory
                _expenseController.deleteEntry(_selectedEntry!.id);

                _stopEditing();
                setState(() {});
              } catch (e) {
                debugPrint('재테크 정보 삭제 중 오류: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '삭제에 실패했습니다.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() {
                  _isSaving = false;
                });
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Custom income type input dialog
  void _showCustomIncomeTypeDialog() {
    final TextEditingController customTypeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '직접 입력',
          style: TextStyle(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: customTypeController,
          decoration: const InputDecoration(
            hintText: '재테크 유형 입력 (10자 이내)',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
          maxLength: 10, // Max 10 characters
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final customType = customTypeController.text.trim();

              // Validate input
              if (customType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '값이 입력되어 있지 않습니다.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.grey,
                  ),
                );
                return;
              }

              // Check if option already exists
              if (_incomeTypes.contains(customType) ||
                  _customIncomeTypes.contains(customType)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '이미 존재하는 재테크 유형입니다.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppColors.grey,
                  ),
                );
                return;
              }

              // Add and select custom type
              setState(() {
                _customIncomeTypes.add(customType);
                _selectedIncomeType = customType;
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  // Show day picker dialog
  void _showDayPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => DaySelectionDialog(
        initialDay: _selectedDay,
        onDaySelected: (day) {
          setState(() {
            _selectedDay = day;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main alert dialog
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                backgroundColor: Colors.white,
                elevation: 10,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      '재테크 정보',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Income type and date selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Income type button
                        _buildIncomeTypeButton(),

                        // Only monthly frequency is active
                        const Text(
                          '매월',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Day button (opens grid dialog)
                        _buildDayButton(),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Amount input (text field or button based on mode)
                    _isEditing ? _buildTextField() : _buildAmountButton(),

                    const SizedBox(height: 20),

                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            );
          },
        ),

        // Transparent alert (list of added items)
        if (_expenseController.getAllEntries().isNotEmpty)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Delayed appearance for staggered effect
              final delayedAnimation = _animation.value > 0.2
                  ? (_animation.value - 0.2) * 1.25
                  : 0.0;
              final adjustedValue = delayedAnimation > 1.0 ? 1.0 : delayedAnimation;

              return Positioned(
                top: 80, // Position above main alert
                left: 0,
                right: 0,
                child: Transform.scale(
                  scale: adjustedValue,
                  child: _buildTransparentAlert(),
                ),
              );
            },
          ),

        // Loading indicator
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
      ],
    );
  }

  // Income type selection button
  Widget _buildIncomeTypeButton() {
    return InkWell(
      onTap: () {
        // Show income type options
        _showIncomeTypeOptions();
      },
      child: Column(
        children: [
          Text(
            _selectedIncomeType,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: primaryColor),
        ],
      ),
    );
  }

  // Show income type options
  void _showIncomeTypeOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final allTypes = [..._incomeTypes, ..._customIncomeTypes];

        return Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              const Text(
                '재테크 유형 선택',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: allTypes.length + 1, // +1 for "other" option
                  itemBuilder: (context, index) {
                    if (index == allTypes.length) {
                      // "Other" option at the end
                      return ListTile(
                        title: const Text(
                          '기타 (직접 입력)',
                          style: TextStyle(color: primaryColor),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showCustomIncomeTypeDialog();
                        },
                      );
                    }

                    final type = allTypes[index];
                    final isSelected = type == _selectedIncomeType;

                    return ListTile(
                      title: Text(
                        type,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? primaryColor : Colors.black87,
                        ),
                      ),
                      trailing: isSelected ? const Icon(Icons.check, color: primaryColor) : null,
                      onTap: () {
                        setState(() {
                          _selectedIncomeType = type;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Day selection button
  Widget _buildDayButton() {
    // Create day label with 말일 for 31st
    final dayText = _selectedDay == 31 ? '말일(31일)' : '${_selectedDay}일';

    return InkWell(
      onTap: _showDayPickerDialog, // Open the day picker dialog
      child: Column(
        children: [
          Text(
            dayText,
            style: const TextStyle(
              color: primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: primaryColor),
        ],
      ),
    );
  }

  // Amount button
  Widget _buildAmountButton() {
    return BlinkingTextButton(
      text: '금액',
      fontSize: 32,
      textColor: primaryColor,
      onTap: () => _startEditing(),
    );
  }

  // Text field for amount input
  Widget _buildTextField() {
    final Color textColor = primaryColor;

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        style: TextStyle(
          color: textColor,
          fontSize: 32,
          fontFamily: 'Noto Sans JP',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          hintText: '숫자 입력',
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.5),
            fontSize: 24,
          ),
          border: InputBorder.none,
        ),
        onChanged: (value) {
          // Add commas for thousands
          final formatted = _formatNumber(value.replaceAll(',', ''));
          if (formatted != value) {
            _textController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }
        },
      ),
    );
  }

  // Action buttons (add/update/delete)
  Widget _buildActionButtons() {
    if (_isEditing && _isUpdating) {
      // Edit mode buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _confirmDelete,
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _updateExpense,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(AppColors.primary),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              elevation: MaterialStateProperty.all(0),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            child: const Text(
              '수정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          )
        ],
      );
    } else if (_isEditing) {
      // Add mode button
      return Align(
        alignment: Alignment.bottomRight,
        child: ElevatedButton(
          onPressed: _addExpense,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(AppColors.primary),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            elevation: MaterialStateProperty.all(0),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          child: const Text(
            '추가',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else {
      // Default state buttons
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: const Text('닫기'),
          ),
          if (_expenseController.getAllEntries().isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // Show completion dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      title: const Text(
                        '설정완료',
                        style: TextStyle(
                          color: AppColors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        '수기가계부를 시작 하시겠습니까?',
                        style: TextStyle(
                          color: AppColors.black,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close alert
                          },
                          child: const Text('취소',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close alert
                            controller.completeOnboarding(); // Complete
                          },
                          child: const Text(
                            '확인',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(AppColors.primary),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                elevation: MaterialStateProperty.all(0),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      );
    }
  }

  // Transparent alert with item list
  Widget _buildTransparentAlert() {
    final entries = _expenseController.getAllEntries();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      constraints: const BoxConstraints(
        maxHeight: 180, // Height for about 3 items
      ),
      child: Material(
        type: MaterialType.transparency, // Keep transparent background
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: entries.length,
          reverse: true, // Most recent first
          itemBuilder: (context, index) {
            final entry = entries[index];

            return ListTile(
              title: Text(
                entry.getDisplayText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Noto Sans JP',
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              onTap: () => _startEditing(entry),
            );
          },
        ),
      ),
    );
  }
}