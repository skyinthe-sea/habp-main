import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/diary_sticker.dart';

/// 스티커 선택 다이얼로그
class StickerPickerDialog extends StatefulWidget {
  const StickerPickerDialog({Key? key}) : super(key: key);

  @override
  State<StickerPickerDialog> createState() => _StickerPickerDialogState();
}

class _StickerPickerDialogState extends State<StickerPickerDialog> {
  // 스티커 카테고리
  final List<Map<String, dynamic>> _stickerCategories = [
    {
      'name': '감정',
      'stickers': ['😊', '😃', '😍', '🥰', '😎', '🤗', '😌', '😇', '🥳', '🤩'],
    },
    {
      'name': '날씨',
      'stickers': ['☀️', '🌤️', '⛅', '🌥️', '☁️', '🌧️', '⛈️', '🌩️', '🌨️', '⛄'],
    },
    {
      'name': '음식',
      'stickers': ['🍕', '🍔', '🍟', '🌭', '🍿', '🧋', '☕', '🍰', '🍪', '🍩'],
    },
    {
      'name': '활동',
      'stickers': ['✈️', '🚗', '🎬', '🎮', '📚', '🎨', '🏃', '💤', '🛍️', '🎵'],
    },
    {
      'name': '기타',
      'stickers': ['❤️', '💙', '💚', '💛', '💜', '⭐', '✨', '🌈', '🔥', '💪'],
    },
  ];

  String _selectedCategory = '감정';

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Text(
                    '✨',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '스티커 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: themeController.isDarkMode
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: themeController.isDarkMode
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            // 카테고리 탭
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _stickerCategories.map((category) {
                  final isSelected = _selectedCategory == category['name'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category['name'] as String;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (themeController.isDarkMode
                                ? AppColors.darkBackground
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          category['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (themeController.isDarkMode
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 스티커 그리드
            Expanded(
              child: _buildStickerGrid(themeController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerGrid(ThemeController themeController) {
    final category = _stickerCategories.firstWhere(
      (cat) => cat['name'] == _selectedCategory,
    );
    final stickers = category['stickers'] as List<String>;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: stickers.length,
      itemBuilder: (context, index) {
        final sticker = stickers[index];
        return GestureDetector(
          onTap: () {
            final diarySticker = DiarySticker(
              type: 'emoji',
              value: sticker,
              x: 0.5,
              y: 0.5,
              size: 1.0,
            );
            Get.back(result: diarySticker);
          },
          child: Container(
            decoration: BoxDecoration(
              color: themeController.isDarkMode
                  ? AppColors.darkBackground
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: themeController.isDarkMode
                    ? AppColors.darkTextSecondary.withOpacity(0.2)
                    : Colors.grey.shade200,
              ),
            ),
            child: Center(
              child: Text(
                sticker,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}
