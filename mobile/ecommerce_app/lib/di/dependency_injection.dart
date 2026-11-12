// ignore_for_file: unused_local_variable
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../infrastructure/http/api_client.dart';
import '../infrastructure/datasources/remote/product_remote_data_source.dart';
import '../infrastructure/datasources/remote/order_remote_data_source.dart';
import '../infrastructure/datasources/remote/auth_remote_data_source.dart';
import '../infrastructure/datasources/local/auth_local_data_source.dart';
import '../infrastructure/datasources/local/cart_local_data_source.dart';
import '../infrastructure/repositories_impl/product_repository_impl.dart';
import '../infrastructure/repositories_impl/order_repository_impl.dart';
import '../infrastructure/repositories_impl/auth_repository_impl.dart';
import '../infrastructure/repositories_impl/cart_repository_impl.dart';

import '../application/use_cases/products/get_products_use_case.dart';
import '../application/use_cases/auth/login_use_case.dart';
import '../application/use_cases/auth/register_use_case.dart';
import '../application/use_cases/cart/add_to_cart_use_case.dart';
import '../application/use_cases/cart/update_cart_quantity_use_case.dart';
import '../application/use_cases/cart/remove_from_cart_use_case.dart';
import '../application/use_cases/orders/create_order_use_case.dart';
import '../application/use_cases/orders/get_orders_use_case.dart';

class DependencyInjection {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final httpClient = http.Client();

    // API Client
    final apiClient = ApiClient(
      client: httpClient,
      baseUrl: ApiConstants.baseUrl,
    );
    // Data Sources
    final productRemoteDataSource = ProductRemoteDataSource(apiClient);
    final orderRemoteDataSource = OrderRemoteDataSource(apiClient);
    final authRemoteDataSource = AuthRemoteDataSource(apiClient);
    final authLocalDataSource = AuthLocalDataSource(prefs);
    final cartLocalDataSource = CartLocalDataSource(prefs);

    // Repositorios
    final productRepository = ProductRepositoryImpl(productRemoteDataSource);
    final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);
    final authRepository = AuthRepositoryImpl(
      authRemoteDataSource,
      authLocalDataSource,
    );
    final cartRepository = CartRepositoryImpl(cartLocalDataSource);

    // Casos de uso
    final getProductsUseCase = GetProductsUseCase(productRepository);
    final loginUseCase = LoginUseCase(authRepository);
    final registerUseCase = RegisterUseCase(authRepository);
    final addToCartUseCase = AddToCartUseCase(cartRepository);
    final updateCartQuantityUseCase = UpdateCartQuantityUseCase(cartRepository);
    final removeFromCartUseCase = RemoveFromCartUseCase(cartRepository);
    final createOrderUseCase = CreateOrderUseCase(
      orderRepository,
      cartRepository,
    );
    final getOrdersUseCase = GetOrdersUseCase(orderRepository);
  }
}
