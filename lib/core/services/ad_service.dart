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

  void _loadBannerAd() {
    // 기존 광고가 있다면 먼저 dispose 처리
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
      bannerAd.value = null;
      isBannerAdLoaded.value = false;
    }

    // 새 광고 생성
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.fullBanner, // 이 부분을 변경 - 더 넓은 광고 크기
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('배너 광고 로드 성공');
          if (!isBannerAdLoaded.value) { // 중복 호출 방지
            bannerAd.value = ad as BannerAd;
            isBannerAdLoaded.value = true;
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패: ${error.message}');
          ad.dispose();
          _bannerAd = null;
          bannerAd.value = null;
          isBannerAdLoaded.value = false;

          // 실패 시 재시도 로직, 약간의 지연 추가
          Future.delayed(const Duration(minutes: 1), () {
            // 앱이 아직 실행 중인지 확인
            if (Get.context != null) {
              _loadBannerAd();
            }
          });
        },
      ),
    );

    try {
      _bannerAd?.load();
    } catch (e) {
      debugPrint('광고 로드 중 예외 발생: $e');
      // 오류 발생시 상태 리셋
      _bannerAd = null;
      bannerAd.value = null;
      isBannerAdLoaded.value = false;
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

  Future<AdService> init() async {
    return this;
  }
}