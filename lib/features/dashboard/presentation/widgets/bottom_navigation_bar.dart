import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/controllers/theme_controller.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() => Container(
      decoration: BoxDecoration(
        color: themeController.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard, '대시보드', themeController),
              _buildNavItem(1, Icons.calendar_today, '캘린더', themeController),
              _buildAddButton(themeController),
              _buildNavItem(3, Icons.account_balance_wallet, '지출', themeController),
              _buildNavItem(4, Icons.settings, '설정', themeController),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeController themeController) {
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected 
                ? themeController.primaryColor 
                : themeController.textSecondaryColor,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected 
                  ? themeController.primaryColor 
                  : themeController.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(ThemeController themeController) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: themeController.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeController.primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}