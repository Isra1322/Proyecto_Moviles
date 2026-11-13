import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';

import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/product/product_card.dart';
import '../../widgets/cart/cart_badge_icon.dart';
import '../../routes/app_routes.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback? onNavigateToCategories;

  const CatalogScreen({super.key, this.onNavigateToCategories});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getSortLabel(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.nameAsc:
        return 'A - Z';
      case ProductSortOption.nameDesc:
        return 'Z - A';
      case ProductSortOption.priceAsc:
        return 'Precio: Menor';
      case ProductSortOption.priceDesc:
        return 'Precio: Mayor';
      case ProductSortOption.none:
        return 'Ordenar por';
    }
  }

  void _showPriceFilterSheet(BuildContext context, ProductProvider provider) {
    final double minBound = (provider.minAvailablePrice).floorToDouble();
    final double maxBound = (provider.maxAvailablePrice > provider.minAvailablePrice
            ? provider.maxAvailablePrice
            : provider.minAvailablePrice + 10.0)
        .ceilToDouble();

    double currentMin = provider.minPrice ?? minBound;
    double currentMax = provider.maxPrice ?? maxBound;
    if (currentMin < minBound) currentMin = minBound;
    if (currentMax > maxBound) currentMax = maxBound;
    if (currentMin > currentMax) currentMin = minBound;

    RangeValues selectedRange = RangeValues(currentMin, currentMax);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar por Rango de Precios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mínimo: ${CurrencyFormatter.format(selectedRange.start)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      Text(
                        'Máximo: ${CurrencyFormatter.format(selectedRange.end)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: selectedRange,
                    min: minBound,
                    max: maxBound,
                    divisions: (maxBound - minBound) > 0
                        ? (maxBound - minBound).round().clamp(5, 100)
                        : 1,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.border,
                    labels: RangeLabels(
                      CurrencyFormatter.format(selectedRange.start),
                      CurrencyFormatter.format(selectedRange.end),
                    ),
                    onChanged: (RangeValues newValues) {
                      setSheetState(() {
                        selectedRange = newValues;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.resetPriceRange();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Limpiar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            provider.setPriceRange(
                              selectedRange.start,
                              selectedRange.end,
                            );
                            Navigator.pop(ctx);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortSheet(BuildContext context, ProductProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Ordenar Productos Por',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              _buildSortTile(
                ctx,
                provider,
                title: 'Por defecto (Sin ordenar)',
                option: ProductSortOption.none,
                icon: Icons.refresh,
              ),
              _buildSortTile(
                ctx,
                provider,
                title: 'Alfabético (A - Z)',
                option: ProductSortOption.nameAsc,
                icon: Icons.sort_by_alpha,
              ),
              _buildSortTile(
                ctx,
                provider,
                title: 'Alfabético (Z - A)',
                option: ProductSortOption.nameDesc,
                icon: Icons.sort_by_alpha,
              ),
              _buildSortTile(
                ctx,
                provider,
                title: 'Precio: Menor a Mayor',
                option: ProductSortOption.priceAsc,
                icon: Icons.arrow_upward,
              ),
              _buildSortTile(
                ctx,
                provider,
                title: 'Precio: Mayor a Menor',
                option: ProductSortOption.priceDesc,
                icon: Icons.arrow_downward,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortTile(
    BuildContext context,
    ProductProvider provider, {
    required String title,
    required ProductSortOption option,
    required IconData icon,
  }) {
    final isSelected = provider.sortOption == option;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        provider.setSortOption(option);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descubre Productos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              productProvider.selectedCategoryId != null
                  ? 'Filtrado por categoría'
                  : 'Encuentra las mejores ofertas para ti',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CartBadgeIcon(
              onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Buscador en tiempo real con diseño limpio y sombra suave
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => productProvider.setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o descripción...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              productProvider.clearSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Fila uniforme de dos botones de acción rápida ("Precio" y "Ordenar por")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Botón Rango de Precios
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: productProvider.hasPriceFilter
                              ? AppColors.primary.withAlpha(20)
                              : Colors.white,
                          side: BorderSide(
                            color: productProvider.hasPriceFilter
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _showPriceFilterSheet(context, productProvider),
                        icon: Icon(
                          Icons.tune,
                          size: 18,
                          color: productProvider.hasPriceFilter
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        label: Text(
                          productProvider.hasPriceFilter
                              ? '\$${productProvider.minPrice?.toStringAsFixed(0)} - \$${productProvider.maxPrice?.toStringAsFixed(0)}'
                              : 'Precio',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: productProvider.hasPriceFilter
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Botón Ordenar por
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: productProvider.sortOption !=
                                  ProductSortOption.none
                              ? AppColors.primary.withAlpha(20)
                              : Colors.white,
                          side: BorderSide(
                            color: productProvider.sortOption !=
                                    ProductSortOption.none
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _showSortSheet(context, productProvider),
                        icon: Icon(
                          Icons.swap_vert,
                          size: 18,
                          color: productProvider.sortOption !=
                                  ProductSortOption.none
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        label: Text(
                          _getSortLabel(productProvider.sortOption),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: productProvider.sortOption !=
                                    ProductSortOption.none
                                ? AppColors.primaryDark
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Fila de chips de filtros activos si existen
            if (productProvider.hasActiveFilters) ...[
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Row(
                  children: [
                    const Text(
                      'Filtros:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (productProvider.selectedCategoryId != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  avatar: const Icon(Icons.category,
                                      size: 14, color: AppColors.primary),
                                  label: Text(
                                    productProvider.categories
                                            .where((c) =>
                                                c.id ==
                                                productProvider
                                                    .selectedCategoryId)
                                            .firstOrNull
                                            ?.name ??
                                        'Categoría',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  deleteIcon:
                                      const Icon(Icons.close, size: 14),
                                  onDeleted: () =>
                                      productProvider.filterByCategory(null),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                            if (productProvider.searchQuery.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    '"${productProvider.searchQuery}"',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () {
                                    _searchController.clear();
                                    productProvider.clearSearch();
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (productProvider.hasPriceFilter)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    '${CurrencyFormatter.format(productProvider.minPrice ?? 0)} - ${CurrencyFormatter.format(productProvider.maxPrice ?? 0)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () =>
                                      productProvider.resetPriceRange(),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            if (productProvider.sortOption !=
                                ProductSortOption.none)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  label: Text(
                                    _getSortLabel(productProvider.sortOption),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  deleteIcon: const Icon(Icons.close, size: 14),
                                  onDeleted: () => productProvider
                                      .setSortOption(ProductSortOption.none),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ActionChip(
                              label: const Text(
                                'Limpiar todo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                productProvider.clearFilters();
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 6),

            // 4. Contenido principal con Grid de productos ocupando todo el espacio libre
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
              message: provider.errorMessage ??
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
        children: [
          SizedBox(
            height: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EmptyView(
                  message: provider.hasActiveFilters
                      ? 'No hay productos que coincidan con los filtros aplicados.'
                      : 'No hay productos disponibles en esta categoría.',
                  icon: Icons.inventory_2_outlined,
                ),
                if (provider.hasActiveFilters) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Limpiar filtros'),
                  ),
                ],
              ],
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
