import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/category_model.dart';
import '../controllers/expense_controller.dart';
import 'category_item.dart';
import 'add_category_dialog.dart';

class AnimatedCategoryList extends StatefulWidget {
  final ExpenseController controller;
  final int? selectedCategoryId;
  final Function(int) onCategorySelected;
  final List<int> previousCategoryIds;

  const AnimatedCategoryList({
    Key? key,
    required this.controller,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.previousCategoryIds,
  }) : super(key: key);

  @override
  State<AnimatedCategoryList> createState() => _AnimatedCategoryListState();
}

class _AnimatedCategoryListState extends State<AnimatedCategoryList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<CategoryModel> _currentCategories;

  @override
  void initState() {
    super.initState();
    _currentCategories = [];

    // 첫 번째 렌더링 후 카테고리 목록을 설정하기 위한 post-frame 콜백
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentCategories();
    });
  }

  void _setCurrentCategories() {
    setState(() {
      _currentCategories = widget.controller.variableCategories.toList();
    });
  }

  @override
  void didUpdateWidget(AnimatedCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 카테고리 변경 사항 감지 및 애니메이션 처리
    final newCategories = widget.controller.variableCategories;

    // 카테고리가 추가된 경우
    if (newCategories.length > _currentCategories.length) {
      for (final category in newCategories) {
        if (!_currentCategories.any((c) => c.id == category.id)) {
          // 새 카테고리 추가
          _currentCategories.add(category);
          _listKey.currentState?.insertItem(
            _currentCategories.length - 1,
            duration: const Duration(milliseconds: 500),
          );
        }
      }
    }
    // 카테고리가 삭제된 경우
    else if (newCategories.length < _currentCategories.length) {
      for (int i = _currentCategories.length - 1; i >= 0; i--) {
        final existingCategory = _currentCategories[i];
        if (!newCategories.any((c) => c.id == existingCategory.id)) {
          // 삭제된 카테고리 애니메이션 처리
          final removedItem = _currentCategories[i];
          _currentCategories.removeAt(i);

          _listKey.currentState?.removeItem(
            i,
                (context, animation) => SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: CategoryItem(
                    category: removedItem,
                    isSelected: widget.selectedCategoryId == removedItem.id,
                    isNewlyAdded: false,
                    onTap: () {},
                    onLongPress: () {},
                  ),
                ),
              ),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = widget.controller.variableCategories;

      return categories.isEmpty
          ? Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '변동 지출 카테고리가 없습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('카테고리 추가하기'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddCategoryDialog(
                    controller: widget.controller,
                    onCategoryAdded: widget.onCategorySelected,
                  ),
                );
              },
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        child: AnimatedList(
          key: _listKey,
          initialItemCount: categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index, animation) {
            final category = categories[index];
            final isSelected = widget.selectedCategoryId == category.id;
            final isNewlyAdded = isSelected &&
                !widget.previousCategoryIds.contains(category.id);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: CategoryItem(
                  category: category,
                  isSelected: isSelected,
                  isNewlyAdded: isNewlyAdded,
                  onTap: () => widget.onCategorySelected(category.id),
                  onLongPress: () {
                    _showDeleteCategoryDialog(context, category);
                  },
                ),
              ),
            );
          },
        ),
      );
    });
  }

  // 카테고리 삭제 다이얼로그
  void _showDeleteCategoryDialog(BuildContext context, CategoryModel category) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '카테고리 삭제',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\'${category.name}\' 예산 정보를 삭제하시겠습니까?',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          StatefulBuilder(
            builder: (context, setDialogState) {
              return TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                  setDialogState(() {
                    isDeleting = true;
                  });

                  // 카테고리 삭제
                  final success = await widget.controller.deleteCategory(category.id);

                  Navigator.of(context).pop();

                  // 결과 알림
                  if (success) {
                    Get.snackbar(
                      '성공',
                      '카테고리가 삭제되었습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  } else {
                    Get.snackbar(
                      '오류',
                      '카테고리 삭제에 실패했습니다.',
                      snackPosition: SnackPosition.TOP,
                    );
                  }
                },
                child: isDeleting
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                )
                    : Text(
                  '삭제',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}