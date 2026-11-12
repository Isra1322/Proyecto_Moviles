import '../../../domain/entities/product.dart';
import '../../../domain/repositories/i_product_repository.dart';

class GetProductByIdUseCase {
  final IProductRepository _repository;

  GetProductByIdUseCase(this._repository);

  Future<Product> execute(int id) async {
    if (id <= 0) {
      throw ArgumentError('El identificador del producto es inválido.');
    }
    return await _repository.getProductById(id);
  }
}

