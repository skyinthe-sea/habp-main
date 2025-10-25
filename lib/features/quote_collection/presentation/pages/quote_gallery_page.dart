// lib/features/quote_collection/presentation/pages/quote_gallery_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/services/daily_quote_service.dart';

/// Gallery page to view all collected quotes
class QuoteGalleryPage extends StatefulWidget {
  const QuoteGalleryPage({Key? key}) : super(key: key);

  @override
  State<QuoteGalleryPage> createState() => _QuoteGalleryPageState();
}

class _QuoteGalleryPageState extends State<QuoteGalleryPage> {
  final DailyQuoteService _quoteService = DailyQuoteService();

  /// Get category icon
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '저축':
        return Icons.savings;
      case '투자':
        return Icons.trending_up;
      case '목표':
        return Icons.flag;
      case '습관':
        return Icons.auto_awesome;
      case '빚':
        return Icons.credit_card_off;
      case '지식':
        return Icons.school;
      default:
        return Icons.workspace_premium;
    }
  }

  /// Get category color
  Color _getCategoryColor(String category) {
    switch (category) {
      case '저축':
        return const Color(0xFF10B981);
      case '투자':
        return const Color(0xFF8B5CF6);
      case '목표':
        return const Color(0xFFF59E0B);
      case '습관':
        return const Color(0xFF3B82F6);
      case '빚':
        return const Color(0xFFEF4444);
      case '지식':
        return const Color(0xFF06B6D4);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote, ThemeController themeController) {
    final String quoteText = quote['quote_text'] as String;
    final String? author = quote['author'] as String?;
    final String category = quote['category'] as String;
    final String? viewedDateStr = quote['viewed_date'] as String?;
    final categoryColor = _getCategoryColor(category);
    final categoryIcon = _getCategoryIcon(category);

    DateTime? viewedDate;
    if (viewedDateStr != null) {
      try {
        viewedDate = DateTime.parse(viewedDateStr);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        categoryIcon,
                        size: 14,
                        color: categoryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Collection date
                if (viewedDate != null)
                  Text(
                    DateFormat('yyyy.MM.dd').format(viewedDate),
                    style: TextStyle(
                      fontSize: 11,
                      color: themeController.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Quote text
            Text(
              '"$quoteText"',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: themeController.textPrimaryColor,
              ),
            ),

            if (author != null && author.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '- $author',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: categoryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      backgroundColor: themeController.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeController.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeController.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '명언 컬렉션',
          style: TextStyle(
            color: themeController.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: FutureBuilder<Map<String, int>>(
            future: _quoteService.getCollectionStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(height: 50);
              }

              final stats = snapshot.data!;
              final collected = stats['collected'] ?? 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                width: double.infinity,
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$collected개 수집',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: themeController.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _quoteService.getCollectedQuotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 64,
                    color: themeController.textSecondaryColor.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아직 수집한 명언이 없어요',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeController.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '매일 새로운 명언을 만나보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeController.textSecondaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final quotes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return _buildQuoteCard(quotes[index], themeController);
            },
          );
        },
      ),
    );
  }
}
