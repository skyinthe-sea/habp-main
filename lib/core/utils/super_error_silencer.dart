// lib/core/utils/super_error_silencer.dart
// 가장 강력한 에러 무시 처리기 - 모든 에러를 완전히 숨기는 방법

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_config.dart';

class SuperErrorSilencer {
  // 싱글톤 인스턴스
  static final SuperErrorSilencer _instance = SuperErrorSilencer._internal();
  factory SuperErrorSilencer() => _instance;
  SuperErrorSilencer._internal();

  // 에러 설정
  final ErrorConfig _config = ErrorConfig();

  // 에러 처리 초기화 메서드
  void silenceAllErrors() {
    // 환경에 맞게 설정 초기화
    _config.initializeForEnvironment();

    // 1. Flutter 에러 처리 재정의
    FlutterError.onError = (FlutterErrorDetails details) {
      // 설정에 따라 에러 무시 여부 결정
      if (_config.ignoreAllErrors ||
          (_config.ignoreDismissibleErrors && _isDismissibleError(details))) {
        // 에러 무시
        if (kDebugMode) {
          print('에러 무시됨: ${details.exception}');
        }
      } else {
        // 무시하지 않는 에러는 정상 처리
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 2. 에러 위젯 재정의
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // 설정에 따라 에러 무시 여부 결정
      if (_config.ignoreAllErrors ||
          (_config.ignoreDismissibleErrors && _isDismissibleError(details))) {
        // 빈 위젯 반환
        return const SizedBox.shrink();
      }

      // 무시하지 않는 에러는 기본 에러 위젯 표시
      return ErrorWidget(details.exception);
    };

    // 3. 비동기 에러에 대한 기본 처리 재정의
    PlatformDispatcher.instance.onError = (error, stack) {
      // 설정에 따라 에러 무시 여부 결정
      if (_config.ignoreAllErrors ||
          (_config.ignoreDismissibleErrors && _config.shouldIgnoreError(error))) {
        return true;  // 에러 처리 완료로 표시
      }

      // 무시하지 않는 에러는 false 반환하여 기본 처리로 넘김
      return false;
    };
  }

  // Dismissible 관련 에러인지 확인하는 유틸리티 메서드
  bool _isDismissibleError(FlutterErrorDetails details) {
    final error = details.exception.toString();
    final summary = details.summary.toString();

    return error.contains('dismissed Dismissible') ||
           error.contains('A dismissed Dismissible') ||
           summary.contains('Dismissible') ||
           error.contains('recreating_view') ||
           error.contains('trying to create an already created view');
  }
}