// lib/features/settings/presentation/widgets/app_info_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({Key? key}) : super(key: key);

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: themeController.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeController.isDarkMode 
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // 앱 로고 및 정보 헤더
            _buildHeader(themeController),

            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: themeController.cardColor,
                border: Border(
                  bottom: BorderSide(
                    color: themeController.isDarkMode 
                        ? Colors.grey.shade700
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '정보'),
                  Tab(text: '라이선스'),
                ],
                labelColor: themeController.primaryColor,
                unselectedLabelColor: themeController.textSecondaryColor,
                indicatorColor: themeController.primaryColor,
                indicatorWeight: 3,
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(themeController),
                  _buildLicenseTab(themeController),
                ],
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeController.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: themeController.isDarkMode 
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeController.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 앱 로고 및 정보 헤더
  // Replace the _buildHeader method in app_info_dialog.dart with this:

  Widget _buildHeader(ThemeController themeController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeController.primaryColor.withOpacity(0.8),
            themeController.primaryColor,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // 앱 로고
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 40,
                    color: themeController.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 앱 이름
              const Text(
                '수기가계부',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // 버전 표시 제거
            ],
          ),

          // 닫기 버튼 - Now properly positioned in a Stack
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  // 정보 탭
  Widget _buildAboutTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 소개
          Text(
            '앱 소개',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '수기가계부는 개인 자산과 지출을 쉽고 효과적으로 관리할 수 있는 앱입니다. '
                '다양한 자산 유형을 관리하고, 지출을 추적하며, 예산을 설정하여 재정 목표를 달성하세요.',
            style: TextStyle(
              fontSize: 15,
              color: themeController.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 주요 기능
          Text(
            '주요 기능',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            themeController,
            '자산 관리',
            '부동산, 예금, 주식 등 다양한 자산을 등록하고 현황을 확인하세요.',
          ),
          _buildFeatureItem(
            themeController,
            '지출 추적',
            '일별, 월별 지출을 추적하고 카테고리별로 분석하세요.',
          ),
          _buildFeatureItem(
            themeController,
            '예산 설정',
            '카테고리별 예산을 설정하고 지출 상황을 모니터링하세요.',
          ),
          _buildFeatureItem(
            themeController,
            '달력 보기',
            '캘린더에서 일별 거래 내역을 확인하고 관리하세요.',
          ),
          _buildFeatureItem(
            themeController,
            '통계 및 분석',
            '소득, 지출, 자산에 대한 다양한 분석과 인사이트를 얻으세요.',
          ),
          const SizedBox(height: 24),

          // 개인정보 처리방침 및 이용약관
          Text(
            '약관 및 정책',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyButton(
            themeController,
            '개인정보 처리방침',
            'https://doc-hosting.flycricket.io/sugigagyebu-privacy-policy/20e1f1f2-7680-4e8f-8251-53c7ac83e8f7/privacy',
          ),
          const SizedBox(height: 8),
          _buildPolicyButton(
            themeController,
            '이용약관',
            'https://doc-hosting.flycricket.io/sugigagyebu-terms-of-use/73d9c4a4-0948-41fc-a8b0-20a01a367248/terms',
          ),
        ],
      ),
    );
  }


  // 라이선스 탭
  Widget _buildLicenseTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오픈소스 라이선스',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '이 앱은 다음과 같은 오픈소스 라이브러리를 사용하고 있습니다.',
            style: TextStyle(
              fontSize: 15,
              color: themeController.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildLicenseItem(
            themeController,
            title: 'Flutter',
            description: 'Google의 UI 툴킷으로, 하나의 코드베이스로 모바일, 웹, 데스크톱 앱을 제작할 수 있습니다.',
            url: 'https://flutter.dev',
            license: 'BSD 3-Clause License',
          ),
          _buildLicenseItem(
            themeController,
            title: 'GetX',
            description: '상태 관리, 의존성 주입, 라우트 관리를 위한 라이브러리입니다.',
            url: 'https://pub.dev/packages/get',
            license: 'MIT License',
          ),
          _buildLicenseItem(
            themeController,
            title: 'FL Chart',
            description: '차트 시각화를 위한 라이브러리로, 다양한 유형의 차트를 제공합니다.',
            url: 'https://pub.dev/packages/fl_chart',
            license: 'BSD 3-Clause License',
          ),
          _buildLicenseItem(
            themeController,
            title: 'Table Calendar',
            description: '캘린더 UI를 제공하는 라이브러리입니다.',
            url: 'https://pub.dev/packages/table_calendar',
            license: 'Apache License 2.0',
          ),
          _buildLicenseItem(
            themeController,
            title: 'Intl',
            description: '국제화 및 지역화 기능을 제공하는 라이브러리입니다.',
            url: 'https://pub.dev/packages/intl',
            license: 'BSD License',
          ),
          _buildLicenseItem(
            themeController,
            title: 'URL Launcher',
            description: '앱에서 외부 링크를 열기 위한 라이브러리입니다.',
            url: 'https://pub.dev/packages/url_launcher',
            license: 'BSD License',
          ),
          _buildLicenseItem(
            themeController,
            title: 'Shared Preferences',
            description: '간단한 데이터 저장을 위한 키-값 스토리지 라이브러리입니다.',
            url: 'https://pub.dev/packages/shared_preferences',
            license: 'BSD License',
          ),
          const SizedBox(height: 16),
          Text(
            '각 라이브러리의 상세 라이선스 정보는 해당 링크를 통해 확인하실 수 있습니다.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: themeController.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // 기능 아이템 위젯
  Widget _buildFeatureItem(ThemeController themeController, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: themeController.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: themeController.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: themeController.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 정책 버튼 위젯
  Widget _buildPolicyButton(ThemeController themeController, String title, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: themeController.isDarkMode 
              ? Colors.grey.shade800.withOpacity(0.3)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeController.isDarkMode 
                ? Colors.grey.shade600
                : Colors.grey.shade300
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: themeController.textPrimaryColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: themeController.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }



  // 라이선스 아이템 위젯
  Widget _buildLicenseItem(
    ThemeController themeController, {
    required String title,
    required String description,
    required String url,
    required String license,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeController.isDarkMode 
              ? Colors.grey.shade700
              : Colors.grey.shade200
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeController.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      license,
                      style: TextStyle(
                        fontSize: 12,
                        color: themeController.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _launchUrl(url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeController.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: themeController.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '링크',
                        style: TextStyle(
                          fontSize: 12,
                          color: themeController.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: themeController.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // URL 실행 함수
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}

// 다이얼로그 표시 확장 함수
extension AppInfoDialogExtension on GetInterface {
  Future<void> showAppInfoDialog() {
    return Get.dialog(
      const AppInfoDialog(),
      barrierDismissible: true,
    );
  }
}