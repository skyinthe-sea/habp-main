import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/emotion_constants.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/quick_add_controller.dart';

/// Dialog for selecting emotion tag and writing diary during quick add flow
class EmotionSelectionDialog extends StatefulWidget {
  const EmotionSelectionDialog({Key? key}) : super(key: key);

  @override
  State<EmotionSelectionDialog> createState() => _EmotionSelectionDialogState();
}

class _EmotionSelectionDialogState extends State<EmotionSelectionDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final QuickAddController _controller = Get.find<QuickAddController>();
  final TextEditingController _diaryController = TextEditingController();

  String? _selectedEmotion;

  @override
  void initState() {
    super.initState();

    // Initialize with current emotion tag if exists
    _selectedEmotion = _controller.transaction.value.emotionTag;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _diaryController.dispose();
    super.dispose();
  }

  void _selectEmotion(String emotion) {
    setState(() {
      _selectedEmotion = emotion;
    });
  }

  void _confirm() {
    _controller.setEmotionTag(_selectedEmotion);
    // TODO: Save diary text when diary feature is implemented in the data model
    Get.back();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.context != null) {
        FocusScope.of(Get.context!).unfocus();
      }
    });
  }

  void _cancel() {
    Get.back();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.context != null) {
        FocusScope.of(Get.context!).unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: themeController.isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                '오늘 하루, 어떠셨나요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '감정을 선택하고 간단한 일기를 남겨보세요',
                style: TextStyle(
                  fontSize: 15,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Emotion section label
              Text(
                '기분',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Horizontal emotion selector
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: EmotionTag.values.length,
                  itemBuilder: (context, index) {
                    final emotion = EmotionTag.values[index];
                    final isSelected = _selectedEmotion == emotion;

                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < EmotionTag.values.length - 1 ? 12 : 0,
                      ),
                      child: _buildEmotionChip(
                        emotion: emotion,
                        emoji: EmotionTagHelper.getEmoji(emotion),
                        label: EmotionTagHelper.getLabel(emotion),
                        isSelected: isSelected,
                        themeController: themeController,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Diary section label
              Text(
                '한 줄 일기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Diary text field
              TextField(
                controller: _diaryController,
                maxLines: 3,
                maxLength: 100,
                style: TextStyle(
                  fontSize: 15,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '오늘 있었던 일을 간단히 적어보세요...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: themeController.isDarkMode
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : AppColors.textSecondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: themeController.isDarkMode
                      ? AppColors.darkTextSecondary.withOpacity(0.1)
                      : AppColors.textSecondary.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: themeController.isDarkMode
                          ? AppColors.darkTextSecondary.withOpacity(0.2)
                          : AppColors.textSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: themeController.isDarkMode
                              ? AppColors.darkTextSecondary.withOpacity(0.3)
                              : AppColors.textSecondary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: themeController.isDarkMode
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedEmotion != null ? _confirm : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: themeController.isDarkMode
                            ? AppColors.darkTextSecondary.withOpacity(0.2)
                            : AppColors.textSecondary.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _selectedEmotion != null
                              ? Colors.white
                              : (themeController.isDarkMode
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionChip({
    required String emotion,
    required String emoji,
    required String label,
    required bool isSelected,
    required ThemeController themeController,
  }) {
    return GestureDetector(
      onTap: () => _selectEmotion(emotion),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (themeController.isDarkMode
                  ? AppColors.darkTextSecondary.withOpacity(0.1)
                  : AppColors.textSecondary.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (themeController.isDarkMode
                    ? AppColors.darkTextSecondary.withOpacity(0.2)
                    : AppColors.textSecondary.withOpacity(0.2)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: isSelected ? 36 : 32,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
