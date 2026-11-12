import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/domain/entities/cart_item.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/core/utils/quantity_input_formatter.dart';

import '../../providers/cart_provider.dart';

class CartItemTile extends StatefulWidget {
  final CartItem item;
  final String? quantityError;
  final ValueChanged<String> onQuantityChanged;
  final ValueChanged<int> onQuantityCommitted;
  final ValueChanged<int> onItemRemoved;

  const CartItemTile({
    super.key,
    required this.item,
    required this.quantityError,
    required this.onQuantityChanged,
    required this.onQuantityCommitted,
    required this.onItemRemoved,
  });

  @override
  State<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<CartItemTile> {
  late final TextEditingController _quantityController;
  late final FocusNode _quantityFocusNode;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: '${widget.item.quantity}',
    );
    _quantityFocusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant CartItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity) {
      _quantityController.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _quantityFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_quantityFocusNode.hasFocus) {
      _ensureValidQuantityAndCommit();
    }
  }

  void _ensureValidQuantityAndCommit() {
    final text = _quantityController.text;
    final maxStock = widget.item.product.stock.floor();
    int qty = int.tryParse(text) ?? 0;
    if (text.isEmpty || qty <= 0) {
      qty = 1;
      _quantityController.text = '1';
      _quantityController.selection = const TextSelection.collapsed(offset: 1);
      widget.onQuantityChanged('1');
    } else if (maxStock > 0 && qty > maxStock) {
      qty = maxStock;
      _quantityController.text = '$maxStock';
      _quantityController.selection = TextSelection.collapsed(offset: _quantityController.text.length);
      widget.onQuantityChanged('$maxStock');
    }
    widget.onQuantityCommitted(qty);
  }

  Future<void> _confirmRemoval() async {
    final productId = widget.item.product.id;
    final onItemRemoved = widget.onItemRemoved;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto del carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && mounted) {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.removeItem(productId);
      if (!cartProvider.cart.items.any(
        (item) => item.product.id == productId,
      )) {
        onItemRemoved(productId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Imagen miniatura
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 64,
                height: 64,
                child: _buildItemImage(item),
              ),
            ),
            const SizedBox(width: 12),
            // Nombre y precio unitario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(item.unitPrice),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Subtotal: ${CurrencyFormatter.format(item.subtotal)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Cantidad editable
            Column(
              children: [
                SizedBox(
                  width: 76,
                  child: TextField(
                    controller: _quantityController,
                    focusNode: _quantityFocusNode,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      QuantityInputFormatter(
                        maxStock: widget.item.product.stock.floor(),
                      ),
                    ],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        var cleaned = value.replaceFirst(RegExp(r'^0+'), '');
                        if (cleaned.isEmpty) {
                          _quantityController.text = '';
                          widget.onQuantityChanged('');
                          return;
                        }
                        final maxStock = widget.item.product.stock.floor();
                        final parsed = int.tryParse(cleaned);
                        if (parsed != null && maxStock > 0 && parsed > maxStock) {
                          _quantityController.text = '$maxStock';
                          _quantityController.selection = TextSelection.collapsed(
                            offset: _quantityController.text.length,
                          );
                          widget.onQuantityChanged('$maxStock');
                          return;
                        } else if (cleaned != value) {
                          _quantityController.text = cleaned;
                          _quantityController.selection = TextSelection.collapsed(
                            offset: cleaned.length,
                          );
                          widget.onQuantityChanged(cleaned);
                          return;
                        }
                      }
                      widget.onQuantityChanged(value);
                    },
                    onEditingComplete: () {
                      _ensureValidQuantityAndCommit();
                      _quantityFocusNode.unfocus();
                    },
                    onSubmitted: (_) {
                      _ensureValidQuantityAndCommit();
                      _quantityFocusNode.unfocus();
                    },
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      errorText: widget.quantityError,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _confirmRemoval,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(CartItem item) {
    final imageUrl = item.image;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    try {
      final base64String = imageUrl.contains(',')
          ? imageUrl.split(',').last
          : imageUrl;
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
      if (cleanBase64.isEmpty) return _placeholder();
      final bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } catch (_) {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.background,
      child: const Icon(Icons.image_outlined, color: AppColors.border),
    );
  }
}
