// lib/features/quick_add/presentation/dialogs/category_type_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../controllers/quick_add_controller.dart';
import 'category_selection_dialog.dart';

/// First dialog in the quick add flow
/// Allows selecting between Income, Expense and Finance
class CategoryTypeDialog extends StatelessWidget {
  const CategoryTypeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();
    final ThemeController themeController = Get.find<ThemeController>();

    // Reset transaction when dialog opens
    controller.resetTransaction();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        // 패딩 값을 줄여서 오버플로우 문제 해결
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        decoration: BoxDecoration(
          color: themeController.cardColor,
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
          children: [
            // Dialog title
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '어떤 거래 입니까?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeController.primaryColor,
                ),
              ),
            ),

            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                color: themeController.textSecondaryColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),


            // 재테크 버튼 - 별도 행에 배치
            _buildTypeButton(
              context: context,
              icon: Icons.account_balance_rounded, // 재테크 관련 아이콘
              label: '재테크',
              color: themeController.isDarkMode ? Colors.blue.shade400 : const Color(0xFF4990E2), // 푸른계통 색상
              type: 'FINANCE',
              controller: controller,
              backgroundColor: themeController.isDarkMode 
                  ? Colors.blue.withOpacity(0.15) 
                  : const Color(0xFFECF4FC), // 연한 푸른색 배경
              themeController: themeController,
              fullWidth: true, // 전체 너비 사용
            ),

            const SizedBox(height: 10), // 하단 여백 감소

            // 소득/지출 버튼을 가로로 배치
            Row(
              children: [
                // 소득 버튼 - 좌측 배치, 확장
                Expanded(
                  child: _buildTypeButton(
                    context: context,
                    icon: Icons.monetization_on,
                    label: '소득',
                    color: themeController.isDarkMode ? Colors.green.shade400 : Colors.green[600]!,
                    type: 'INCOME',
                    controller: controller,
                    backgroundColor: themeController.isDarkMode 
                        ? Colors.green.withOpacity(0.15) 
                        : const Color(0xFFEDF7ED), // 연한 배경색
                    themeController: themeController,
                  ),
                ),

                const SizedBox(width: 10), // 간격 줄임

                // 지출 버튼 - 우측 배치, 확장
                Expanded(
                  child: _buildTypeButton(
                    context: context,
                    icon: Icons.payment,
                    label: '지출',
                    color: themeController.primaryColor,
                    type: 'EXPENSE',
                    controller: controller,
                    backgroundColor: themeController.isDarkMode 
                        ? themeController.primaryColor.withOpacity(0.15) 
                        : const Color(0xFFFCEEF0), // 연한 배경색
                    themeController: themeController,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10), // 버튼 사이 간격
          ],
        ),
      ),
    );
  }

  /// Builds a stylized button for each transaction type
  Widget _buildTypeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String type,
    required QuickAddController controller,
    required Color backgroundColor,
    required ThemeController themeController,
    bool fullWidth = false, // 전체 너비 사용 여부
  }) {
    return InkWell(
      onTap: () {
        // Set the transaction type and show the next dialog
        controller.setCategoryType(type);

        // Close this dialog and show the next one with smooth transition
        Navigator.of(context).pop();

        // Show category selection dialog with animation
        showGeneralDialog(
          context: context,
          pageBuilder: (_, __, ___) => const CategorySelectionDialog(),
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            // 풍선 터지는 효과를 위한 커브 설정
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut, // 풍선 튕김 효과
            );

            // 크기 애니메이션을 적용
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
      child: Container(
        width: fullWidth ? double.infinity : null,
        // 높이 조정 - 오버플로우 방지하면서 버튼 크기 키움
        height: 100, // 80에서 100으로 증가
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeController.isDarkMode 
                ? color.withOpacity(0.6)
                : color.withOpacity(0.3)
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36), // 아이콘 크기 증가
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 20, // 글자 크기 증가
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}