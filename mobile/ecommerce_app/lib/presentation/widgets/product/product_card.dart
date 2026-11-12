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
              child: _buildImage(),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(product.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (!product.isInStock)
                    const Text(
                      'Sin stock',
                      style: TextStyle(color: AppColors.error, fontSize: 11),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = product.imageUrl;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return _placeholder();
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    try {
      final base64String = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
      final cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
      if (cleanBase64.isEmpty) return _placeholder();
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
        child: Icon(Icons.image_outlined, size: 48, color: AppColors.border),
      ),
    );
  }
}

