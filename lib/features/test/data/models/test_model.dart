import '../../domain/entities/test_entity.dart';

class TestModel extends TestEntity {
  TestModel({
    super.id,
    required super.data,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'data': data,
    'created_at': createdAt.toIso8601String(),
  };

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] as int,
      data: json['data'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  factory TestModel.fromEntity(TestEntity entity) {
    return TestModel(
      id: entity.id,
      data: entity.data,
      createdAt: entity.createdAt,
    );
  }
}