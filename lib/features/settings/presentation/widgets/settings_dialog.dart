// lib/features/settings/presentation/widgets/settings_dialog.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../../domain/repositories/fixed_transaction_repository.dart';
import '../../domain/usecases/get_fixed_categories_by_type.dart';
import '../../domain/usecases/add_fixed_transaction_setting.dart';
import '../../domain/usecases/create_fixed_transaction.dart';
import '../../domain/usecases/delete_fixed_transaction.dart';
import '../controllers/settings_controller.dart';
import 'fixed_income_dialog.dart';
import 'fixed_expense_dialog.dart';
import 'fixed_finance_dialog.dart';
import 'help_dialog.dart';
import 'app_info_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late SettingsController _settingsController;

  String _appVersion = "1.0.0"; // 기본값
  bool _isLoadingVersion = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // SettingsController 초기화
    _initSettingsController();

    // 앱 버전 가져오기
    _getAppVersion();

    // 애니메이션 시작
    _animationController.forward();
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _isLoadingVersion = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVersion = false;
      });
    }
  }

  void _initSettingsController() {
    // 이미 컨트롤러가 등록되어 있는지 확인
    if (!Get.isRegistered<SettingsController>()) {
      // 의존성 주입
      final dbHelper = DBHelper();
      final dataSource = FixedTransactionLocalDataSourceImpl(dbHelper: dbHelper);
      final repository = FixedTransactionRepositoryImpl(localDataSource: dataSource);

      final getFixedCategoriesByType = GetFixedCategoriesByType(repository);
      final addFixedTransactionSetting = AddFixedTransactionSetting(repository);
      final createFixedTransaction = CreateFixedTransaction(repository);
      final deleteFixedTransaction = DeleteFixedTransaction(repository);

      // 컨트롤러 생성 및 등록
      _settingsController = SettingsController(
        getFixedCategoriesByType: getFixedCategoriesByType,
        addFixedTransactionSetting: addFixedTransactionSetting,
        createFixedTransaction: createFixedTransaction,
        deleteFixedTransaction: deleteFixedTransaction,
        repository: repository,
      );

      Get.put(_settingsController);
    } else {
      // 이미 등록된 컨트롤러 가져오기
      _settingsController = Get.find<SettingsController>();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeDialog() async {
    // 닫기 애니메이션 실행
    await _animationController.reverse();
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _closeDialog();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 배경 (탭하면 닫기)
            GestureDetector(
              onTap: _closeDialog,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),

            // 슬라이드되는 설정 패널
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: Get.width * 0.85, // 화면의 85% 너비
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(-5, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 블러 효과가 있는 설정 헤더
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary.withOpacity(0.8),
                                    AppColors.primary.withOpacity(0.6),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '설정',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        color: Colors.white,
                                        onPressed: _closeDialog,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '수기가계부',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 설정 목록
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            children: [
                              // 소득/지출/재테크 관리 섹션
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '고정 거래 관리',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSettingItem(
                                icon: Icons.attach_money,
                                title: '고정 소득',
                                subtitle: '매월 반복되는 소득 항목을 관리합니다',
                                color: Colors.green.shade700,
                                onTap: () => Get.showFixedIncomeDialog(),
                              ),
                              _buildSettingItem(
                                icon: Icons.money_off,
                                title: '고정 지출',
                                subtitle: '매월 반복되는 지출 항목을 관리합니다',
                                color: AppColors.cate4,
                                onTap: () => Get.showFixedExpenseDialog(),
                              ),
                              _buildSettingItem(
                                icon: Icons.account_balance,
                                title: '고정 재테크',
                                subtitle: '매월 반복되는 재테크 항목을 관리합니다',
                                color: Colors.blue.shade700,
                                onTap: () => Get.showFixedFinanceDialog(),
                              ),

                              // 데이터 섹션
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.storage,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '데이터',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSettingItem(
                                icon: Icons.backup,
                                title: '백업 및 복원',
                                subtitle: '데이터를 백업하고 복원할 수 있습니다',
                                onTap: () {
                                  Get.snackbar(
                                    '준비중',
                                    '백업 및 복원 기능은 곧 제공될 예정입니다',
                                    backgroundColor: Colors.black87,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                              ),
                              _buildSettingItem(
                                icon: Icons.delete_outline,
                                title: '데이터 초기화',
                                subtitle: '모든 데이터를 초기화합니다',
                                textColor: Colors.red,
                                onTap: () {
                                  _showDataResetDialog();
                                },
                              ),

                              // 기타 설정 섹션
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.more_horiz,
                                      size: 16,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '기타',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildSettingItem(
                                icon: Icons.help_outline,
                                title: '도움말',
                                subtitle: '앱 사용 가이드와 자주 묻는 질문',
                                onTap: () {
                                  Get.showHelpDialog();
                                },
                              ),
                              _buildSettingItem(
                                icon: Icons.info_outline,
                                title: '앱 정보',
                                subtitle: '버전, 개발팀, 라이센스 정보',
                                onTap: () {
                                  Get.showAppInfoDialog();
                                },
                              ),
                              _buildSettingItem(
                                icon: Icons.star_outline,
                                title: '앱 평가하기',
                                subtitle: '스토어에서 앱을 평가해주세요',
                                onTap: () {
                                  Get.snackbar(
                                    '준비중',
                                    '앱 평가 기능은 곧 제공될 예정입니다',
                                    backgroundColor: Colors.black87,
                                    colorText: Colors.white,
                                    snackPosition: SnackPosition.BOTTOM,
                                    margin: const EdgeInsets.all(16),
                                    duration: const Duration(seconds: 2),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // 하단 앱 버전
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLoadingVersion
                                    ? '버전 정보 로딩 중...'
                                    : '버전 $_appVersion',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? color,
  }) {
    final itemColor = color ?? (textColor ?? AppColors.primary);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: itemColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: itemColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 4,
      ),
    );
  }

  void _showDataResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '데이터 초기화',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          '모든 데이터가 삭제되며 복구할 수 없습니다. 정말 초기화하시겠습니까?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showFinalConfirmationDialog();
            },
            child: const Text('초기화'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showFinalConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '최종 확인',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '⚠️ 경고: 이 작업은 되돌릴 수 없습니다',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '• 모든 거래 내역이 삭제됩니다\n'
                  '• 모든 카테고리 설정이 초기화됩니다\n'
                  '• 모든 자산 정보가 삭제됩니다\n'
                  '• 모든 예산 설정이 삭제됩니다\n'
                  '• 모든 고정 거래 설정이 삭제됩니다',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 12),
            Text(
              '다시 한번 확인합니다. 정말로 모든 데이터를 초기화하시겠습니까?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllData();
            },
            child: const Text('최종 확인'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Future<void> _resetAllData() async {
    // 로딩 다이얼로그 표시
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      // DBHelper 인스턴스 가져오기
      final dbHelper = DBHelper();

      // 데이터베이스 초기화
      await dbHelper.resetDatabase();

      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 설정 다이얼로그 닫기
      _closeDialog();

      // 이벤트 버스를 통해 앱 전체에 데이터 변경 알림
      final eventBusService = Get.find<EventBusService>();
      eventBusService.emitTransactionChanged();

      // 성공 메시지 표시
      Get.snackbar(
        '초기화 완료',
        '모든 데이터가 성공적으로 초기화되었습니다.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

      // 메인 페이지로 이동 (초기화 후 앱 상태 리셋)
      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 오류 메시지 표시
      Get.snackbar(
        '오류 발생',
        '데이터 초기화 중 오류가 발생했습니다: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

// 다이얼로그 표시 확장 함수
extension SettingsDialogExtension on GetInterface {
  Future<void> showSettingsDialog() {
    return Get.dialog(
      const SettingsDialog(),
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useSafeArea: false,
      routeSettings: const RouteSettings(name: '/settings'),
    );
  }
}