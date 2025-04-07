// lib/features/settings/presentation/widgets/app_info_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // 앱 로고 및 정보 헤더
            _buildHeader(),

            // 탭 바
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: '정보'),
                  Tab(text: '개발팀'),
                  Tab(text: '라이선스'),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
              ),
            ),

            // 탭 컨텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildTeamTab(),
                  _buildLicenseTab(),
                ],
              ),
            ),

            // 하단 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
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
                    backgroundColor: AppColors.primary,
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
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
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
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 앱 이름
          const Text(
            '우리 정이 가계부',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // 앱 버전
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '버전 1.0.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 닫기 버튼
          Positioned(
            top: 16,
            right: 16,
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
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 소개
          const Text(
            '앱 소개',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '우리 정이 가계부는 개인 자산과 지출을 쉽고 효과적으로 관리할 수 있는 앱입니다. '
                '다양한 자산 유형을 관리하고, 지출을 추적하며, 예산을 설정하여 재정 목표를 달성하세요.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 주요 기능
          const Text(
            '주요 기능',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            '자산 관리',
            '부동산, 예금, 주식 등 다양한 자산을 등록하고 현황을 확인하세요.',
          ),
          _buildFeatureItem(
            '지출 추적',
            '일별, 월별 지출을 추적하고 카테고리별로 분석하세요.',
          ),
          _buildFeatureItem(
            '예산 설정',
            '카테고리별 예산을 설정하고 지출 상황을 모니터링하세요.',
          ),
          _buildFeatureItem(
            '달력 보기',
            '캘린더에서 일별 거래 내역을 확인하고 관리하세요.',
          ),
          _buildFeatureItem(
            '통계 및 분석',
            '소득, 지출, 자산에 대한 다양한 분석과 인사이트를 얻으세요.',
          ),
          const SizedBox(height: 24),

          // 개인정보 처리방침 및 이용약관
          const Text(
            '약관 및 정책',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPolicyButton(
            '개인정보 처리방침',
            'https://example.com/privacy-policy',
          ),
          const SizedBox(height: 8),
          _buildPolicyButton(
            '이용약관',
            'https://example.com/terms-of-service',
          ),
        ],
      ),
    );
  }

  // 개발팀 탭
  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '개발팀 소개',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '우리 정이 가계부는 개인 재정 관리의 어려움을 해결하기 위해 만들어진 앱입니다. '
                '저희 팀은 사용자의 재정 건강을 개선하고 재정 목표 달성을 돕기 위해 노력하고 있습니다.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 팀원 목록
          const Text(
            '팀원',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTeamMember(
            name: '홍길동',
            role: '프로젝트 리더 & UX 디자이너',
            description: '사용자 경험과 인터페이스 디자인 전문가. 복잡한 재정 앱을 직관적이고 사용하기 쉽게 만드는 데 집중.',
          ),
          _buildTeamMember(
            name: '김영희',
            role: '앱 개발자',
            description: 'Flutter 프레임워크 전문가. 안드로이드와 iOS 모두에서 최적의 성능을 내는 크로스플랫폼 앱 개발.',
          ),
          _buildTeamMember(
            name: '이철수',
            role: '백엔드 개발자',
            description: '데이터베이스 및 서버 인프라 전문가. 사용자 데이터의 안전한 저장과 처리를 담당.',
          ),
          _buildTeamMember(
            name: '박민지',
            role: '데이터 분석가',
            description: '사용자의 지출 패턴을 분석하고 유용한 인사이트를 제공하는 알고리즘 개발.',
          ),
          const SizedBox(height: 24),

          // 문의하기
          const Text(
            '문의하기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactItem(
                    icon: Icons.email,
                    title: '이메일',
                    content: 'support@example.com',
                    onTap: () => _launchUrl('mailto:support@example.com'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    icon: Icons.web,
                    title: '웹사이트',
                    content: 'www.example.com',
                    onTap: () => _launchUrl('https://www.example.com'),
                  ),
                  const Divider(height: 24),
                  _buildContactItem(
                    icon: Icons.question_answer,
                    title: '고객센터',
                    content: '평일 10:00 - 18:00',
                    onTap: null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 라이선스 탭
  Widget _buildLicenseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오픈소스 라이선스',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '이 앱은 다음과 같은 오픈소스 라이브러리를 사용하고 있습니다.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          _buildLicenseItem(
            title: 'Flutter',
            description: 'Google의 UI 툴킷으로, 하나의 코드베이스로 모바일, 웹, 데스크톱 앱을 제작할 수 있습니다.',
            url: 'https://flutter.dev',
            license: 'BSD 3-Clause License',
          ),
          _buildLicenseItem(
            title: 'GetX',
            description: '상태 관리, 의존성 주입, 라우트 관리를 위한 라이브러리입니다.',
            url: 'https://pub.dev/packages/get',
            license: 'MIT License',
          ),
          _buildLicenseItem(
            title: 'FL Chart',
            description: '차트 시각화를 위한 라이브러리로, 다양한 유형의 차트를 제공합니다.',
            url: 'https://pub.dev/packages/fl_chart',
            license: 'BSD 3-Clause License',
          ),
          _buildLicenseItem(
            title: 'Table Calendar',
            description: '캘린더 UI를 제공하는 라이브러리입니다.',
            url: 'https://pub.dev/packages/table_calendar',
            license: 'Apache License 2.0',
          ),
          _buildLicenseItem(
            title: 'Intl',
            description: '국제화 및 지역화 기능을 제공하는 라이브러리입니다.',
            url: 'https://pub.dev/packages/intl',
            license: 'BSD License',
          ),
          _buildLicenseItem(
            title: 'URL Launcher',
            description: '앱에서 외부 링크를 열기 위한 라이브러리입니다.',
            url: 'https://pub.dev/packages/url_launcher',
            license: 'BSD License',
          ),
          _buildLicenseItem(
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 기능 아이템 위젯
  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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
  Widget _buildPolicyButton(String title, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[700],
            ),
          ],
        ),
      ),
    );
  }

  // 팀원 카드 위젯
  Widget _buildTeamMember({
    required String name,
    required String role,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 이미지
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.substring(0, 1),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 연락처 아이템 위젯
  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String content,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const Spacer(),
              Icon(
                Icons.launch,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 라이선스 아이템 위젯
  Widget _buildLicenseItem({
    required String title,
    required String description,
    required String url,
    required String license,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      license,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '링크',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
              color: Colors.grey[700],
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