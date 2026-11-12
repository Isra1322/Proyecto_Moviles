import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';

import '../../../domain/entities/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/cart/cart_item_tile.dart';
import '../../routes/app_routes.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Map<int, String> _quantityDrafts = {};
  final Map<int, String> _quantitySaveErrors = {};
  final Map<int, Future<void>> _pendingQuantitySaves = {};

  String? _quantityError(CartItem item) {
    final productId = item.product.id;
    final rawQuantity = _quantityDrafts[productId] ?? '${item.quantity}';
    final quantity = int.tryParse(rawQuantity);
    if (quantity == null || quantity <= 0) {
      return 'Ingresa una cantidad mayor que 0';
    }

    final availableStock = item.product.stock.floor();
    if (quantity > availableStock) {
      return 'Solo hay $availableStock unidades disponibles';
    }

    return _quantitySaveErrors[productId];
  }

  void _onQuantityChanged(int productId, String value) {
    String sanitized = value;
    if (sanitized.isNotEmpty) {
      sanitized = sanitized.replaceFirst(RegExp(r'^0+'), '');
    }
    setState(() {
      _quantityDrafts[productId] = sanitized;
      _quantitySaveErrors.remove(productId);
    });
  }

  int? _savedQuantity(int productId) {
    for (final item in context.read<CartProvider>().cart.items) {
      if (item.product.id == productId) return item.quantity;
    }
    return null;
  }

  void _clearQuantityDraft(int productId) {
    if (!mounted) return;
    setState(() {
      _quantityDrafts.remove(productId);
      _quantitySaveErrors.remove(productId);
    });
  }

  void _clearAllQuantityDrafts() {
    if (!mounted) return;
    setState(() {
      _quantityDrafts.clear();
      _quantitySaveErrors.clear();
    });
  }

  Future<void> _commitQuantity(CartItem item, String rawQuantity) {
    final productId = item.product.id;
    final pendingSave = _pendingQuantitySaves[productId];
    if (pendingSave != null) return pendingSave;

    final availableStock = item.product.stock.floor();
    int quantity = int.tryParse(rawQuantity) ?? 1;
    if (quantity <= 0) quantity = 1;
    if (availableStock > 0 && quantity > availableStock) {
      quantity = availableStock;
    }

    if (quantity == item.quantity) {
      if (mounted) {
        setState(() => _quantityDrafts.remove(productId));
      }
      return Future<void>.value();
    }

    final cartProvider = context.read<CartProvider>();
    final save = Future<void>(() async {
      await cartProvider.updateQuantity(productId, quantity);
      if (!mounted) return;

      int? savedQuantity;
      for (final cartItem in cartProvider.cart.items) {
        if (cartItem.product.id == productId) {
          savedQuantity = cartItem.quantity;
          break;
        }
      }

      setState(() {
        if (savedQuantity == quantity) {
          _quantityDrafts.remove(productId);
          _quantitySaveErrors.remove(productId);
        } else {
          _quantitySaveErrors[productId] =
              'No se pudo actualizar la cantidad. Inténtalo de nuevo.';
        }
      });
    });
    final trackedSave = save.whenComplete(
      () => _pendingQuantitySaves.remove(productId),
    );
    _pendingQuantitySaves[productId] = trackedSave;
    return trackedSave;
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();
    final orderProvider = context.read<OrderProvider>();

    for (final item in List<CartItem>.of(cartProvider.cart.items)) {
      final rawQuantity =
          _quantityDrafts[item.product.id] ?? '${item.quantity}';
      final error = _quantityError(item);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
        return;
      }

      await _commitQuantity(item, rawQuantity);
      if (!context.mounted) return;
      if (_savedQuantity(item.product.id) != int.parse(rawQuantity)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar una cantidad del carrito.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (!authProvider.isAuthenticated) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }

    final order = await orderProvider.createOrder(
      customerId: authProvider.currentUser!.customerId,
      cart: cartProvider.cart,
      customerName: authProvider.currentUser?.name,
    );

    if (order != null && context.mounted) {
      cartProvider.refreshAfterOrder();
      _clearAllQuantityDrafts();
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.orderSuccess,
        (route) => route.settings.name == AppRoutes.catalog,
        arguments: order,
      );
    } else if (context.mounted && orderProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          if (cartProvider.cart.isNotEmpty)
            TextButton(
              onPressed: () async {
                await cartProvider.clearCart();
                if (mounted && cartProvider.cart.isEmpty) {
                  _clearAllQuantityDrafts();
                }
              },
              child: const Text(
                'Vaciar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: cartProvider.cart.isEmpty
            ? const EmptyView(
                message: 'Tu carrito está vacío.\nAgrega productos desde el catálogo.',
                icon: Icons.shopping_cart_outlined,
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProvider.cart.items.length,
                      itemBuilder: (_, index) {
                        final item = cartProvider.cart.items[index];
                        return CartItemTile(
                          key: ValueKey(item.product.id),
                          item: item,
                          quantityError: _quantityError(item),
                          onQuantityChanged: (value) =>
                              _onQuantityChanged(item.product.id, value),
                          onQuantityCommitted: (value) =>
                              _commitQuantity(item, '$value'),
                          onItemRemoved: _clearQuantityDraft,
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.subtotal,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'IVA (15%):',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.iva15,
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total a Pagar:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.totalConIva,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '* Incluye IVA oficial del 15% según especificaciones técnicas de integración.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (cartProvider.cart.items.any(
                          (item) => _quantityError(item) != null,
                        )) ...[
                          const Text(
                            'Corrige las cantidades para continuar con el pedido.',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        CustomButton(
                          label: 'Confirmar Pedido',
                          onPressed:
                              cartProvider.cart.items.any(
                                (item) => _quantityError(item) != null,
                              )
                              ? null
                              : () => _confirmOrder(context),
                          isLoading: orderProvider.isCreating,
                          width: double.infinity,
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
