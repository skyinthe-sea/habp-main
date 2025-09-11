// lib/features/settings/presentation/widgets/help_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/controllers/theme_controller.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({Key? key}) : super(key: key);

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
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '이용 가이드',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 컨텐츠
            Expanded(
              child: DefaultTabController(
                length: 4,
                child: Column(
                  children: [
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
                        tabs: const [
                          Tab(text: '개요'),
                          Tab(text: '자산'),
                          Tab(text: '예산'),
                          Tab(text: 'FAQ'),
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
                        children: [
                          _buildOverviewTab(themeController),
                          _buildAssetsTab(themeController),
                          _buildBudgetTab(themeController),
                          _buildFAQTab(themeController),
                        ],
                      ),
                    ),
                  ],
                ),
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

  // 개요 탭
  Widget _buildOverviewTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.dashboard,
            title: '대시보드',
            description: '자산, 지출, 소득에 대한 전반적인 상황을 한눈에 확인할 수 있습니다. 월간 지출 추이와 카테고리별 분석을 제공합니다.',
          ),
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.calendar_today,
            title: '캘린더',
            description: '날짜별 수입과 지출을 확인할 수 있습니다. 일별, 월별로 거래를 조회하고 필터링할 수 있습니다.',
          ),
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.add_circle,
            title: '빠른 추가',
            description: '화면 중앙 하단의 + 버튼을 눌러 빠르게 거래를 추가할 수 있습니다. 소득, 지출, 재테크 중 거래 유형을 선택하세요.',
          ),
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.account_balance_wallet,
            title: '자산 관리',
            description: '부동산, 예금, 주식 등 다양한 자산을 등록하고 관리할 수 있습니다. 자산별 현황과 증감을 확인하세요.',
          ),
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.pie_chart,
            title: '예산 관리',
            description: '카테고리별 예산을 설정하고 지출 현황을 모니터링할 수 있습니다. 초과 지출 시 알림을 받을 수 있습니다.',
          ),
          _buildFeatureCard(
            themeController: themeController,
            icon: Icons.settings,
            title: '설정',
            description: '고정 소득, 지출, 재테크를 설정하여 매월 반복되는 거래를 자동으로 관리할 수 있습니다.',
          ),
        ],
      ),
    );
  }

  // 자산 탭
  Widget _buildAssetsTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '자산 관리 사용법',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '01',
            title: '자산 추가하기',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 자산 화면에서 우측 하단의 설정 버튼을 탭합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 자산 유형을 선택합니다. (부동산, 예금, 주식 등)', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 자산 이름과 현재 가치를 입력합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('4. 필요에 따라 구매 가치, 구매 날짜, 이자율 등의 추가 정보를 입력합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('5. 저장 버튼을 눌러 자산을 추가합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '02',
            title: '자산 수정 및 삭제',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 자산 목록에서 수정/삭제할 자산을 탭합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 상세 화면에서 수정하기 버튼을 눌러 정보를 업데이트하거나, 삭제하기 버튼을 눌러 자산을 삭제합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 자산 가치가 변경되면 현재 가치를 업데이트하여 수익률을 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '03',
            title: '자산 분석 보기',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 자산 화면 상단의 요약 카드에서 총 자산 가치와 자산별 비율을 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 각 자산을 탭하면 해당 자산의 상세 정보와 증감률을 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 자산 유형별 필터를 사용하여 원하는 자산만 볼 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 예산 탭
  Widget _buildBudgetTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '예산 관리 사용법',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeController.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '01',
            title: '예산 설정하기',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 예산 화면에서 우측 하단의 설정 버튼을 탭합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 카테고리를 선택하고 예산 금액을 입력합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 새 카테고리가 필요하면 "카테고리 추가" 버튼을 눌러 만들 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('4. 저장 버튼을 눌러 예산을 설정합니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '02',
            title: '월간 예산 관리',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 상단의 월 선택기를 사용하여 원하는 월의 예산을 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 전체 예산 진행 상황은 상단 카드에서 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 카테고리별 예산 진행 상황은 목록에서 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('4. 예산을 초과한 카테고리는 빨간색으로 표시됩니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '03',
            title: '카테고리별 분석',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 카테고리를 탭하면 해당 카테고리의 세부 분석을 볼 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 요일별, 일별 지출 패턴을 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 지난달 대비 변화를 확인하고 지출 패턴을 분석할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('4. 지출 내역 탭에서 해당 카테고리의 모든 거래를 확인할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
          _buildStepCard(
            themeController: themeController,
            stepNumber: '04',
            title: '예산 복사하기',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. 새 달이 시작되면 자동으로 이전 달의 예산을 복사할지 물어봅니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('2. 또는 예산 설정 화면에서 이전 달 예산을 복사할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
                Text('3. 필요에 따라 각 카테고리의 예산을 조정할 수 있습니다.', style: TextStyle(color: themeController.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FAQ 탭
  Widget _buildFAQTab(ThemeController themeController) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFAQItem(
            themeController: themeController,
            question: '고정 거래는 무엇인가요?',
            answer: '매월 반복되는 소득, 지출, 재테크 항목을 설정하는 기능입니다. 예를 들어 급여, 월세, 보험료, 적금 등을 설정해두면 매월 자동으로 기록됩니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '자산을 추가하면 어떤 장점이 있나요?',
            answer: '모든 자산을 한 곳에서 관리할 수 있어 순자산을 정확히 파악할 수 있습니다. 부동산, 주식, 예금 등 다양한 자산의 가치 변화와 수익률을 확인할 수 있습니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '예산은 어떻게 설정하나요?',
            answer: '예산 화면에서 카테고리별로 월간 예산을 설정할 수 있습니다. 카테고리별 예산을 설정하면 지출 현황을 더 효과적으로 관리할 수 있습니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '거래 내역을 수정하거나 삭제할 수 있나요?',
            answer: '네, 캘린더에서 해당 거래를 선택하여 수정하거나 삭제할 수 있습니다. 또한 카테고리 상세 화면에서도 거래 내역을 관리할 수 있습니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '데이터 백업 방법은 무엇인가요?',
            answer: '현재 개발 중인 기능입니다. 추후 업데이트에서 클라우드 백업 및 복원 기능이 추가될 예정입니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '여러 계좌나 신용카드를 연결할 수 있나요?',
            answer: '현재는 수동 입력 방식만 지원합니다. 추후 업데이트에서 은행 및 카드사 연동 기능이 추가될 예정입니다.',
          ),
          _buildFAQItem(
            themeController: themeController,
            question: '앱을 삭제하면 데이터는 어떻게 되나요?',
            answer: '앱 데이터는 기기에 저장되므로 앱을 삭제하면 모든 데이터가 손실됩니다. 중요한 데이터는 앱 삭제 전에 반드시 백업하시기 바랍니다.',
          ),
        ],
      ),
    );
  }

  // 기능 카드 위젯
  Widget _buildFeatureCard({
    required ThemeController themeController,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: themeController.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: themeController.isDarkMode 
              ? Colors.grey.shade600
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: themeController.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: themeController.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: themeController.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 단계별 카드 위젯
  Widget _buildStepCard({
    required ThemeController themeController,
    required String stepNumber,
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: themeController.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeController.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  // FAQ 아이템 위젯
  Widget _buildFAQItem({
    required ThemeController themeController,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: themeController.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeController.isDarkMode 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Icon(
              Icons.question_answer,
              color: themeController.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: themeController.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: themeController.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// 다이얼로그 표시 확장 함수
extension HelpDialogExtension on GetInterface {
  Future<void> showHelpDialog() {
    return Get.dialog(
      const HelpDialog(),
      barrierDismissible: true,
    );
  }
}