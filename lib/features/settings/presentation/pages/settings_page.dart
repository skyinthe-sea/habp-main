// lib/features/settings/presentation/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/version_check_service.dart';
import '../../../asset/presentation/pages/asset_page.dart';
import '../controllers/settings_controller.dart';
import '../widgets/fixed_income_dialog.dart';
import '../widgets/fixed_expense_dialog.dart';
import '../widgets/fixed_finance_dialog.dart';
import '../widgets/help_dialog.dart';
import '../widgets/app_info_dialog.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/fixed_transaction_local_data_source.dart';
import '../../domain/repositories/fixed_transaction_repository.dart';
import '../../domain/usecases/get_fixed_categories_by_type.dart';
import '../../domain/usecases/add_fixed_transaction_setting.dart';
import '../../domain/usecases/create_fixed_transaction.dart';
import '../../domain/usecases/delete_fixed_transaction.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutomaticKeepAliveClientMixin {
  late SettingsController _settingsController;
  String _appVersion = "1.0.0";
  bool _isLoadingVersion = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSettingsController();
    _getAppVersion();
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
    if (!Get.isRegistered<SettingsController>()) {
      final dbHelper = DBHelper();
      final dataSource = FixedTransactionLocalDataSourceImpl(dbHelper: dbHelper);
      final repository = FixedTransactionRepositoryImpl(localDataSource: dataSource);

      final getFixedCategoriesByType = GetFixedCategoriesByType(repository);
      final addFixedTransactionSetting = AddFixedTransactionSetting(repository);
      final createFixedTransaction = CreateFixedTransaction(repository);
      final deleteFixedTransaction = DeleteFixedTransaction(repository);

      _settingsController = SettingsController(
        getFixedCategoriesByType: getFixedCategoriesByType,
        addFixedTransactionSetting: addFixedTransactionSetting,
        createFixedTransaction: createFixedTransaction,
        deleteFixedTransaction: deleteFixedTransaction,
        repository: repository,
      );

      Get.put(_settingsController);
    } else {
      _settingsController = Get.find<SettingsController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 자산 관리 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 16,
                    color: Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '자산 관리',
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
              icon: Icons.account_balance_outlined,
              title: '자산',
              subtitle: '보유 자산을 관리하고 현황을 확인합니다',
              color: Colors.blue.shade700,
              onTap: () {
                Get.to(() => const AssetPage());
              },
            ),

            // 고정 거래 관리 섹션
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
              onTap: () async {
                try {
                  final versionService = Get.find<VersionCheckService>();
                  final success = await versionService.openStore();
                  if (!success) {
                    Get.snackbar(
                      '오류',
                      '스토어를 열 수 없습니다. 나중에 다시 시도해주세요.',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  }
                } catch (e) {
                  Get.snackbar(
                    '오류',
                    '스토어 연결 중 오류가 발생했습니다.',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  );
                }
              },
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
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
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}