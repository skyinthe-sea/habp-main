// lib/features/quick_add/presentation/dialogs/category_type_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import 'category_selection_dialog.dart';

/// First dialog in the quick add flow
/// Allows selecting between Income, Expense, or Finance
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
        padding: const EdgeInsets.all(20),
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
              padding: EdgeInsets.only(bottom: 20),
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

            // Three buttons for transaction types
            const SizedBox(height: 10),

            _buildTypeButton(
              context: context,
              icon: Icons.arrow_downward_rounded,
              label: '소득',
              color: Colors.green.shade600,
              type: 'INCOME',
              controller: controller,
            ),

            const SizedBox(height: 12),

            _buildTypeButton(
              context: context,
              icon: Icons.arrow_upward_rounded,
              label: '지출',
              color: Colors.red.shade600,
              type: 'EXPENSE',
              controller: controller,
            ),

            const SizedBox(height: 12),

            _buildTypeButton(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              label: '금융',
              color: Colors.blue.shade600,
              type: 'FINANCE',
              controller: controller,
            ),

            const SizedBox(height: 20),
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
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);
            final offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          barrierDismissible: true,
          barrierLabel: '',
          barrierColor: Colors.black.withOpacity(0.5),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}