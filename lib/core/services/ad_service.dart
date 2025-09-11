// lib/core/services/ad_service.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends GetxService {
  BannerAd? _bannerAd;
  final Rx<BannerAd?> bannerAd = Rx<BannerAd?>(null);
  final RxBool isBannerAdLoaded = false.obs;
  int _retryCount = 0;
  static const int _maxRetries = 5;

  // 테스트 광고 ID
  final String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // Keep test ID for debug mode
      : Platform.isAndroid
      ? 'ca-app-pub-6902355178006305/6345111569' // Your Android banner ad unit ID
      : 'ca-app-pub-6902355178006305/2615779808'; // Your iOS banner ad unit ID

  @override
  void onInit() {
    super.onInit();
    _loadBannerAd();
  }

  @override
  void onClose() {
    _bannerAd?.dispose();
    super.onClose();
  }

  void _loadBannerAd() async {
    // 기존 광고가 있다면 먼저 dispose 처리
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
      bannerAd.value = null;
      isBannerAdLoaded.value = false;
    }

    debugPrint('광고 로드 시작 - Ad Unit ID: $_adUnitId');
    debugPrint('디버그 모드: $kDebugMode');
    debugPrint('재시도 횟수: $_retryCount/$_maxRetries');
    debugPrint('플랫폼: ${Platform.isAndroid ? "Android" : "iOS"}');
    
    // 새 광고 생성
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // fullBanner에서 banner로 변경하여 안정성 향상
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          final bannerAd = ad as BannerAd;
          debugPrint('배너 광고 로드 성공 - Size: ${bannerAd.size}');
          _retryCount = 0; // 성공 시 재시도 카운트 리셋
          if (!isBannerAdLoaded.value) { // 중복 호출 방지
            this.bannerAd.value = bannerAd;
            isBannerAdLoaded.value = true;
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패 - 상세 정보:');
          debugPrint('- 에러 코드: ${error.code}');
          debugPrint('- 에러 메시지: ${error.message}');
          debugPrint('- 도메인: ${error.domain}');
          debugPrint('- 응답 정보: ${error.responseInfo}');
          
          // "cannot parse response" 오류 전용 디버깅
          if (error.message.toLowerCase().contains('parse') || 
              error.message.toLowerCase().contains('response')) {
            debugPrint('=== RESPONSE PARSING ERROR DETECTED ===');
            debugPrint('응답 파싱 오류 발생 - 가능한 원인:');
            debugPrint('1. 네트워크 연결 불안정');
            debugPrint('2. AdMob 서버 응답 형식 문제');
            debugPrint('3. SDK 버전 호환성 문제');
            debugPrint('4. 앱 Bundle ID와 AdMob 설정 불일치');
            debugPrint('====================================');
          }
          
          ad.dispose();
          _bannerAd = null;
          bannerAd.value = null;
          isBannerAdLoaded.value = false;

          // 재시도 횟수 증가
          _retryCount++;
          debugPrint('재시도 횟수: $_retryCount/$_maxRetries');
          
          // 최대 재시도 횟수 초과 시 재시도 중단
          if (_retryCount >= _maxRetries) {
            debugPrint('최대 재시도 횟수 초과 - 광고 로드 중단');
            return;
          }
          
          // 특정 에러 코드에 따른 처리
          if (error.code == 0) { // ERROR_CODE_INTERNAL_ERROR
            debugPrint('내부 에러 발생 - 5분 후 재시도');
            Future.delayed(const Duration(minutes: 5), () {
              if (Get.context != null && _retryCount < _maxRetries) {
                _loadBannerAd();
              }
            });
          } else if (error.code == 1) { // ERROR_CODE_INVALID_REQUEST
            debugPrint('잘못된 요청 - Ad Unit ID 또는 앱 설정 확인 필요');
            debugPrint('재시도를 중단합니다.');
            _retryCount = _maxRetries; // 재시도 중단
          } else if (error.code == 2) { // ERROR_CODE_NETWORK_ERROR
            debugPrint('네트워크 에러 - 30초 후 재시도 (네트워크 연결 확인 필요)');
            Future.delayed(const Duration(seconds: 30), () {
              if (Get.context != null && _retryCount < _maxRetries) {
                debugPrint('네트워크 오류 재시도 시작');
                _loadBannerAd();
              }
            });
          } else if (error.code == 3) { // ERROR_CODE_NO_FILL
            debugPrint('광고 인벤토리 없음 - 5분 후 재시도');
            Future.delayed(const Duration(minutes: 5), () {
              if (Get.context != null && _retryCount < _maxRetries) {
                _loadBannerAd();
              }
            });
          } else {
            // 기타 에러의 경우 1분 후 재시도
            debugPrint('기타 에러 - 1분 후 재시도');
            Future.delayed(const Duration(minutes: 1), () {
              if (Get.context != null && _retryCount < _maxRetries) {
                _loadBannerAd();
              }
            });
          }
        },
        onAdClicked: (ad) {
          debugPrint('배너 광고 클릭됨');
        },
        onAdImpression: (ad) {
          debugPrint('배너 광고 노출됨');
        },
      ),
    );

    try {
      // 작은 지연 후 로드 시도 (안정성 향상)
      await Future.delayed(const Duration(milliseconds: 500));
      _bannerAd?.load();
      debugPrint('광고 로드 요청 완료');
    } catch (e) {
      debugPrint('광고 로드 중 예외 발생: $e');
      debugPrint('오류 유형: ${e.runtimeType}');
      
      // 오류 발생시 상태 리셋
      _bannerAd = null;
      bannerAd.value = null;
      isBannerAdLoaded.value = false;
      
      // 특정 예외에 대한 처리
      if (e.toString().toLowerCase().contains('parse')) {
        debugPrint('파싱 오류 감지 - SDK 버전 또는 네트워크 오류 가능성');
      }
    }
  }

  // 배너 광고 위젯 - 꽉 차게 표시하되 안정적으로 관리
  Widget getBannerAdWidget() {
    return Obx(() {
      if (isBannerAdLoaded.value && bannerAd.value != null) {
        try {
          return Container(
            key: ValueKey<String>('ad_${DateTime.now().millisecondsSinceEpoch}'), // 고유 키 부여
            width: double.infinity, // 화면 너비 전체
            height: bannerAd.value!.size.height.toDouble(),
            constraints: const BoxConstraints(maxHeight: 60), // 높이 제한 추가
            child: Center(
              child: AdWidget(ad: bannerAd.value!),
            ),
          );
        } catch (e) {
          debugPrint('광고 위젯 렌더링 오류: $e');
          // 오류 발생시 빈 공간 표시
          return const SizedBox(height: 50, width: double.infinity);
        }
      }
      // 광고가 로드되지 않았을 때 표시할 빈 공간
      return const SizedBox(height: 50, width: double.infinity);
    });
  }

  // Ad Unit ID 유효성 검사
  void validateAdConfiguration() {
    debugPrint('=== Ad Configuration Validation ===');
    debugPrint('Current Ad Unit ID: $_adUnitId');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
    
    // 테스트 ID 확인
    const testId = 'ca-app-pub-3940256099942544/6300978111';
    if (_adUnitId == testId) {
      debugPrint('✅ 테스트 광고 ID 사용 중 - 정상');
    } else {
      debugPrint('⚠️ 실제 광고 ID 사용 중');
      debugPrint('Bundle ID와 AdMob 설정이 일치하는지 확인해주세요');
    }
    debugPrint('====================================');
  }

  // 광고 로드 재시도
  void retryLoadAd() {
    debugPrint('광고 로드 수동 재시도 실행 - 재시도 카운트 리셋');
    _retryCount = 0; // 수동 재시도 시 카운트 리셋
    _loadBannerAd();
  }

  Future<AdService> init() async {
    validateAdConfiguration();
    return this;
  }
}