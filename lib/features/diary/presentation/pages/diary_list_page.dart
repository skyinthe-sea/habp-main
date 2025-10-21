import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/monthly_diary.dart';
import '../controllers/diary_controller.dart';
import 'diary_detail_page.dart';

/// 월별 다이어리 목록 페이지
class DiaryListPage extends StatelessWidget {
  const DiaryListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final diaryController = Get.find<DiaryController>();

    return Scaffold(
      backgroundColor: themeController.isDarkMode
          ? AppColors.darkBackground
          : AppColors.background,
      appBar: AppBar(
        title: const Text('월별 다이어리'),
        backgroundColor: themeController.isDarkMode
            ? AppColors.darkSurface
            : AppColors.surface,
        elevation: 0,
      ),
      body: Obx(() {
        if (diaryController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        if (diaryController.diaries.isEmpty) {
          return _buildEmptyState(themeController);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: diaryController.diaries.length,
          itemBuilder: (context, index) {
            final diary = diaryController.diaries[index];
            return _DiaryCard(
              diary: diary,
              themeController: themeController,
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final diary = await diaryController.getOrCreateCurrentMonthDiary();
          Get.to(() => DiaryDetailPage(diary: diary));
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '이번 달 다이어리',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeController themeController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 80,
            color: themeController.isDarkMode
                ? AppColors.darkTextSecondary.withOpacity(0.5)
                : AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '아직 작성한 다이어리가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: themeController.isDarkMode
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 다이어리를 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: themeController.isDarkMode
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 다이어리 카드 위젯
class _DiaryCard extends StatelessWidget {
  final MonthlyDiary diary;
  final ThemeController themeController;

  const _DiaryCard({
    required this.diary,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => DiaryDetailPage(diary: diary));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: themeController.isDarkMode
              ? AppColors.darkSurface
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (월 정보)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diary.monthLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (diary.title != null && diary.title!.isNotEmpty)
                        Text(
                          diary.title!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 이미지 미리보기 (있을 경우)
            if (diary.images.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(diary.images.first)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

            // 콘텐츠 (메모, 스티커 개수)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (diary.memo != null && diary.memo!.isNotEmpty) ...[
                    Text(
                      diary.memo!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: themeController.isDarkMode
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      if (diary.images.isNotEmpty) ...[
                        Icon(
                          Icons.photo,
                          size: 18,
                          color: themeController.isDarkMode
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${diary.images.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeController.isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (diary.stickers.isNotEmpty) ...[
                        const Text('✨', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Text(
                          '${diary.stickers.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: themeController.isDarkMode
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
