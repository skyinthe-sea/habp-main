// lib/core/services/ad_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends GetxService {
  // BannerAd? _bannerAd;
  // final Rx<BannerAd?> bannerAd = Rx<BannerAd?>(null);
  // final RxBool isBannerAdLoaded = false.obs;
  //
  // // 실제 앱에서는 아래 테스트 ID를 실제 AdMob ID로 교체해야 합니다
  // final String _adUnitId = kDebugMode
  //     ? 'ca-app-pub-3940256099942544/6300978111'  // 테스트 광고 ID
  //     : 'ca-app-pub-3940256099942544/6300978111'; // 실제 광고 ID로 교체
  //
  // @override
  // void onInit() {
  //   super.onInit();
  //   _loadBannerAd();
  // }
  //
  // @override
  // void onClose() {
  //   _bannerAd?.dispose();
  //   super.onClose();
  // }
  //
  // // 배너 광고 로드 메서드
  // void _loadBannerAd() {
  //   _bannerAd = BannerAd(
  //     adUnitId: _adUnitId,
  //     size: AdSize.banner,
  //     request: const AdRequest(),
  //     listener: BannerAdListener(
  //       onAdLoaded: (ad) {
  //         debugPrint('배너 광고 로드 성공');
  //         bannerAd.value = ad as BannerAd;
  //         isBannerAdLoaded.value = true;
  //       },
  //       onAdFailedToLoad: (ad, error) {
  //         debugPrint('배너 광고 로드 실패: ${error.message}');
  //         ad.dispose();
  //         isBannerAdLoaded.value = false;
  //
  //         // 실패 시 재시도 로직
  //         Future.delayed(const Duration(minutes: 1), () {
  //           _loadBannerAd();
  //         });
  //       },
  //     ),
  //   );
  //
  //   _bannerAd?.load();
  // }
  //
  // // 배너 광고 위젯
  // Widget getBannerAdWidget() {
  //   return Obx(() {
  //     if (isBannerAdLoaded.value && bannerAd.value != null) {
  //       return Container(
  //         width: bannerAd.value!.size.width.toDouble(),
  //         height: bannerAd.value!.size.height.toDouble(),
  //         alignment: Alignment.center,
  //         child: AdWidget(ad: bannerAd.value!),
  //       );
  //     }
  //     // 광고가 로드되지 않았을 때 표시할 빈 공간
  //     return SizedBox(height: 50);
  //   });
  // }
  //
  // // AdMob 서비스 초기화 및 인스턴스 반환
  // Future<AdService> init() async {
  //   // 여기에 추가 초기화 코드를 넣을 수 있습니다
  //   return this;
  // }
}