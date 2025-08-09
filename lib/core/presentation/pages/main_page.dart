import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:habp/features/expense/presentation/pages/expense_page.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../constants/app_colors.dart';
import '../../services/ad_service.dart';
import '../../services/version_check_service.dart';
import '../controllers/main_controller.dart';
import '../../../features/calendar/presentation/pages/calendar_page.dart';
import '../../../features/quick_add/presentation/widgets/quick_add_button.dart';
import '../../../features/asset/presentation/pages/asset_page.dart';
import '../../../features/settings/presentation/widgets/settings_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainController controller;

  @override
  void initState() {
    super.initState();
    // MainController 주입
    controller = Get.put(MainController());
    
    // 버전 체크 (앱 실행 시)
    _checkAppVersion();
  }
  
  void _checkAppVersion() async {
    try {
      // VersionCheckService가 등록되어 있지 않다면 등록
      if (!Get.isRegistered<VersionCheckService>()) {
        final versionService = VersionCheckService();
        await versionService.init();
        Get.put(versionService);
      }
      
      // 버전 체크 실행
      final versionService = Get.find<VersionCheckService>();
      final result = await versionService.checkVersion();
      
      // 업데이트가 필요한 경우 다이얼로그 표시
      if (result['needsUpdate'] == true) {
        versionService.showUpdateDialog(
          context: context,
          latestVersion: result['latestVersion'],
          message: result['updateMessage'],
          forceUpdate: result['forceUpdate'] ?? false,
        );
      }
    } catch (e) {
      debugPrint('버전 체크 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            '수기가계부',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.primary),
              onPressed: () => Get.showSettingsDialog(),
              tooltip: '설정',
            ),
          ],
        ),
        body: Column(
          children: [
            // 애드몹 배너 광고 - 개선된 방식으로 표시
            Builder(
              builder: (context) {
                // 키 추가를 통해 위젯 재사용 방지
                return Container(
                  key: const ValueKey('ad_container'),
                  width: MediaQuery.of(context).size.width, // 화면 너비 전체 사용
                  padding: EdgeInsets.zero, // 패딩 제거
                  margin: EdgeInsets.zero, // 마진 제거
                  child: Get.find<AdService>().getBannerAdWidget(),
                );
              }
            ),

            // 나머지 콘텐츠
            Expanded(
              child: IndexedStack(
                index: controller.selectedIndex.value,
                children: const [
                  DashboardPage(),
                  CalendarPage(),
                  SizedBox(),
                  ExpensePage(),
                  AssetPage(),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: const QuickAddButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      );
    });
  }

  Widget _buildBottomNavigationBar() {
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
              _buildNavItem(0, Icons.dashboard, '대시보드'),
              _buildNavItem(1, Icons.calendar_today, '캘린더'),
              // 가운데 공간
              const SizedBox(width: 48),
              _buildNavItem(3, Icons.account_balance_wallet, '예산'),
              _buildNavItem(4, Icons.account_balance_outlined, '자산'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
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