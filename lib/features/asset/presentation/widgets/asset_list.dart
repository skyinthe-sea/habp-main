// lib/features/asset/presentation/widgets/asset_list.dart
import 'package:flutter/material.dart';
import '../../data/models/asset_category_model.dart';
import '../../domain/entities/asset.dart';
import 'asset_item.dart';
import 'asset_detail_dialog.dart';

class AssetList extends StatelessWidget {
  final List<Asset> assets;
  final List<AssetCategoryModel> categories;
  final Function(int) onDeleteAsset;
  final Function({
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
  }) onUpdateAsset;
  final bool showAnimation;

  const AssetList({
    Key? key,
    required this.assets,
    required this.categories,
    required this.onDeleteAsset,
    required this.onUpdateAsset,
    required this.showAnimation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            '표시할 자산이 없습니다',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];

        // 애니메이션 지연 계산 (각 항목마다 약간의 지연 효과 추가)
        final animationDelay = Duration(milliseconds: 100 * index);

        return FutureBuilder(
          future: Future.delayed(animationDelay),
          builder: (context, snapshot) {
            final shouldAnimate = snapshot.connectionState == ConnectionState.done && showAnimation;

            return AnimatedOpacity(
              opacity: shouldAnimate ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedSlide(
                offset: shouldAnimate ? Offset.zero : const Offset(0.2, 0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AssetItem(
                    asset: asset,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AssetDetailDialog(
                          asset: asset,
                          categories: categories,
                          onUpdate: onUpdateAsset,
                          onDelete: () => onDeleteAsset(asset.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}