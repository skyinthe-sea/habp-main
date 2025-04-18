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
    // 광고 크기를 FULL_BANNER 또는 SMART_BANNER로 변경
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.fullBanner, // 이 부분을 변경 - 더 넓은 광고 크기
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('배너 광고 로드 성공');
          bannerAd.value = ad as BannerAd;
          isBannerAdLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패: ${error.message}');
          ad.dispose();
          isBannerAdLoaded.value = false;

          // 실패 시 재시도 로직
          Future.delayed(const Duration(minutes: 1), () {
            _loadBannerAd();
          });
        },
      ),
    );

    _bannerAd?.load();
  }

  // 배너 광고 위젯 - 꽉 차게 표시
  Widget getBannerAdWidget() {
    return Obx(() {
      if (isBannerAdLoaded.value && bannerAd.value != null) {
        return SizedBox(
          width: double.infinity, // 화면 너비 전체
          height: bannerAd.value!.size.height.toDouble(),
          child: Center(
            child: AdWidget(ad: bannerAd.value!),
          ),
        );
      }
      // 광고가 로드되지 않았을 때 표시할 빈 공간
      return SizedBox(height: 50, width: double.infinity);
    });
  }

  Future<AdService> init() async {
    return this;
  }
}