import 'package:ecommerce_app/core/constants/api_constants.dart';
import 'package:ecommerce_app/infrastructure/http/api_client.dart';
import 'package:ecommerce_app/infrastructure/models/category_model.dart';
import 'package:ecommerce_app/infrastructure/models/product_model.dart';

class ProductRemoteDataSource {
  final ApiClient _client;

  ProductRemoteDataSource(this._client);

  Future<List<ProductModel>> getProducts({int? categoryId}) async {
    final queryParams = <String, String>{};
    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId.toString();
    }

    final data = await _client.get(
      ApiConstants.products,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map<ProductModel>((item) => ProductModel.fromJson(item))
          .toList();
    }
    return <ProductModel>[];
  }

  Future<ProductModel> getProductById(int id) async {
    final data = await _client.get('${ApiConstants.products}/$id');
    if (data is Map<String, dynamic>) {
      return ProductModel.fromJson(data);
    }
    throw FormatException('Formato inesperado para el producto con ID $id.');
  }

  Future<List<CategoryModel>> getCategories() async {
    final data = await _client.get(ApiConstants.categories);
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map<CategoryModel>((item) => CategoryModel.fromJson(item))
          .toList();
    }
    return <CategoryModel>[];
  }
}
