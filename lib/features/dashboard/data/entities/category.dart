class Category {
  final int id;
  final String name;
  final String type;
  final int isFixed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.isFixed,
    required this.createdAt,
    required this.updatedAt,
  });
}