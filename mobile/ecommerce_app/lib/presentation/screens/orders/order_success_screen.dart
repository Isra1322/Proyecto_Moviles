import 'package:flutter/material.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/domain/entities/order.dart';

import '../../routes/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 80,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Pedido Confirmado!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu pedido #${order.id} fue creado exitosamente en el sistema.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Número de pedido',
                        value: '#${order.id}',
                      ),
                      const Divider(height: 16),
                      _InfoRow(label: 'Estado', value: order.displayStatus),
                      const Divider(height: 16),
                      _InfoRow(
                        label: 'Total final (con impuestos)',
                        value: CurrencyFormatter.format(order.totalAmount),
                        valueStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.catalog,
                      (_) => false,
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Seguir Comprando'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.orderHistory),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Ver mis Pedidos'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
