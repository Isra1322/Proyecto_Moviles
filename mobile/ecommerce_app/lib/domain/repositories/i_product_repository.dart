import '../entities/category.dart';
import '../entities/product.dart';

abstract class IProductRepository {
  Future<List<Product>> getProducts({int? categoryId});
  Future<Product> getProductById(int id);
  Future<List<Category>> getCategories();
}

