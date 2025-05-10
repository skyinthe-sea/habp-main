import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxService {
  // 다크 모드 상태를 관리하는 Rx 변수
  final RxBool _isDarkMode = false.obs;
  
  // 시스템 설정 따라가기 여부
  final RxBool _isSystemMode = false.obs;
  
  // 다크 모드 여부 getter
  bool get isDarkMode => _isDarkMode.value;

  // 시스템 모드 여부 getter
  bool get isSystemMode => _isSystemMode.value;

  // 다크 모드 설정 메서드 (시스템 설정이 변경될 때 사용)
  void setDarkMode(bool isDark) {
    _isDarkMode.value = isDark;
    // 테마 변경 알림
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
    debugPrint('다크 모드 설정 변경: $isDark');
  }
  
  // SharedPreferences 키
  static const String _darkModeKey = 'is_dark_mode';
  static const String _systemModeKey = 'is_system_mode';
  
  Future<ThemeService> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 저장된 설정 불러오기
      _isSystemMode.value = prefs.getBool(_systemModeKey) ?? true;
      
      if (_isSystemMode.value) {
        // 시스템 설정 따라가기 모드일 경우
        final brightness = Get.mediaQuery.platformBrightness;
        _isDarkMode.value = brightness == Brightness.dark;
      } else {
        // 사용자 지정 모드일 경우
        _isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;
      }
      
      // 테마 설정 디버그 로그
      debugPrint('테마 서비스 초기화: 다크 모드=${_isDarkMode.value}, 시스템 모드=${_isSystemMode.value}');
      
      return this;
    } catch (e) {
      debugPrint('테마 서비스 초기화 중 오류: $e');
      return this;
    }
  }
  
  // 다크 모드 전환 메서드
  Future<void> toggleDarkMode() async {
    try {
      // 시스템 모드를 먼저 해제
      await _setSystemMode(false);
      
      // 다크 모드 전환
      _isDarkMode.value = !_isDarkMode.value;
      
      // 변경 내용 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode.value);
      
      // 테마 업데이트
      Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      
      debugPrint('다크 모드 전환: ${_isDarkMode.value}');
    } catch (e) {
      debugPrint('다크 모드 전환 중 오류: $e');
    }
  }
  
  // 시스템 설정 사용 모드 설정 메서드
  Future<void> _setSystemMode(bool value) async {
    try {
      _isSystemMode.value = value;
      
      // 변경 내용 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_systemModeKey, value);
      
      debugPrint('시스템 모드 설정: $value');
    } catch (e) {
      debugPrint('시스템 모드 설정 중 오류: $e');
    }
  }
  
  // 시스템 설정으로 전환 메서드
  Future<void> useSystemTheme() async {
    try {
      // 시스템 모드 활성화
      await _setSystemMode(true);
      
      // 현재 시스템 설정 확인
      final brightness = Get.mediaQuery.platformBrightness;
      _isDarkMode.value = brightness == Brightness.dark;
      
      // 테마 업데이트
      Get.changeThemeMode(ThemeMode.system);
      
      debugPrint('시스템 테마 사용: 다크 모드=${_isDarkMode.value}');
    } catch (e) {
      debugPrint('시스템 테마 설정 중 오류: $e');
    }
  }
  
  // 테마 모드 변경 리스너 설정
  void listenToPlatformBrightnessChanges(BuildContext context) {
    if (_isSystemMode.value) {
      // 현재 시스템 밝기 모드 확인
      final currentBrightness = MediaQuery.of(context).platformBrightness;
      _isDarkMode.value = currentBrightness == Brightness.dark;

      // 시스템 설정이 변경될 경우 앱을 다시 시작할 때 반영됨
      debugPrint('현재 시스템 밝기 상태: ${currentBrightness.toString()}, 다크 모드=${_isDarkMode.value}');

      // 참고: Flutter의 MediaQuery에서 platformBrightness 변경을 실시간으로
      // 감지하려면 WidgetsBindingObserver를 사용해야 합니다.
      // 이 기능은 현재 페이지 클래스에서 구현하는 것이 더 적합합니다.
    }
  }
}