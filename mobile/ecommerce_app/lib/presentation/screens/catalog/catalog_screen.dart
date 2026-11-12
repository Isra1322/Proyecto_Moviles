import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/product/category_selector.dart';
import '../../widgets/cart/cart_badge_icon.dart';
import '../../routes/app_routes.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      provider.loadProducts();
      provider.loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        actions: [
          CartBadgeIcon(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline),
            onSelected: (value) {
              if (value == 'orders') {
                Navigator.pushNamed(context, AppRoutes.orderHistory);
              } else if (value == 'logout') {
                authProvider.logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'user',
                enabled: false,
                child: Text(
                  authProvider.currentUser?.name ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Mis Pedidos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Selector de categorías
            if (productProvider.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              CategorySelector(
                categories: productProvider.categories,
                selectedCategoryId: productProvider.selectedCategoryId,
                onSelected: (id) => productProvider.filterByCategory(id),
              ),
              const SizedBox(height: 8),
            ],
            // Contenido principal
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => productProvider.loadProducts(
                  categoryId: productProvider.selectedCategoryId,
                ),
                child: _buildBody(productProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ProductProvider provider) {
    if (provider.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: LoadingIndicator(message: 'Cargando productos...'),
          ),
        ],
      );
    }

    if (provider.status == ViewStatus.error) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 400,
            child: ErrorView(
              message:
                  provider.errorMessage ??
                  'Ocurrió un error al cargar los productos.',
              onRetry: () => provider.loadProducts(
                categoryId: provider.selectedCategoryId,
              ),
            ),
          ),
        ],
      );
    }

    if (provider.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: EmptyView(
              message: 'No hay productos disponibles en esta categoría.',
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.70,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final product = provider.products[index];
        return ProductCard(
          product: product,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.productDetail,
            arguments: product,
          ),
        );
      },
    );
  }
}
