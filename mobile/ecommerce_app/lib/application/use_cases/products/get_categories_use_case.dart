import '../../../domain/entities/category.dart';
import '../../../domain/repositories/i_product_repository.dart';

class GetCategoriesUseCase {
  final IProductRepository _repository;

  GetCategoriesUseCase(this._repository);

  Future<List<Category>> execute() async {
    return await _repository.getCategories();
  }
}

