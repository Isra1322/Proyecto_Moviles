import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/catalog/categories_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/order_history_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/order_success_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String catalog = '/catalog';
  static const String categories = '/categories';
  static const String profile = '/profile';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String orderHistory = '/order-history';
  static const String orderDetail = '/order-detail';
  static const String orderSuccess = '/order-success';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        catalog: (_) => const MainNavigationScreen(),
        categories: (_) => const CategoriesScreen(),
        profile: (_) => const ProfileScreen(),
        cart: (_) => const CartScreen(),
        orderHistory: (_) => const OrderHistoryScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case productDetail:
        if (settings.arguments is Product) {
          final product = settings.arguments as Product;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: product.id,
              initialProduct: product,
            ),
            settings: settings,
          );
        } else if (settings.arguments is int) {
          final productId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: productId),
            settings: settings,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Argumento de producto inválido.')),
            ),
          );
        }
      case orderDetail:
        if (settings.arguments is Order) {
          final order = settings.arguments as Order;
          return MaterialPageRoute(
            builder: (_) => OrderDetailScreen(order: order),
            settings: settings,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Argumento de pedido inválido.')),
            ),
          );
        }
      case orderSuccess:
        final order = settings.arguments as Order;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: order),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Ruta no encontrada.')),
          ),
        );
    }
  }
}
