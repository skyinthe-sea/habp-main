// lib/features/asset/presentation/controllers/asset_controller.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/services/event_bus_service.dart';
import '../../data/models/asset_category_model.dart';
import '../../domain/entities/asset.dart';
import '../../domain/entities/asset_summary.dart';
import '../../domain/usecases/add_asset.dart';
import '../../domain/usecases/delete_asset.dart';
import '../../domain/usecases/get_asset_categories.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_asset_summary.dart';
import '../../domain/usecases/update_asset.dart';

class AssetController extends GetxController {
  final GetAssets getAssetsUseCase;
  final GetAssetSummary getAssetSummaryUseCase;
  final GetAssetCategories getAssetCategoriesUseCase;
  final AddAsset addAssetUseCase;
  final UpdateAsset updateAssetUseCase;
  final DeleteAsset deleteAssetUseCase;

  AssetController({
    required this.getAssetsUseCase,
    required this.getAssetSummaryUseCase,
    required this.getAssetCategoriesUseCase,
    required this.addAssetUseCase,
    required this.updateAssetUseCase,
    required this.deleteAssetUseCase,
  });

  // 상태 변수
  final RxList<Asset> assets = <Asset>[].obs;
  final Rx<AssetSummary?> assetSummary = Rx<AssetSummary?>(null);
  final RxList<AssetCategoryModel> assetCategories = <AssetCategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool dataInitialized = false.obs;

  // 애니메이션 관련 상태
  final RxBool showSummaryAnimation = false.obs;
  final RxBool showAssetsAnimation = false.obs;

  // 필터링 상태
  final RxString selectedCategoryFilter = 'ALL'.obs;

  // 사용자 ID (실제 앱에서는 인증에서 가져옴)
  final int userId = 1;

  // EventBusService 인스턴스
  late final EventBusService _eventBusService;

  @override
  void onInit() {
    super.onInit();

    // EventBusService 가져오기
    _eventBusService = Get.find<EventBusService>();

    // 트랜잭션 변경 이벤트 구독
    ever(_eventBusService.transactionChanged, (_) {
      debugPrint('자산 변경 이벤트 감지됨: 자산 데이터 새로고침');
      loadData();
    });

    // 초기 데이터 로드
    loadData();
  }

  @override
  void onReady() {
    super.onReady();
    // UI가 모두 준비된 후에 다시 한번 데이터 로드 시도
    if (!dataInitialized.value) {
      debugPrint('AssetController: onReady에서 데이터 다시 로드');
      loadData();
    }
  }

  // 모든 데이터 로드 메서드
  Future<void> loadData() async {
    debugPrint('AssetController: 모든 데이터 로드 시작');
    isLoading.value = true;

    try {
      await Future.wait([
        fetchAssets(),
        fetchAssetSummary(),
        fetchAssetCategories(),
      ]);

      // 데이터 로드 후 애니메이션 시작
      Future.delayed(const Duration(milliseconds: 300), () {
        showSummaryAnimation.value = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        showAssetsAnimation.value = true;
      });

      dataInitialized.value = true;
      debugPrint('AssetController: 모든 데이터 로드 완료');
    } catch (e) {
      debugPrint('AssetController: 데이터 로드 중 오류: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAssets() async {
    try {
      final result = await getAssetsUseCase(userId);
      assets.assignAll(result);
      assets.refresh();
      debugPrint('AssetController: 자산 데이터 로드 - ${result.length}개 항목');
    } catch (e) {
      debugPrint('자산 데이터 가져오는 중 오류: $e');
    }
  }

  Future<void> fetchAssetSummary() async {
    try {
      final result = await getAssetSummaryUseCase(userId);
      assetSummary.value = result;
      debugPrint('AssetController: 자산 요약 데이터 로드 완료');
    } catch (e) {
      debugPrint('자산 요약 데이터 가져오는 중 오류: $e');
    }
  }

  Future<void> fetchAssetCategories() async {
    try {
      final result = await getAssetCategoriesUseCase();
      assetCategories.assignAll(result);
      assetCategories.refresh();
      debugPrint('AssetController: 자산 카테고리 데이터 로드 - ${result.length}개 항목');
    } catch (e) {
      debugPrint('자산 카테고리 가져오는 중 오류: $e');
    }
  }

  void filterByCategory(String categoryName) {
    selectedCategoryFilter.value = categoryName;
    update();
  }

  List<Asset> getFilteredAssets() {
    if (selectedCategoryFilter.value == 'ALL') {
      return assets;
    }
    return assets.where((asset) => asset.categoryName == selectedCategoryFilter.value).toList();
  }

  // 자산 추가 메서드
  Future<bool> addAsset({
    required int categoryId,
    required String name,
    required double currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    try {
      final assetId = await addAssetUseCase(
        userId: userId,
        categoryId: categoryId,
        name: name,
        currentValue: currentValue,
        purchaseValue: purchaseValue,
        purchaseDate: purchaseDate,
        interestRate: interestRate,
        loanAmount: loanAmount,
        description: description,
        location: location,
        details: details,
        iconType: iconType,
      );

      if (assetId != null) {
        // 자산 목록과 요약 다시 불러오기
        await loadData();

        // 애니메이션 초기화 후 다시 시작
        showSummaryAnimation.value = false;
        showAssetsAnimation.value = false;

        Future.delayed(const Duration(milliseconds: 300), () {
          showSummaryAnimation.value = true;
        });

        Future.delayed(const Duration(milliseconds: 600), () {
          showAssetsAnimation.value = true;
        });

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('자산 추가 중 오류: $e');
      return false;
    }
  }

  // 자산 업데이트 메서드
  Future<bool> updateAsset({
    required int assetId,
    int? categoryId,
    String? name,
    double? currentValue,
    double? purchaseValue,
    String? purchaseDate,
    double? interestRate,
    double? loanAmount,
    String? description,
    String? location,
    String? details,
    String? iconType,
  }) async {
    try {
      final result = await updateAssetUseCase(
        assetId: assetId,
        categoryId: categoryId,
        name: name,
        currentValue: currentValue,
        purchaseValue: purchaseValue,
        purchaseDate: purchaseDate,
        interestRate: interestRate,
        loanAmount: loanAmount,
        description: description,
        location: location,
        details: details,
        iconType: iconType,
      );

      if (result) {
        // 자산 목록과 요약 다시 불러오기
        await loadData();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('자산 업데이트 중 오류: $e');
      return false;
    }
  }

  // 자산 삭제 메서드
  Future<bool> deleteAsset(int assetId) async {
    try {
      final result = await deleteAssetUseCase(assetId);

      if (result) {
        // 자산 목록과 요약 다시 불러오기
        await loadData();

        // 이벤트 버스를 통해 변경 알림
        _eventBusService.emitTransactionChanged();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('자산 삭제 중 오류: $e');
      return false;
    }
  }
}