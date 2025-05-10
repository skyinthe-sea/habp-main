// lib/core/utils/error_config.dart

import 'package:flutter/foundation.dart';

/// 에러 처리 관련 설정을 관리하는 클래스
class ErrorConfig {
  // 싱글톤 인스턴스
  static final ErrorConfig _instance = ErrorConfig._internal();
  factory ErrorConfig() => _instance;
  ErrorConfig._internal();
  
  // 플래그: Dismissible 에러 무시 여부
  bool ignoreDismissibleErrors = true;
  
  // 플래그: 모든 에러 무시 여부
  bool ignoreAllErrors = false;
  
  // 특정 에러 유형 무시 목록
  final List<String> ignoredErrorTypes = [
    'dismissed Dismissible',
    'A dismissed Dismissible widget is still part of the tree',
    'recreating_view',
    'trying to create an already created view'
  ];
  
  // 특정 에러인지 확인하는 메서드
  bool shouldIgnoreError(dynamic error) {
    if (ignoreAllErrors) return true;
    
    final errorString = error.toString();
    return ignoredErrorTypes.any((type) => errorString.contains(type));
  }
  
  // 개발 환경에 따라 설정 초기화
  void initializeForEnvironment() {
    if (kDebugMode) {
      // 디버그 모드에서는 Dismissible 에러만 무시
      ignoreDismissibleErrors = true;
      ignoreAllErrors = false;
    } else {
      // 릴리즈 모드에서는 모든 잠재적 UI 에러 무시
      ignoreDismissibleErrors = true;
      ignoreAllErrors = true;
    }
    
    debugPrint('에러 설정 초기화 - Dismissible 에러 무시: $ignoreDismissibleErrors, 모든 에러 무시: $ignoreAllErrors');
  }
}