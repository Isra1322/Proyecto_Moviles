import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_product_repository.dart';

class GetProductsUseCase {
  final IProductRepository _repository;

  GetProductsUseCase(this._repository);

  Future<List<Product>> execute({int? categoryId}) async {
    return await _repository.getProducts(categoryId: categoryId);
  }
}

