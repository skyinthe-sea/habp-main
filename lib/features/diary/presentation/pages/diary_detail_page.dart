import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/monthly_diary.dart';
import '../../domain/entities/diary_sticker.dart';
import '../controllers/diary_controller.dart';
import '../widgets/sticker_picker_dialog.dart';

/// 다이어리 상세/편집 페이지
class DiaryDetailPage extends StatefulWidget {
  final MonthlyDiary diary;

  const DiaryDetailPage({Key? key, required this.diary}) : super(key: key);

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  late List<String> _images;
  late List<DiarySticker> _stickers;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.diary.title);
    _memoController = TextEditingController(text: widget.diary.memo);
    _images = List.from(widget.diary.images);
    _stickers = List.from(widget.diary.stickers);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _images.add(image.path);
        });
      }
    } catch (e) {
      Get.snackbar('오류', '이미지를 선택하는데 실패했습니다: $e');
    }
  }

  Future<void> _addSticker() async {
    final sticker = await showDialog<DiarySticker>(
      context: context,
      builder: (context) => const StickerPickerDialog(),
    );

    if (sticker != null) {
      setState(() {
        _stickers.add(sticker);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _removeSticker(int index) {
    setState(() {
      _stickers.removeAt(index);
    });
  }

  Future<void> _saveDiary() async {
    final diaryController = Get.find<DiaryController>();

    final updatedDiary = widget.diary.copyWith(
      title: _titleController.text.trim().isEmpty
          ? null
          : _titleController.text.trim(),
      memo: _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim(),
      images: _images,
      stickers: _stickers,
      updatedAt: DateTime.now(),
    );

    if (widget.diary.id == null) {
      await diaryController.createDiary(updatedDiary);
    } else {
      await diaryController.updateDiary(updatedDiary);
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: themeController.isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        title: Text('${widget.diary.monthLabel} 다이어리'),
        backgroundColor: themeController.isDarkMode
            ? AppColors.darkSurface
            : AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveDiary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 입력
            Text(
              '제목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '${widget.diary.monthLabel}의 한 줄 요약',
                hintStyle: TextStyle(
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                fillColor: themeController.isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 메모 입력
            Text(
              '메모',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: themeController.isDarkMode
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '이번 달은 어땠나요? 자유롭게 기록해보세요 ✍️',
                hintStyle: TextStyle(
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                fillColor: themeController.isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 24),

            // 사진 섹션
            Row(
              children: [
                Text(
                  '사진',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate, size: 20),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildImageGrid(themeController),
            const SizedBox(height: 24),

            // 스티커 섹션
            Row(
              children: [
                Text(
                  '스티커',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeController.isDarkMode
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSticker,
                  icon: const Text('✨', style: TextStyle(fontSize: 20)),
                  label: const Text('추가'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStickerList(themeController),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(ThemeController themeController) {
    if (_images.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface.withOpacity(0.5)
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeController.isDarkMode
                ? AppColors.darkTextSecondary.withOpacity(0.3)
                : AppColors.textSecondary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: themeController.isDarkMode
                    ? AppColors.darkTextSecondary.withOpacity(0.5)
                    : AppColors.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '사진을 추가해보세요',
                style: TextStyle(
                  fontSize: 14,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(_images[index])),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStickerList(ThemeController themeController) {
    if (_stickers.isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface.withOpacity(0.5)
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeController.isDarkMode
                ? AppColors.darkTextSecondary.withOpacity(0.3)
                : AppColors.textSecondary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '스티커로 다이어리를 꾸며보세요 ✨',
            style: TextStyle(
              fontSize: 14,
              color: themeController.isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _stickers.asMap().entries.map((entry) {
        final index = entry.key;
        final sticker = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: themeController.isDarkMode
                ? AppColors.darkSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sticker.value,
                style: TextStyle(fontSize: 20 * sticker.size),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeSticker(index),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: themeController.isDarkMode
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
