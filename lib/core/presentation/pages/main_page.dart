// lib/core/presentation/pages/main_page.dart - Updated to include AssetPage
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habp/features/expense/presentation/pages/expense_page.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../constants/app_colors.dart';
import '../controllers/main_controller.dart';
import '../../../features/calendar/presentation/pages/calendar_page.dart';
import '../../../features/quick_add/presentation/widgets/quick_add_button.dart';
import '../../../features/asset/presentation/pages/asset_page.dart'; // 자산 페이지 추가

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MainController 주입
    final controller = Get.put(MainController());

    return Obx(() {
      return Scaffold(
        // appBar: AppBar(".""?////'''''
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: const [
            DashboardPage(), // 대시보드 페이지
            CalendarPage(), // 캘린더 페이지
            SizedBox(), // 추가 버튼은 페이지가 없음
            ExpensePage(), // 지출 페이지
            AssetPage(), // 자산 페이지 - 연결
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(controller),
        floatingActionButton: const QuickAddButton(), // 새로운 QuickAddButton 사용
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }

  Widget _buildBottomNavigationBar(MainController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
              _buildNavItem(0, Icons.dashboard, '대시보드', controller),
              _buildNavItem(1, Icons.calendar_today, '캘린더', controller),
              // 가운데 공간
              const SizedBox(width: 48),
              _buildNavItem(3, Icons.account_balance_wallet, '예산', controller),
              _buildNavItem(4, Icons.account_balance_outlined, '자산', controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, MainController controller) {
    final isSelected = controller.selectedIndex.value == index;
    return InkWell(
      onTap: () => controller.changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isSelected ? const Color(0xFFE495C0) : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? const Color(0xFFE495C0) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}