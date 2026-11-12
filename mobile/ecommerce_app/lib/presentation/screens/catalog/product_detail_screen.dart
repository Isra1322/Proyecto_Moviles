import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/core/utils/quantity_input_formatter.dart';
import 'package:ecommerce_app/domain/entities/product.dart';

import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/cart/cart_badge_icon.dart';
import '../../routes/app_routes.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _quantityController = TextEditingController(text: '1');
  late final FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _quantityFocusNode = FocusNode()..addListener(_handleQuantityFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialProduct != null) {
        context.read<ProductProvider>().selectProduct(widget.initialProduct!);
      }
      context.read<ProductProvider>().loadProductDetail(widget.productId);
    });
  }

  void _handleQuantityFocus() {
    if (!_quantityFocusNode.hasFocus) {
      _ensureValidQuantity();
    }
  }

  void _ensureValidQuantity() {
    final text = _quantityController.text;
    final product = context.read<ProductProvider>().selectedProduct;
    final availableStock = product != null ? _availableStock(product) : 1;
    int qty = int.tryParse(text) ?? 0;
    if (text.isEmpty || qty <= 0) {
      _quantityController.text = '1';
      _quantityController.selection = const TextSelection.collapsed(offset: 1);
      setState(() {});
    } else if (availableStock > 0 && qty > availableStock) {
      _quantityController.text = '$availableStock';
      _quantityController.selection = TextSelection.collapsed(
        offset: _quantityController.text.length,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _quantityFocusNode
      ..removeListener(_handleQuantityFocus)
      ..dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    final product = context.read<ProductProvider>().selectedProduct;
    if (product == null) return;

    final quantity = int.tryParse(_quantityController.text);
    final availableStock = _availableStock(product);
    if (quantity == null || quantity <= 0 || quantity > availableStock) {
      setState(() {});
      return;
    }

    final error = await context.read<CartProvider>().addToCart(
      product,
      quantity: quantity,
    );

    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto agregado al carrito'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  int _availableStock(Product product) {
    final cart = context.read<CartProvider>().cart;
    final currentQuantity = cart.items
        .where((item) => item.product.id == product.id)
        .fold(0, (total, item) => total + item.quantity);
    return (product.stock - currentQuantity).floor();
  }

  String? _validateQuantity(Product product) {
    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      return 'Ingresa una cantidad mayor que 0';
    }
    final availableStock = _availableStock(product);
    if (quantity > availableStock) {
      return 'Solo hay $availableStock unidades disponibles';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        actions: [
          CartBadgeIcon(
            onTap: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(ProductProvider provider) {
    if (provider.detailStatus == ViewStatus.loading) {
      return const LoadingIndicator(message: 'Cargando producto...');
    }

    if (provider.detailStatus == ViewStatus.error) {
      return ErrorView(
        message: provider.errorMessage ?? 'No se pudo cargar el producto.',
        onRetry: () => provider.loadProductDetail(widget.productId),
      );
    }

    final product = provider.selectedProduct;
    if (product == null) {
      return const ErrorView(message: 'Producto no encontrado.');
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          SizedBox(
            height: 280,
            width: double.infinity,
            child: _buildProductImage(product.imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Precio
                Text(
                  CurrencyFormatter.format(product.price),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Stock
                Row(
                  children: [
                    Icon(
                      product.isInStock
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: product.isInStock
                          ? AppColors.success
                          : AppColors.error,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.isInStock
                          ? 'En stock: ${product.stock.toStringAsFixed(0)} unidades'
                          : 'Sin stock disponible',
                      style: TextStyle(
                        color: product.isInStock
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (product.categoryName != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(product.categoryName!),
                    backgroundColor: AppColors.primary.withAlpha(20),
                    labelStyle: const TextStyle(color: AppColors.primary),
                  ),
                ],
                if (product.description != null &&
                    product.description!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Cantidad:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: _quantityController,
                        focusNode: _quantityFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          QuantityInputFormatter(
                            maxStock: _availableStock(product),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            var cleaned = value.replaceFirst(RegExp(r'^0+'), '');
                            if (cleaned.isEmpty) {
                              _quantityController.text = '';
                              setState(() {});
                              return;
                            }
                            final availableStock = _availableStock(product);
                            final parsed = int.tryParse(cleaned);
                            if (parsed != null && availableStock > 0 && parsed > availableStock) {
                              _quantityController.text = '$availableStock';
                              _quantityController.selection = TextSelection.collapsed(
                                offset: _quantityController.text.length,
                              );
                            } else if (cleaned != value) {
                              _quantityController.text = cleaned;
                              _quantityController.selection = TextSelection.collapsed(
                                offset: cleaned.length,
                              );
                            }
                          }
                          setState(() {});
                        },
                        onEditingComplete: () {
                          _ensureValidQuantity();
                          _quantityFocusNode.unfocus();
                        },
                        onSubmitted: (_) {
                          _ensureValidQuantity();
                          _quantityFocusNode.unfocus();
                        },
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          errorText: _validateQuantity(product),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Botón agregar al carrito
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        product.isInStock && _validateQuantity(product) == null
                        ? _addToCart
                        : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      product.isInStock ? 'Agregar al Carrito' : 'Sin Stock',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    try {
      final base64String = imageUrl.contains(',')
          ? imageUrl.split(',').last
          : imageUrl;
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
      if (cleanBase64.isEmpty) {
        return _placeholder();
      }
      final bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: AppColors.border),
      ),
    );
  }
}
