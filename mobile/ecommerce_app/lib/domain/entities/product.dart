class Product {
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

  const Product({
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

  bool get isInStock => stock > 0;
}

