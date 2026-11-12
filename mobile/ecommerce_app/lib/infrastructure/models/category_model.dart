class CategoryModel {
  final int id;
  final String name;
  final int? parentId;
  final String? parentName;

  const CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as int?,
      parentName: json['parentName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'parentName': parentName,
    };
  }
}

