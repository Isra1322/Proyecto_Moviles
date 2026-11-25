import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ecommerce_app/domain/entities/product.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import '../../routes/app_routes.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stockCount = product.stock % 1 == 0
        ? product.stock.toInt().toString()
        : product.stock.toString();

    return GestureDetector(
      onTap: onTap ??
          () => Navigator.pushNamed(
                context,
                AppRoutes.productDetail,
                arguments: product,
              ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del producto
            Expanded(
              child: _buildImage(isDark),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      product.description!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.2,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          CurrencyFormatter.format(product.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? const Color(0x224CAF50)
                              : const Color(0x22E53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.stock > 0
                              ? '$stockCount disp.'
                              : 'Agotado',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: product.stock > 0
                                ? (isDark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF2E7D32))
                                : (isDark
                                    ? const Color(0xFFE57373)
                                    : const Color(0xFFD32F2F)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    final imageUrl = product.imageUrl;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _placeholder(isDark);
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) => _placeholder(isDark),
      );
    }

    try {
      final base64String = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
      if (cleanBase64.isEmpty) return _placeholder(isDark);
      final bytes = base64Decode(cleanBase64);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _placeholder(isDark),
      );
    } catch (_) {
      return _placeholder(isDark);
    }
  }

  Widget _placeholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : AppColors.background,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark ? Colors.white38 : AppColors.border,
        ),
      ),
    );
  }
}

