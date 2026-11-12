class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double stock;
  final int? categoryId;
  final String? categoryName;
  final String? imageUrl;
  final String? barcode;
  final String? defaultCode;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
    this.barcode,
    this.defaultCode,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String?,
      defaultCode: json['defaultCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'defaultCode': defaultCode,
    };
  }
}

