// lib/features/quick_add/presentation/dialogs/category_type_dialog.dart 파일 수정

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'category_selection_dialog.dart';

/// First dialog in the quick add flow
/// Allows selecting between Income and Expense
class CategoryTypeDialog extends StatelessWidget {
  const CategoryTypeDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuickAddController>();

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
          children: [
            // Dialog title
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '추가하기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.grey,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),

            // 소득/지출 버튼을 가로로 배치
            Row(
              children: [
                // 소득 버튼 - 좌측 배치, 확장
                Expanded(
                  child: _buildTypeButton(
                    context: context,
                    icon: Icons.arrow_downward_rounded,
                    label: '소득',
                    color: AppColors.primary, // 메인 색상으로 통일
                    type: 'INCOME',
                    controller: controller,
                    backgroundColor: const Color(0xFFEDF7ED), // 연한 배경색
                  ),
                ),

                const SizedBox(width: 10), // 간격 줄임

                // 지출 버튼 - 우측 배치, 확장
                Expanded(
                  child: _buildTypeButton(
                    context: context,
                    icon: Icons.arrow_upward_rounded,
                    label: '지출',
                    color: AppColors.primary, // 메인 색상으로 통일
                    type: 'EXPENSE',
                    controller: controller,
                    backgroundColor: const Color(0xFFFCEEF0), // 연한 배경색
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10), // 하단 여백 감소
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
        width: double.infinity,
        // 높이 감소 - 오버플로우 방지
        height: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}