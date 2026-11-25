import 'package:flutter/material.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/services/invoice_pdf_service.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/domain/entities/order.dart';

import '../../routes/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
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
                Text(
                  '¡Pedido Confirmado!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tu pedido #${order.id} fue creado exitosamente en el sistema.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).cardColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A2A2A) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Número de pedido',
                        value: '#${order.id}',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Divider(height: 16, color: isDark ? const Color(0xFF2A2A2A) : null),
                      _InfoRow(
                        label: 'Estado',
                        value: order.displayStatus,
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Divider(height: 16, color: isDark ? const Color(0xFF2A2A2A) : null),
                      _InfoRow(
                        label: 'Total final (con impuestos)',
                        value: CurrencyFormatter.format(order.totalAmount),
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        valueStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.catalog,
                      (_) => false,
                    ),
                    icon: const Icon(Icons.storefront_outlined, color: Colors.white),
                    label: const Text(
                      'Seguir Comprando',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF2196F3),
                      side: BorderSide(
                        color: isDark ? Colors.white54 : const Color(0xFF2196F3),
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => InvoicePdfService.generateAndDownloadInvoice(
                      context,
                      order,
                    ),
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFE53935),
                    ),
                    label: const Text(
                      'Descargar Factura',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF2196F3) : AppColors.primary,
                  ),
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
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ?? const TextStyle(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
