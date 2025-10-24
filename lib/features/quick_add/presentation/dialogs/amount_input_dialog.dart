import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/emotion_constants.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/quick_add_controller.dart';
import '../widgets/autocomplete_text_field.dart';
import 'date_selection_dialog.dart';
import 'category_selection_dialog.dart';
import 'calculator_dialog.dart';
import 'emotion_selection_dialog.dart';
import '../services/save_animation_service.dart';

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

  // GlobalKey for tracking dialog position during animation
  final GlobalKey _dialogKey = GlobalKey();

  // Current amount stored as an integer
  int _currentAmount = 0;

  // Flag for highlight animation on amount changes
  bool _isHighlighted = false;

  // Image picker instance
  final ImagePicker _imagePicker = ImagePicker();

  // Selected image file
  File? _selectedImage;

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

    final controller = Get.find<QuickAddController>();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),  // 빠르게 작아짐
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,  // 0.0부터 시작 (완전히 작아진 상태)
      end: 1.0,    // 1.0까지 (정상 크기)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeInCubic,  // 빠르게 가속하면서 작아짐
    ));

    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Auto-focus removed - user can tap to focus when needed

    // Listen for changes to enable/disable save button
    _amountController.addListener(_updateSaveButtonState);

    // Initialize with a default amount of 0
    _amountController.text = '0';

    // Load existing image if editing transaction with imagePath
    final existingImagePath = controller.transaction.value.imagePath;
    if (existingImagePath != null && existingImagePath.isNotEmpty) {
      final imageFile = File(existingImagePath);
      if (imageFile.existsSync()) {
        _selectedImage = imageFile;
      }
    }
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

  /// Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
  }

  /// Save image to app documents directory and return the path
  Future<String?> _saveImageToLocal(File imageFile) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDocDir.path, 'transaction_images');

      // Create directory if it doesn't exist
      await Directory(imagesDir).create(recursive: true);

      // Generate unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'IMG_$timestamp${path.extension(imageFile.path)}';
      final String savePath = path.join(imagesDir, fileName);

      // Copy image to app directory
      await imageFile.copy(savePath);

      return savePath;
    } catch (e) {
      debugPrint('Error saving image to local: $e');
      return null;
    }
  }

  /// Show image in fullscreen preview
  void _showImagePreview(File imageFile) {
    final ThemeController themeController = Get.find<ThemeController>();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
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

  /// Show bottom sheet for image source selection
  void _showImageSourceSelection() {
    final ThemeController themeController = Get.find<ThemeController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: themeController.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: themeController.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: themeController.primaryColor),
              title: Text(
                '갤러리에서 선택',
                style: TextStyle(color: themeController.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: themeController.primaryColor),
              title: Text(
                '카메라로 촬영',
                style: TextStyle(color: themeController.textPrimaryColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade400),
                title: Text(
                  '사진 삭제',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
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

  /// 날짜 선택 다이얼로그 표시
  void _showDateSelectionDialog(BuildContext context, QuickAddController controller) async {
    // 키보드 닫기
    FocusScope.of(context).unfocus();

    final ThemeController themeController = Get.find<ThemeController>();
    DateTime selectedDate = controller.transaction.value.transactionDate;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Obx(() => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeController.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: themeController.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 제목
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '날짜 변경',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeController.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        color: themeController.textSecondaryColor,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 달력
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: selectedDate,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDate, day);
                    },
                    onDaySelected: (selected, focused) {
                      setState(() {
                        selectedDate = selected;
                      });
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeController.textPrimaryColor,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: themeController.primaryColor,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: themeController.primaryColor,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 0,
                      defaultTextStyle: TextStyle(
                        color: themeController.textPrimaryColor,
                      ),
                      weekendTextStyle: TextStyle(
                        color: themeController.textPrimaryColor,
                      ),
                      todayDecoration: BoxDecoration(
                        color: themeController.primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: themeController.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 버튼들
                  Row(
                    children: [
                      // 오늘 버튼
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: themeController.primaryColor,
                          ),
                          child: const Text('오늘'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 확인 버튼
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(selectedDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeController.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('확인'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          );
        },
      ),
    );

    // 결과가 있으면 날짜 업데이트
    if (result != null) {
      controller.setTransactionDate(result);
    }
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
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
                ? themeController.primaryColor
                : _amountFocusNode.hasFocus
                ? themeController.primaryColor
                : themeController.isDarkMode
                ? themeController.textSecondaryColor.withOpacity(0.3)
                : Colors.grey.shade200,
            width: _isHighlighted ? 2.0 : 1.0,
          ),
          color: themeController.surfaceColor,
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
                    color: themeController.isDarkMode
                        ? themeController.cardColor
                        : Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Text(
                    'C',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeController.textSecondaryColor,
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
                  color: _isHighlighted 
                      ? themeController.primaryColor 
                      : themeController.textPrimaryColor,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  suffixText: '원',
                  suffixStyle: TextStyle(
                    fontSize: 18,
                    color: themeController.textSecondaryColor,
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
                    color: themeController.primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: Icon(
                    Icons.calculate_rounded,
                    color: themeController.primaryColor,
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
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeController.isDarkMode
            ? themeController.cardColor
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeController.isDarkMode
              ? themeController.textSecondaryColor.withOpacity(0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // First row: 100, 500, 1000
          Row(
            children: [
              // Subtraction side (left)
              _buildOperationButton(amount: 100, isAddition: false),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 500, isAddition: false),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 1000, isAddition: false),

              // Center divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: themeController.isDarkMode
                    ? themeController.textSecondaryColor.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),

              // Addition side (right)
              _buildOperationButton(amount: 100, isAddition: true),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 500, isAddition: true),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 1000, isAddition: true),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: 5000, 10000, 100000
          Row(
            children: [
              // Subtraction side (left)
              _buildOperationButton(amount: 5000, isAddition: false),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 10000, isAddition: false),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 100000, isAddition: false),

              // Center divider
              Container(
                height: 40,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: themeController.isDarkMode
                    ? themeController.textSecondaryColor.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),

              // Addition side (right)
              _buildOperationButton(amount: 5000, isAddition: true),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 10000, isAddition: true),
              const SizedBox(width: 4),
              _buildOperationButton(amount: 100000, isAddition: true),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper method to build operation buttons
  Widget _buildOperationButton({required int amount, required bool isAddition}) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    final Color backgroundColor = isAddition
        ? themeController.primaryColor.withOpacity(0.1)
        : themeController.isDarkMode
            ? themeController.cardColor
            : Colors.grey.shade200;

    final Color textColor = isAddition
        ? themeController.primaryColor
        : themeController.textSecondaryColor;

    final IconData icon = isAddition ? Icons.add : Icons.remove;

    // Adjust font size based on amount for better readability in 2 rows
    double fontSize = 11.0;  // Larger base font size for 2-row layout
    if (amount >= 10000) {
      fontSize = 10.0; // Slightly smaller for 5-digit numbers
    }
    if (amount >= 100000) {
      fontSize = 9.0; // Smallest for 6-digit numbers
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: themeController.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(height: 1),
              Text(
                NumberFormat('#,###').format(amount),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    final ThemeController themeController = Get.find<ThemeController>();
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // 애니메이션 진행도 (1.0 = 열림, 0.0 = 닫힘)
          final progress = _scaleAnimation.value;
          final reverseProgress = 1.0 - progress;

          // Scale: 1.0 → 0.0 (완전히 작아짐)
          final scale = progress * progress; // 제곱으로 더 빠르게 작아짐

          // Opacity: 처음엔 유지하다가 마지막에 빠르게 사라짐
          final opacity = progress > 0.3 ? 1.0 : (progress / 0.3);

          // 화면 아래쪽으로 이동 (캘린더 위치로 - Y축으로 이동)
          final translateY = reverseProgress * screenSize.height * 0.4;

          // 약간 뒤로 밀리는 효과 (perspective)
          final translateX = reverseProgress * 20;

          // Border radius 애니메이션 (20 → 10 → 5로 작아짐)
          final borderRadius = 20.0 * progress;

          return Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  key: _dialogKey,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: themeController.surfaceColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: themeController.isDarkMode
                            ? Colors.black.withOpacity(0.3 * progress)
                            : Colors.black.withOpacity(0.1 * progress),
                        blurRadius: 10 * progress,
                        offset: Offset(0, 5 * progress),
                      ),
                    ],
                  ),
                  child: Column(
            children: [
              // Fixed header section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeController.surfaceColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog title and back button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Obx(() => Text(
                          '금액 입력',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeController.primaryColor,
                          ),
                        )),
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20),
                          onPressed: () {
                            // Go back to the previous dialog
                            Navigator.of(context).pop();

                            // Show the category selection dialog again
                            showGeneralDialog(
                              context: context,
                              pageBuilder: (_, __, ___) => const CategorySelectionDialog(),
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
                              barrierColor: themeController.isDarkMode
                                  ? Colors.black.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.5),
                            );
                          },
                          color: themeController.textSecondaryColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Transaction info
                    Obx(() => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeController.isDarkMode
                            ? themeController.cardColor
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: themeController.isDarkMode
                              ? themeController.textSecondaryColor.withOpacity(0.2)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '카테고리:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: themeController.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => Text(
                                  controller.transaction.value.categoryName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: themeController.textPrimaryColor,
                                  ),
                                )),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '날짜:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: themeController.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Obx(() => Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showDateSelectionDialog(context, controller),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeController.primaryColor.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: themeController.primaryColor.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: themeController.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            DateFormat('yyyy년 MM월 dd일').format(
                                                controller.transaction.value.transactionDate),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: themeController.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),

                    const SizedBox(height: 20),

                    // Amount input field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() => Text(
                          '금액',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: themeController.textPrimaryColor,
                          ),
                        )),
                        const SizedBox(height: 12),

                        // 수정된 금액 입력 필드 (계산기 버튼 추가)
                        _buildAmountField(),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable content section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick amount selection buttons with add/subtract functionality
                      _buildQuickAmountButtons(),

                      const SizedBox(height: 20),

                      // Save button - moved here right after quick amount buttons
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

                            // Set image path if selected
                            if (_selectedImage != null) {
                              controller.setImagePath(_selectedImage!.path);
                            }

                            // Get transaction info for animation
                            final targetDate = controller.transaction.value.transactionDate;

                            // Animate dialog shrinking to center point
                            await _animationController.reverse();

                            // Close dialog after animation completes
                            if (mounted) {
                              Navigator.of(context).pop();
                            }

                            // Trigger calendar marker pulse
                            SaveAnimationService.triggerMarkerPulse(
                              targetDate: targetDate,
                            );

                            // Save transaction after animation completes
                            final success = await controller.saveTransaction();

                            // Show success message if successful
                            if (success) {
                              // Show success snackbar
                              Get.snackbar(
                                '성공',
                                '거래가 추가되었습니다',
                                snackPosition: SnackPosition.TOP,
                                backgroundColor: themeController.isDarkMode ? AppColors.darkSuccess : AppColors.success,
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
                                backgroundColor: themeController.isDarkMode ? AppColors.darkError : AppColors.error,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(16),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeController.primaryColor,
                            foregroundColor: Colors.white, // 텍스트 색상 명시적 지정
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor:
                            themeController.primaryColor.withOpacity(0.3),
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

                      const SizedBox(height: 20),

                      // Description input field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                    '설명 (선택사항)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: themeController.textPrimaryColor,
                    ),
                  )),
                  const SizedBox(height: 6),
                  AutocompleteTextField(
                    controller: _descriptionController,
                    hintText: '내용을 입력하세요',
                    autocompleteService: controller.autocompleteService,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Photo attachment section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                    '영수증·사진 (선택사항)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: themeController.textPrimaryColor,
                    ),
                  )),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectedImage == null
                        ? _showImageSourceSelection
                        : null,  // Disable tap when image exists (handled by GestureDetector below)
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeController.isDarkMode
                            ? themeController.cardColor
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedImage != null
                              ? AppColors.primary.withOpacity(0.3)
                              : (themeController.isDarkMode
                                  ? themeController.textSecondaryColor.withOpacity(0.2)
                                  : Colors.grey.shade200),
                        ),
                      ),
                      child: _selectedImage == null
                          ? Row(
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: themeController.textSecondaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '영수증이나 사진을 첨부하세요',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: themeController.textSecondaryColor,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: themeController.textSecondaryColor,
                                  size: 20,
                                ),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image preview - tap to view fullscreen
                                GestureDetector(
                                  onTap: () => _showImagePreview(_selectedImage!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '사진이 첨부되었습니다',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: themeController.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '사진 탭하여 크게 보기',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeController.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Change/Remove image button
                                GestureDetector(
                                  onTap: _showImageSourceSelection,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: themeController.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      color: themeController.primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

                      // Emotion selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                            '감정 태그 (선택사항)',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: themeController.textPrimaryColor,
                            ),
                          )),
                          const SizedBox(height: 8),
                          Obx(() {
                            final emotionTag = controller.transaction.value.emotionTag;
                            return InkWell(
                              onTap: () {
                                // 포커스 해제하여 자동완성 UI 숨김
                                FocusScope.of(context).unfocus();

                                // 약간의 딜레이 후 다이얼로그 표시 (포커스 해제가 완전히 처리되도록)
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => const EmotionSelectionDialog(),
                                  );
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: themeController.isDarkMode
                                      ? themeController.cardColor
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: emotionTag != null
                                        ? AppColors.primary.withOpacity(0.3)
                                        : (themeController.isDarkMode
                                            ? themeController.textSecondaryColor.withOpacity(0.2)
                                            : Colors.grey.shade200),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      emotionTag != null
                                          ? EmotionTagHelper.getEmoji(emotionTag)
                                          : '😊',
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        emotionTag != null
                                            ? EmotionTagHelper.getLabel(emotionTag)
                                            : '지금 기분을 선택해주세요',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: emotionTag != null
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                          color: emotionTag != null
                                              ? themeController.textPrimaryColor
                                              : themeController.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: themeController.textSecondaryColor,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 8),
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
        },
      ),
    );
  }
}