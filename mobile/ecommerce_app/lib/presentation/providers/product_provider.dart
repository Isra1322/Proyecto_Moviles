import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/application/use_cases/products/get_products_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_product_by_id_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_categories_use_case.dart';
import 'auth_provider.dart';

class ProductProvider extends ChangeNotifier {
  final GetProductsUseCase _getProductsUseCase;
  final GetProductByIdUseCase _getProductByIdUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  ProductProvider(
    this._getProductsUseCase,
    this._getProductByIdUseCase,
    this._getCategoriesUseCase,
  );

  ViewStatus _status = ViewStatus.initial;
  ViewStatus _detailStatus = ViewStatus.initial;
  List<Product> _products = [];
  List<Category> _categories = [];
  Product? _selectedProduct;
  String? _errorMessage;
  int? _selectedCategoryId;

  ViewStatus get status => _status;
  ViewStatus get detailStatus => _detailStatus;
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _status == ViewStatus.loading;

  Future<void> loadProducts({int? categoryId}) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    _selectedCategoryId = categoryId;
    notifyListeners();
    try {
      _products = await _getProductsUseCase.execute(categoryId: categoryId);
      _status = ViewStatus.success;
    } catch (e) {
      _errorMessage = _friendlyMessage(e);
      _status = ViewStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _getCategoriesUseCase.execute();
      notifyListeners();
    } catch (_) {
      // Las categorías no son críticas; no bloquear la pantalla si fallan
    }
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    _detailStatus = ViewStatus.success;
    notifyListeners();
  }

  Future<void> loadProductDetail(int id) async {
    final existingIndex = _products.indexWhere((p) => p.id == id);
    if (existingIndex != -1) {
      _selectedProduct = _products[existingIndex];
      _detailStatus = ViewStatus.success;
      notifyListeners();
    } else {
      _detailStatus = ViewStatus.loading;
      _selectedProduct = null;
      notifyListeners();
    }

    try {
      final fetched = await _getProductByIdUseCase.execute(id);
      _selectedProduct = fetched;
      _detailStatus = ViewStatus.success;
    } catch (e) {
      if (_selectedProduct == null) {
        _errorMessage = _friendlyMessage(e);
        _detailStatus = ViewStatus.error;
      }
    }
    notifyListeners();
  }

  void filterByCategory(int? categoryId) {
    loadProducts(categoryId: categoryId);
  }

  String _friendlyMessage(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('NetworkException')) {
      return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
    }
    if (msg.contains('TimeoutException')) {
      return 'Tiempo de espera agotado. El servidor tardó demasiado.';
    }
    return msg.replaceAll('Exception: ', '').replaceAll('ServerException: ', '');
  }
}

