class Category {
  final int id;
  final String name;
  final int? parentId;
  final String? parentName;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
  });
}

