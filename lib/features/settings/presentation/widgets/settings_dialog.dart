// lib/features/settings/presentation/widgets/settings_dialog.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';

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

    // 애니메이션 시작
    _animationController.forward();
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
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '설정',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    color: AppColors.primary,
                                    onPressed: _closeDialog,
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
                              _buildSettingItem(
                                icon: Icons.person_outline,
                                title: '고정소득',
                                onTap: () {},
                              ),
                              const Divider(height: 32),
                              _buildSettingItem(
                                icon: Icons.help_outline,
                                title: '도움말',
                                onTap: () {},
                              ),
                              _buildSettingItem(
                                icon: Icons.info_outline,
                                title: '앱 정보',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),

                        // 하단 앱 버전
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '앱 버전: 1.0.0',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
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
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 4,
      ),
    );
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