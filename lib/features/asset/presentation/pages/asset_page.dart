// lib/features/asset/presentation/pages/asset_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/db_helper.dart';
import '../../data/datasources/asset_local_data_source.dart';
import '../../data/repositories/asset_repository_impl.dart';
import '../../domain/usecases/add_asset.dart';
import '../../domain/usecases/delete_asset.dart';
import '../../domain/usecases/get_asset_categories.dart';
import '../../domain/usecases/get_assets.dart';
import '../../domain/usecases/get_asset_summary.dart';
import '../../domain/usecases/update_asset.dart';
import '../controllers/asset_controller.dart';
import '../widgets/asset_summary_card.dart';
import '../widgets/asset_category_filter.dart';
import '../widgets/asset_list.dart';
import '../widgets/add_asset_dialog.dart';

class AssetPage extends StatefulWidget {
  const AssetPage({Key? key}) : super(key: key);

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> with AutomaticKeepAliveClientMixin {
  late AssetController _controller;
  late Future<void> _initFuture;
  bool _isInitialized = false;

  // AutomaticKeepAliveClientMixin 상태 유지
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = _initController();
    _initFuture = _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 보일 때마다 데이터 새로고침
    if (_isInitialized) {
      _refreshData();
    }
  }

  void _refreshData() {
    if (!_controller.isLoading.value) {
      debugPrint('AssetPage: 데이터 새로고침');
      _controller.loadData();
    }
  }

  AssetController _initController() {
    // Check if controller already exists to avoid duplication on hot restart
    if (Get.isRegistered<AssetController>()) {
      final controller = Get.find<AssetController>();
      // Reset any necessary state
      controller.dataInitialized.value = false;
      // Trigger data reload
      controller.loadData();
      return controller;
    }

    // 의존성 주입
    final dbHelper = DBHelper();
    final dataSource = AssetLocalDataSourceImpl(dbHelper: dbHelper);
    final repository = AssetRepositoryImpl(localDataSource: dataSource);
    final getAssetsUseCase = GetAssets(repository);
    final getAssetSummaryUseCase = GetAssetSummary(repository);
    final getAssetCategoriesUseCase = GetAssetCategories(repository);
    final addAssetUseCase = AddAsset(repository);
    final updateAssetUseCase = UpdateAsset(repository);
    final deleteAssetUseCase = DeleteAsset(repository);

    // 컨트롤러를 영구적으로 등록 (앱 재시작할 때도 유지)
    return Get.put(
      AssetController(
        getAssetsUseCase: getAssetsUseCase,
        getAssetSummaryUseCase: getAssetSummaryUseCase,
        getAssetCategoriesUseCase: getAssetCategoriesUseCase,
        addAssetUseCase: addAssetUseCase,
        updateAssetUseCase: updateAssetUseCase,
        deleteAssetUseCase: deleteAssetUseCase,
      ),
      permanent: true,
    );
  }

  // 초기 데이터 로드
  Future<void> _loadInitialData() async {
    debugPrint('AssetPage: 초기 데이터 로드 시작');
    try {
      await _controller.loadData();
      _isInitialized = true;
      debugPrint('AssetPage: 초기 데이터 로드 완료');
    } catch (e) {
      debugPrint('AssetPage: 초기 데이터 로드 오류 - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 필수

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // 초기 데이터 로드 중일 때 로딩 표시
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: GetBuilder<AssetController>(
              init: _controller,
              builder: (controller) {
                return Column(
                  children: [
                    // 상단 헤더 (타이틀)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '나의 자산',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _refreshData,
                          ),
                        ],
                      ),
                    ),

                    // 스크롤 가능한 콘텐츠
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await controller.loadData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Obx(() {
                            // 로딩 중이고 데이터가 없을 때 로딩 표시
                            if (controller.isLoading.value &&
                                controller.assets.isEmpty) {
                              return SizedBox(
                                height: MediaQuery.of(context).size.height - 150,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 자산 요약 카드
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: AssetSummaryCard(
                                    assetSummary: controller.assetSummary.value,
                                    showAnimation: controller.showSummaryAnimation.value,
                                  ),
                                ),

                                // 카테고리 필터
                                if (controller.assets.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                                    child: AssetCategoryFilter(
                                      categories: controller.assetCategories,
                                      selectedCategory: controller.selectedCategoryFilter.value,
                                      onCategorySelected: controller.filterByCategory,
                                    ),
                                  ),

                                // 자산 리스트
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: controller.assets.isEmpty
                                      ? _buildEmptyState()
                                      : AssetList(
                                    assets: controller.getFilteredAssets(),
                                    categories: controller.assetCategories,
                                    onDeleteAsset: controller.deleteAsset,
                                    onUpdateAsset: controller.updateAsset,
                                    showAnimation: controller.showAssetsAnimation.value,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppColors.primary,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddAssetDialog(controller: _controller),
              );
            },
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  // lib/features/asset/presentation/pages/asset_page.dart의 _buildEmptyState 함수 수정

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 32),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 자산이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오른쪽 하단의 + 버튼을 눌러 자산을 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddAssetDialog(controller: _controller),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('자산 추가하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}