// lib/core/utils/dismissible_error_handler.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DismissibleErrorHandler {
  // 싱글톤 인스턴스
  static final DismissibleErrorHandler _instance = DismissibleErrorHandler._internal();
  factory DismissibleErrorHandler() => _instance;
  DismissibleErrorHandler._internal();

  // 에러 핸들러 초기화 - Dismissible 관련 에러만 무시
  void initialize() {
    // 원래 에러 위젯 빌더 저장
    final originalErrorBuilder = ErrorWidget.builder;

    // ErrorWidget 재정의
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Dismissible 관련 에러만 빈 위젯으로 대체
      if (details.exception.toString().contains('dismissed Dismissible') ||
          details.toString().contains('A dismissed Dismissible') ||
          details.summary.toString().contains('Dismissible')) {
        return const SizedBox.shrink();  // 빈 위젯 반환
      }

      // 다른 에러는 원래 처리 방식으로
      return originalErrorBuilder(details);
    };

    // 콘솔 에러 처리 - 원래 에러 핸들러 저장
    final originalOnError = FlutterError.onError;

    // FlutterError.onError 재정의
    FlutterError.onError = (FlutterErrorDetails details) {
      // Dismissible 관련 에러는 무시
      if (details.exception.toString().contains('dismissed Dismissible') ||
          details.toString().contains('A dismissed Dismissible') ||
          details.summary.toString().contains('Dismissible')) {
        // 에러 완전 무시
        return;
      }

      // 다른 에러는 원래 처리 방식으로
      if (originalOnError != null) {
        originalOnError(details);
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
    };
  }
}