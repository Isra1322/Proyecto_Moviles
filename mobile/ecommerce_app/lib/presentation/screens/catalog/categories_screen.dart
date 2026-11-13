import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/domain/entities/category.dart';
import '../../providers/product_provider.dart';
import '../../widgets/cart/cart_badge_icon.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_view.dart';
import '../../routes/app_routes.dart';

class CategoriesScreen extends StatefulWidget {
  final void Function(int? categoryId)? onCategorySelected;

  const CategoriesScreen({super.key, this.onCategorySelected});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.categories.isEmpty) {
        provider.loadCategories();
      }
      if (provider.allProducts.isEmpty) {
        provider.loadProducts();
      }
    });
  }

  void _handleSelectCategory(int? categoryId) {
    final provider = context.read<ProductProvider>();
    provider.filterByCategory(categoryId);

    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(categoryId);
    } else {
      // Si se abrió de forma independiente, navegar al catálogo
      Navigator.pushNamed(context, AppRoutes.catalog);
    }
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ropa') || lower.contains('vest') || lower.contains('camisa')) {
      return Icons.checkroom;
    } else if (lower.contains('electr') || lower.contains('celul') || lower.contains('comp')) {
      return Icons.devices;
    } else if (lower.contains('hogar') || lower.contains('mueble') || lower.contains('casa')) {
      return Icons.chair_outlined;
    } else if (lower.contains('alimento') || lower.contains('comida') || lower.contains('bebida')) {
      return Icons.restaurant;
    } else if (lower.contains('deporte') || lower.contains('fitness')) {
      return Icons.fitness_center;
    } else if (lower.contains('libro') || lower.contains('papel')) {
      return Icons.menu_book;
    } else if (lower.contains('salud') || lower.contains('belleza')) {
      return Icons.spa_outlined;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categories = productProvider.categories;
    final totalProducts = productProvider.allProducts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          CartBadgeIcon(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await productProvider.loadCategories();
            await productProvider.loadProducts();
          },
          child: categories.isEmpty && productProvider.isLoading
              ? const LoadingIndicator(message: 'Cargando categorías...')
              : categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EmptyView(
                            message: 'No se encontraron categorías disponibles.',
                            icon: Icons.category_outlined,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => productProvider.loadCategories(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Tarjeta para "Todas las categorías"
                        _buildAllCategoriesCard(
                          totalProducts: totalProducts,
                          isSelected: productProvider.selectedCategoryId == null,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Explora por Categoría',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Grid de Categorías
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.15,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final count = productProvider.allProducts
                                .where((p) => p.categoryId == cat.id)
                                .length;
                            final isSelected =
                                productProvider.selectedCategoryId == cat.id;

                            return _buildCategoryItemCard(
                              category: cat,
                              productCount: count,
                              isSelected: isSelected,
                            );
                          },
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildAllCategoriesCard({
    required int totalProducts,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleSelectCategory(null),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Todas las Categorías',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalProducts productos disponibles',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItemCard({
    required Category category,
    required int productCount,
    required bool isSelected,
  }) {
    final icon = _getCategoryIcon(category.name);

    return Card(
      elevation: isSelected ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _handleSelectCategory(category.id),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withAlpha(35)
                      : AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                productCount > 0
                    ? '$productCount producto(s)'
                    : 'Ver productos',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
