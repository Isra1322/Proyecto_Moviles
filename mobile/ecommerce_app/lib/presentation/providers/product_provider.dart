import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/application/use_cases/products/get_products_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_product_by_id_use_case.dart';
import 'package:ecommerce_app/application/use_cases/products/get_categories_use_case.dart';
import 'auth_provider.dart';

enum ProductSortOption {
  none,
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
}

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
  List<Product> _allProducts = [];
  List<Category> _categories = [];
  Product? _selectedProduct;
  String? _errorMessage;
  int? _selectedCategoryId;

  // Filtrado y búsqueda en tiempo real
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  ProductSortOption _sortOption = ProductSortOption.none;

  ViewStatus get status => _status;
  ViewStatus get detailStatus => _detailStatus;
  List<Category> get categories => _categories;
  Product? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _status == ViewStatus.loading;

  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  ProductSortOption get sortOption => _sortOption;
  List<Product> get allProducts => _allProducts;

  bool get hasPriceFilter => _minPrice != null || _maxPrice != null;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      hasPriceFilter ||
      _sortOption != ProductSortOption.none ||
      _selectedCategoryId != null;

  double get minAvailablePrice {
    if (_allProducts.isEmpty) return 0.0;
    return _allProducts
        .map((p) => p.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxAvailablePrice {
    if (_allProducts.isEmpty) return 100.0;
    return _allProducts
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Retorna la lista de productos tras aplicar búsqueda, rango de precios y ordenación
  List<Product> get products {
    var list = List<Product>.from(_allProducts);

    // 1. Filtro por buscador (nombre o descripción)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final matchesName = p.name.toLowerCase().contains(q);
        final matchesDesc =
            p.description != null && p.description!.toLowerCase().contains(q);
        return matchesName || matchesDesc;
      }).toList();
    }

    // 2. Filtro por rango de precios
    if (_minPrice != null) {
      list = list.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      list = list.where((p) => p.price <= _maxPrice!).toList();
    }

    // 3. Ordenación
    switch (_sortOption) {
      case ProductSortOption.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSortOption.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case ProductSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOption.none:
        break;
    }

    return list;
  }

  Future<void> loadProducts({int? categoryId}) async {
    _status = ViewStatus.loading;
    _errorMessage = null;
    _selectedCategoryId = categoryId;
    notifyListeners();
    try {
      _allProducts = await _getProductsUseCase.execute(categoryId: categoryId);
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
    final existingIndex = _allProducts.indexWhere((p) => p.id == id);
    if (existingIndex != -1) {
      _selectedProduct = _allProducts[existingIndex];
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

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void resetPriceRange() {
    _minPrice = null;
    _maxPrice = null;
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _minPrice = null;
    _maxPrice = null;
    _sortOption = ProductSortOption.none;
    _selectedCategoryId = null;
    loadProducts();
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
