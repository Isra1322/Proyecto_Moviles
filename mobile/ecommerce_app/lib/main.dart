import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

// Core
import 'core/constants/api_constants.dart';

// Infrastructure
import 'infrastructure/http/api_client.dart';
import 'infrastructure/datasources/remote/product_remote_data_source.dart';
import 'infrastructure/datasources/remote/order_remote_data_source.dart';
import 'infrastructure/datasources/remote/auth_remote_data_source.dart';
import 'infrastructure/datasources/local/auth_local_data_source.dart';
import 'infrastructure/datasources/local/cart_local_data_source.dart';
import 'infrastructure/repositories_impl/product_repository_impl.dart';
import 'infrastructure/repositories_impl/order_repository_impl.dart';
import 'infrastructure/repositories_impl/auth_repository_impl.dart';
import 'infrastructure/repositories_impl/cart_repository_impl.dart';

// Casos de Uso (Products)
import 'application/use_cases/products/get_products_use_case.dart';
import 'application/use_cases/products/get_product_by_id_use_case.dart';
import 'application/use_cases/products/get_categories_use_case.dart';

// Casos de Uso (Auth)
import 'application/use_cases/auth/login_use_case.dart';
import 'application/use_cases/auth/register_use_case.dart';
import 'application/use_cases/auth/get_saved_user_use_case.dart';
import 'application/use_cases/auth/logout_use_case.dart';

// Casos de Uso (Cart)
import 'application/use_cases/cart/get_cart_use_case.dart';
import 'application/use_cases/cart/add_to_cart_use_case.dart';
import 'application/use_cases/cart/update_cart_quantity_use_case.dart';
import 'application/use_cases/cart/remove_from_cart_use_case.dart';
import 'application/use_cases/cart/clear_cart_use_case.dart';

// Casos de Uso (Orders)
import 'application/use_cases/orders/create_order_use_case.dart';
import 'application/use_cases/orders/get_orders_use_case.dart';
import 'application/use_cases/orders/get_order_by_id_use_case.dart';

// Providers
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/order_provider.dart';

// Rutas
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);
  await initializeDateFormatting('es', null);

  // 1. Inicializar dependencias base
  final prefs = await SharedPreferences.getInstance();
  final httpClient = http.Client();

  // 2. API Client
  final apiClient = ApiClient(
    client: httpClient,
    baseUrl: ApiConstants.baseUrl,
  );

  // 3. Data Sources
  final productRemoteDataSource = ProductRemoteDataSource(apiClient);
  final orderRemoteDataSource = OrderRemoteDataSource(apiClient);
  final authRemoteDataSource = AuthRemoteDataSource(apiClient);
  final authLocalDataSource = AuthLocalDataSource(prefs);
  final cartLocalDataSource = CartLocalDataSource(prefs);

  // Si hay sesión guardada previa, inyectar el token JWT en el ApiClient
  final savedUser = await authLocalDataSource.getUser();
  if (savedUser != null && savedUser.accessToken != null) {
    apiClient.setAuthToken(savedUser.accessToken);
  }

  // 4. Repositorios (Implementaciones)
  final productRepository = ProductRepositoryImpl(productRemoteDataSource);
  final orderRepository = OrderRepositoryImpl(orderRemoteDataSource);
  final authRepository = AuthRepositoryImpl(
    authRemoteDataSource,
    authLocalDataSource,
  );
  final cartRepository = CartRepositoryImpl(cartLocalDataSource);

  // 5. Casos de Uso
  // - Products
  final getProductsUseCase = GetProductsUseCase(productRepository);
  final getProductByIdUseCase = GetProductByIdUseCase(productRepository);
  final getCategoriesUseCase = GetCategoriesUseCase(productRepository);

  // - Auth
  final loginUseCase = LoginUseCase(authRepository);
  final registerUseCase = RegisterUseCase(authRepository);
  final getSavedUserUseCase = GetSavedUserUseCase(authRepository);
  final logoutUseCase = LogoutUseCase(authRepository);

  // - Cart
  final getCartUseCase = GetCartUseCase(cartRepository);
  final addToCartUseCase = AddToCartUseCase(cartRepository);
  final updateCartQuantityUseCase = UpdateCartQuantityUseCase(cartRepository);
  final removeFromCartUseCase = RemoveFromCartUseCase(cartRepository);
  final clearCartUseCase = ClearCartUseCase(cartRepository);

  // - Orders
  final createOrderUseCase = CreateOrderUseCase(
    orderRepository,
    cartRepository,
  );
  final getOrdersUseCase = GetOrdersUseCase(orderRepository);
  final getOrderByIdUseCase = GetOrderByIdUseCase(orderRepository);

  // 6. Ejecutar la App con MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            loginUseCase,
            registerUseCase,
            getSavedUserUseCase,
            logoutUseCase,
          )..checkSavedSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            getProductsUseCase,
            getProductByIdUseCase,
            getCategoriesUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(
            getCartUseCase,
            addToCartUseCase,
            updateCartQuantityUseCase,
            removeFromCartUseCase,
            clearCartUseCase,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(
            createOrderUseCase,
            getOrdersUseCase,
            getOrderByIdUseCase,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce Odoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      routes: AppRoutes.routes,
    );
  }
}
