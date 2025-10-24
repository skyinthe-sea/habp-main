import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/emotion_constants.dart';
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
  String? _selectedEmotionTag;
  bool _isLoading = false;

  // Image picker and selected image
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _originalImagePath;

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
    _selectedEmotionTag = widget.transaction.emotionTag;

    // Load existing image if available
    _originalImagePath = widget.transaction.imagePath;
    debugPrint('🔍 [EditTransactionDialog] initState - imagePath from transaction: $_originalImagePath');

    if (_originalImagePath != null && _originalImagePath!.isNotEmpty) {
      final imageFile = File(_originalImagePath!);
      final fileExists = imageFile.existsSync();
      debugPrint('🔍 [EditTransactionDialog] Image file exists: $fileExists at path: $_originalImagePath');

      if (fileExists) {
        _selectedImage = imageFile;
        debugPrint('✅ [EditTransactionDialog] Image loaded successfully');
      } else {
        debugPrint('❌ [EditTransactionDialog] Image file does not exist');
      }
    } else {
      debugPrint('ℹ️ [EditTransactionDialog] No image path in transaction');
    }
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
                  decoration: const BoxDecoration(
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
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  '사진 제거',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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

      // Determine final image path
      String? finalImagePath;
      if (_selectedImage != null) {
        // Use the selected image path directly
        finalImagePath = _selectedImage!.path;
        debugPrint('💾 [EditTransactionDialog] Saving with image path: $finalImagePath');
      } else {
        // Image was removed
        finalImagePath = null;
        debugPrint('💾 [EditTransactionDialog] Saving without image (removed or never set)');
      }

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
        emotionTag: _selectedEmotionTag,
        imagePath: finalImagePath,
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

                        const SizedBox(height: 16),

                        // 금액 입력
                        _buildAmountField(),

                        const SizedBox(height: 16),

                        // 날짜 및 시간 선택
                        _buildDateTimeFields(),

                        const SizedBox(height: 16),

                        // 감정 선택
                        _buildEmotionField(),

                        const SizedBox(height: 16),

                        // 사진 첨부
                        _buildPhotoField(),

                        const SizedBox(height: 24),

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
              fontSize: 15,
              color: themeController.textPrimaryColor,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: '거래 내용을 입력하세요',
              hintStyle: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 15,
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
              fontSize: 15,
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
              hintText: '0',
              hintStyle: TextStyle(
                color: themeController.textSecondaryColor,
                fontSize: 15,
              ),
              suffix: Text(
                '원',
                style: TextStyle(
                  fontSize: 15,
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

    // 시간을 24시간 형식으로 포맷
    String formatTime24(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

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
        // 날짜 선택
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
              color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: themeController.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('yyyy년 M월 d일').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 15,
                    color: themeController.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 시간 선택
        GestureDetector(
          onTap: _selectTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
              color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: themeController.primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  formatTime24(_selectedTime),
                  style: TextStyle(
                    fontSize: 15,
                    color: themeController.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionField() {
    final ThemeController themeController = Get.find<ThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '감정 태그 (선택사항)',
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
            border: Border.all(
              color: _selectedEmotionTag != null
                  ? AppColors.primary.withOpacity(0.3)
                  : (themeController.isDarkMode ? Colors.grey.shade600 : AppColors.lightGrey),
            ),
            color: themeController.isDarkMode ? Colors.grey.shade800 : Colors.grey[50],
          ),
          child: Column(
            children: [
              // 현재 선택된 감정 표시
              InkWell(
                onTap: () {
                  // 포커스 해제
                  FocusScope.of(context).unfocus();

                  // 감정 선택 바텀시트 표시
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _showEmotionPicker();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        _selectedEmotionTag != null
                            ? EmotionTagHelper.getEmoji(_selectedEmotionTag)
                            : '😊',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedEmotionTag != null
                              ? EmotionTagHelper.getLabel(_selectedEmotionTag)
                              : '감정을 선택해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: _selectedEmotionTag != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                            color: _selectedEmotionTag != null
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoField() {
    final ThemeController themeController = Get.find<ThemeController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '영수증·사진 (선택사항)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeController.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectedImage == null ? _showImageSourceSelection : null,
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
                        ? Colors.grey.shade600
                        : AppColors.lightGrey),
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
    );
  }

  void _showEmotionPicker() {
    final ThemeController themeController = Get.find<ThemeController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: themeController.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeController.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Happy
            _buildEmotionOption(EmotionTag.happy, '기분 좋을 때'),
            const SizedBox(height: 12),

            // Neutral
            _buildEmotionOption(EmotionTag.neutral, '보통'),
            const SizedBox(height: 12),

            // Stressed
            _buildEmotionOption(EmotionTag.stressed, '스트레스받을 때'),
            const SizedBox(height: 12),

            // None
            _buildEmotionOption(null, '선택 안함'),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ).then((_) {
      // 바텀시트가 닫힌 후 포커스 해제
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          FocusScope.of(context).unfocus();
        }
      });
    });
  }

  Widget _buildEmotionOption(String? emotionTag, String label) {
    final ThemeController themeController = Get.find<ThemeController>();
    final isSelected = _selectedEmotionTag == emotionTag;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEmotionTag = emotionTag;
        });
        Get.back();
        // 바텀시트 닫은 후 포커스 해제
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            FocusScope.of(context).unfocus();
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (themeController.isDarkMode
                    ? Colors.grey.shade600
                    : AppColors.lightGrey),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (emotionTag != null) ...[
              Text(
                EmotionTagHelper.getEmoji(emotionTag),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 16),
            ] else ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: themeController.textSecondaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.block,
                  size: 18,
                  color: themeController.textSecondaryColor,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primary
                      : themeController.textPrimaryColor,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
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