import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

class CartBadgeIcon extends StatelessWidget {
  final VoidCallback onTap;

  const CartBadgeIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final totalItems = context.watch<CartProvider>().totalItems;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: onTap,
        ),
        if (totalItems > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$totalItems',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

