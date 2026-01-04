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

  // 광고 ID 설정 - 릴리즈 모드에서는 실제 광고 ID 사용
  final String _adUnitId = kReleaseMode
      ? (Platform.isAndroid
          ? 'ca-app-pub-6902355178006305/6345111569' // Android 실제 ID
          : 'ca-app-pub-6902355178006305/2615779808') // iOS 실제 ID
      : 'ca-app-pub-3940256099942544/6300978111'; // Google 테스트 ID (디버그/프로파일)

  @override
  void onInit() async {
    super.onInit();
    // Mobile Ads SDK 초기화
    await MobileAds.instance.initialize();
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

    // 디버깅 정보 출력
    debugPrint('=== 광고 로드 시작 ===');
    debugPrint('Bundle ID: ljs.salamander.habp');
    debugPrint('Ad Unit ID: $_adUnitId');
    debugPrint('플랫폼: ${Platform.isAndroid ? "Android" : "iOS"}');
    debugPrint('릴리즈 모드: $kReleaseMode');
    debugPrint('디버그 모드: $kDebugMode');
    debugPrint('프로파일 모드: $kProfileMode');
    debugPrint('=====================');

    // 새 광고 생성
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.fullBanner, // 이 부분을 변경 - 더 넓은 광고 크기
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('=== 배너 광고 로드 성공 ===');
          debugPrint('광고 크기: ${(ad as BannerAd).size}');
          debugPrint('광고 ID: $_adUnitId');
          if (!isBannerAdLoaded.value) { // 중복 호출 방지
            bannerAd.value = ad;
            isBannerAdLoaded.value = true;
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('=== 배너 광고 로드 실패 ===');
          debugPrint('에러 코드: ${error.code}');
          debugPrint('에러 메시지: ${error.message}');
          debugPrint('도메인: ${error.domain}');
          debugPrint('응답 정보: ${error.responseInfo}');
          debugPrint('사용된 광고 ID: $_adUnitId');
          debugPrint('========================');

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

  // 배너 광고 위젯 - StatefulWidget으로 감싸서 광고 객체 재사용 방지
  Widget getBannerAdWidget() {
    return _BannerAdContainer(adService: this);
  }

  Future<AdService> init() async {
    return this;
  }
}

/// 배너 광고를 위한 StatefulWidget 컨테이너
/// AdWidget이 리빌드될 때 동일한 광고 객체를 재사용하는 문제를 방지
class _BannerAdContainer extends StatefulWidget {
  final AdService adService;

  const _BannerAdContainer({required this.adService});

  @override
  State<_BannerAdContainer> createState() => _BannerAdContainerState();
}

class _BannerAdContainerState extends State<_BannerAdContainer> {
  Widget? _cachedAdWidget;
  BannerAd? _lastAd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoaded = widget.adService.isBannerAdLoaded.value;
      final currentAd = widget.adService.bannerAd.value;

      if (isLoaded && currentAd != null) {
        // 광고 객체가 변경되었을 때만 새 AdWidget 생성
        if (_lastAd != currentAd) {
          _lastAd = currentAd;
          _cachedAdWidget = AdWidget(ad: currentAd);
        }

        return Container(
          width: double.infinity,
          height: currentAd.size.height.toDouble(),
          constraints: const BoxConstraints(maxHeight: 60),
          child: Center(
            child: _cachedAdWidget,
          ),
        );
      }

      // 광고가 로드되지 않았을 때 표시할 빈 공간
      return const SizedBox(height: 50, width: double.infinity);
    });
  }
}