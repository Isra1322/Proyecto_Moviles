import '../../domain/entities/product.dart';
import '../models/product_model.dart';

class ProductMapper {
  static Product toEntity(ProductModel model) {
    return Product(
      id: model.id,
      name: model.name,
      description: model.description,
      price: model.price,
      stock: model.stock,
      categoryId: model.categoryId,
      categoryName: model.categoryName,
      imageUrl: model.imageUrl,
      barcode: model.barcode,
      defaultCode: model.defaultCode,
    );
  }

  static ProductModel toModel(Product entity) {
    return ProductModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      stock: entity.stock,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      imageUrl: entity.imageUrl,
      barcode: entity.barcode,
      defaultCode: entity.defaultCode,
    );
  }
}

