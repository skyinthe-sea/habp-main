class CategoryItem {
  final int id;
  final String name;
  final String type; // INCOME, EXPENSE, FINANCE
  final bool isFixed;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.type,
    this.isFixed = false,
  });
}