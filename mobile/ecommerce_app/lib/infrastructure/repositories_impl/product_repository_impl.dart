import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/domain/repositories/i_product_repository.dart';
import 'package:ecommerce_app/infrastructure/datasources/remote/product_remote_data_source.dart';
import 'package:ecommerce_app/infrastructure/mappers/category_mapper.dart';
import 'package:ecommerce_app/infrastructure/mappers/product_mapper.dart';

class ProductRepositoryImpl implements IProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> getProducts({int? categoryId}) async {
    final models = await _remoteDataSource.getProducts(categoryId: categoryId);
    return models.map<Product>(ProductMapper.toEntity).toList();
  }

  @override
  Future<Product> getProductById(int id) async {
    final model = await _remoteDataSource.getProductById(id);
    return ProductMapper.toEntity(model);
  }

  @override
  Future<List<Category>> getCategories() async {
    final models = await _remoteDataSource.getCategories();
    return models.map<Category>(CategoryMapper.toEntity).toList();
  }
}
