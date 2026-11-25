import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';

import '../../../domain/entities/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/address_provider.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/auth_guard_dialog.dart';
import '../../widgets/payment/add_card_modal.dart';
import '../../widgets/payment/select_card_modal.dart';
import '../../widgets/address/add_edit_address_modal.dart';
import '../../widgets/address/select_address_modal.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<PaymentProvider>().loadPaymentMethods();
        try {
          context.read<AddressProvider>().loadAddresses();
        } catch (_) {}
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final payment = context.read<PaymentProvider>();

    if (auth.isAuthenticated) {
      if (payment.status == ViewStatus.initial && !payment.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            payment.loadPaymentMethods();
          }
        });
      }
      try {
        final address = context.read<AddressProvider>();
        if (address.status == ViewStatus.initial && !address.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              address.loadAddresses();
            }
          });
        }
      } catch (_) {}
    }
  }

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
      final didLogin = await promptLoginGuard(context);
      if (!didLogin || !context.mounted) return;
      await context.read<PaymentProvider>().loadPaymentMethods();
      if (!context.mounted) return;
      try {
        await context.read<AddressProvider>().loadAddresses();
      } catch (_) {}
      if (!context.mounted) return;
    }

    final paymentProvider = context.read<PaymentProvider>();
    final selectedPayment = paymentProvider.selectedMethod;
    if (selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona o agrega un método de pago antes de continuar.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    AddressProvider? addressProvider;
    try {
      addressProvider = context.read<AddressProvider>();
    } catch (_) {}

    final selectedAddress = addressProvider?.selectedAddress;
    if (addressProvider != null && selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona o agrega una dirección de entrega antes de continuar.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final order = await orderProvider.createOrder(
      customerId: authProvider.currentUser!.customerId,
      cart: cartProvider.cart,
      customerName: authProvider.currentUser?.name,
      customerEmail: authProvider.currentUser?.username,
      paymentMethodId: selectedPayment.id,
      paymentReference:
          'Pago con ${selectedPayment.cardType} terminada en ${selectedPayment.maskedCardNumber.substring(selectedPayment.maskedCardNumber.length - 4)}',
      shippingAddressId: selectedAddress?.id,
      shippingAddressText: selectedAddress?.fullSummary,
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
    final authProvider = context.watch<AuthProvider>();
    final paymentProvider = context.watch<PaymentProvider>();
    AddressProvider? addressProvider;
    try {
      addressProvider = context.watch<AddressProvider>();
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasQuantityError = cartProvider.cart.items.any(
      (item) => _quantityError(item) != null,
    );
    final isAuth = authProvider.isAuthenticated;
    final hasMissingPayment = isAuth && paymentProvider.selectedMethod == null;
    final hasMissingAddress = isAuth && addressProvider != null && addressProvider.selectedAddress == null;
    final canConfirm = !hasQuantityError && (!isAuth || (!hasMissingPayment && !hasMissingAddress));

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
              child: Text(
                'Vaciar',
                style: TextStyle(color: isDark ? Colors.white : AppColors.primary),
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
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).cardColor : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withAlpha(50)
                              : const Color(0x1A000000),
                          blurRadius: 12,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal:',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.subtotal,
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'IVA (15%):',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.iva15,
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(
                            height: 1,
                            color: isDark ? const Color(0xFF2A2A2A) : null,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total a Pagar:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                cartProvider.totalConIva,
                              ),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '* Incluye IVA oficial del 15% según especificaciones técnicas de integración.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Paso 2: Método de Pago
                        _buildPaymentSection(
                            context, authProvider, paymentProvider),
                        if (addressProvider != null) ...[
                          const SizedBox(height: 12),
                          // Paso 3: Dirección de Entrega
                          _buildAddressSection(
                              context, authProvider, addressProvider),
                        ],
                        const SizedBox(height: 16),
                        if (hasQuantityError) ...[
                          const Text(
                            'Corrige las cantidades para continuar con el pedido.',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else if (hasMissingPayment) ...[
                          const Text(
                            'Selecciona o agrega un método de pago para continuar.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else if (hasMissingAddress) ...[
                          const Text(
                            'Selecciona o agrega una dirección de entrega para continuar.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        CustomButton(
                          label: 'Confirmar Pedido',
                          onPressed: canConfirm ? () => _confirmOrder(context) : null,
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

  Widget _buildPaymentSection(
    BuildContext context,
    AuthProvider authProvider,
    PaymentProvider paymentProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = paymentProvider.selectedMethod;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, size: 18, color: Color(0xFF2196F3)),
                  const SizedBox(width: 6),
                  Text(
                    'Método de Pago',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (selected != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                  onPressed: () => SelectCardModal.show(context),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (selected != null) ...[
            Row(
              children: [
                _buildCardBadge(selected.cardType),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.maskedCardNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? const Color(0xFFB0B0B0) : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${selected.cardHolderName} • Exp: ${selected.expiryDate}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 20, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No tienes tarjetas registradas para pagar.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () async {
                  if (!authProvider.isAuthenticated) {
                    final didLogin = await promptLoginGuard(context);
                    if (!didLogin || !context.mounted) return;
                    await context.read<PaymentProvider>().loadPaymentMethods();
                    return;
                  }
                  AddCardModal.show(context);
                },
                icon: const Icon(Icons.add_card,
                    size: 16, color: Color(0xFF2196F3)),
                label: const Text(
                  'Agregar tarjeta para pagar',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressSection(
    BuildContext context,
    AuthProvider authProvider,
    AddressProvider addressProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = addressProvider.selectedAddress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, size: 18, color: Color(0xFF2196F3)),
                  const SizedBox(width: 6),
                  Text(
                    'Dirección de Entrega',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (selected != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF2196F3),
                  ),
                  onPressed: () => SelectAddressModal.show(context),
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (selected != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home_outlined,
                    size: 20,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              selected.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selected.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withAlpha(isDark ? 40 : 20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Predeterminada',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected.street,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFB0B0B0) : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${selected.city}${selected.stateOrProvince.isNotEmpty ? ", ${selected.stateOrProvince}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                        ),
                      ),
                      if (selected.reference != null && selected.reference!.isNotEmpty)
                        Text(
                          'Ref: ${selected.reference}',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No tienes una dirección de entrega configurada',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () async {
                  if (!authProvider.isAuthenticated) {
                    final didLogin = await promptLoginGuard(context);
                    if (!didLogin || !context.mounted) return;
                    await Future.wait([
                      context.read<PaymentProvider>().loadPaymentMethods(),
                      context.read<AddressProvider>().loadAddresses(),
                    ]);
                    return;
                  }
                  AddEditAddressModal.show(context);
                },
                icon: const Icon(Icons.add_location_alt_outlined,
                    size: 16, color: Color(0xFF2196F3)),
                label: const Text(
                  'Agregar Dirección de Entrega',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardBadge(String cardType) {
    Color bg = AppColors.primary;
    String label = 'CARD';
    if (cardType == 'Visa') {
      bg = const Color(0xFF1A1F71);
      label = 'VISA';
    } else if (cardType == 'MasterCard') {
      bg = const Color(0xFFEB001B);
      label = 'MC';
    } else if (cardType == 'American Express') {
      bg = const Color(0xFF007BC1);
      label = 'AMEX';
    }

    return Container(
      width: 40,
      height: 26,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
