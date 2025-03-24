// lib/features/quick_add/presentation/widgets/quick_add_button.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/quick_add_controller.dart';
import '../dialogs/category_type_dialog.dart';

/// QuickAdd button widget that replaces the FloatingActionButton in MainPage
/// Handles the initial animation and shows the first dialog when tapped
class QuickAddButton extends StatelessWidget {
  const QuickAddButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize the controller if not already done
    final controller = Get.put(QuickAddController());

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE495C0), Color(0xFFD279A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE495C0).withOpacity(0.4),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          // Show the initial category type selection dialog
          _showCategoryTypeDialog(context);
        },
      ),
    );
  }

  /// Shows the first dialog for selecting transaction type (Income, Expense, Finance)
  void _showCategoryTypeDialog(BuildContext context) {
    // Add a little scale animation when opening the dialog
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => const CategoryTypeDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack, // Snappy animation curve
        );

        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}