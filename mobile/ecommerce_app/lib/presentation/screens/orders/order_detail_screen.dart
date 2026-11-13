import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/core/utils/date_formatter.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

/// Línea divisoria punteada estilo comprobante / ticket
class DottedDivider extends StatelessWidget {
  final double height;
  final Color color;
  final double dashWidth;
  final double dashSpace;

  const DottedDivider({
    super.key,
    this.height = 1.2,
    this.color = const Color(0xFFD1D5DB),
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: height,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: color),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order _currentOrder;
  bool _isLoadingDetail = false;

  Order get order => _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _checkAndFetchDetails();
  }

  void _checkAndFetchDetails() {
    // Si los items vienen vacíos o con valores por defecto/stubs
    final bool needsFetch = _currentOrder.items.isEmpty ||
        _currentOrder.items.any((item) =>
            item.unitPrice <= 0 ||
            item.productName.trim() == 'Producto' ||
            item.productName.trim().isEmpty);

    if (needsFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final orderProvider = context.read<OrderProvider?>();
        if (orderProvider != null) {
          setState(() => _isLoadingDetail = true);
          try {
            final freshOrder = await orderProvider.getOrderById(_currentOrder.id);
            if (freshOrder != null && mounted) {
              setState(() {
                _currentOrder = freshOrder;
                _isLoadingDetail = false;
              });
            } else if (mounted) {
              setState(() => _isLoadingDetail = false);
            }
          } catch (_) {
            if (mounted) {
              setState(() => _isLoadingDetail = false);
            }
          }
        }
      });
    }
  }

  Widget _buildStatusStampBadge() {
    final statusLower = order.status.toLowerCase();
    final bool isConfirmed = statusLower == 'confirmado' ||
        statusLower == 'confirmed' ||
        statusLower == 'sale' ||
        statusLower == 'done' ||
        statusLower == 'realizado' ||
        statusLower == '3' ||
        statusLower == '4';

    final Color bgColor = isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1);
    final Color borderColor = isConfirmed ? const Color(0xFFA5D6A7) : const Color(0xFFFFE082);
    final Color textColor = isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFF57F17);
    final IconData icon = isConfirmed ? Icons.verified_rounded : Icons.pending_actions_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 5),
          Text(
            order.displayStatus.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Desglose financiero con IVA estándar del 15%
    final double total = order.totalAmount;
    final double subtotal = total / 1.15;
    final double iva = total - subtotal;

    // Obtener nombre del usuario autenticado si el pedido no lo trae explícito
    final authUser = context.watch<AuthProvider?>()?.currentUser;
    final String clientName = (order.customerName.trim().isNotEmpty && order.customerName.trim() != 'Cliente')
        ? order.customerName.trim()
        : (authUser?.name.trim().isNotEmpty == true
            ? authUser!.name.trim()
            : (authUser?.username.trim().isNotEmpty == true
                ? authUser!.username.trim()
                : 'Cliente Registrado'));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Detalle del Pedido #${order.id}'),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              // Contenedor principal tipo Comprobante / Recibo
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Encabezado del Comprobante
                      _buildReceiptHeader(clientName),

                      // Línea divisoria punteada
                      const DottedDivider(),

                      // 2. Tabla de Items
                      _buildReceiptItemsSection(),

                      // Línea divisoria punteada
                      const DottedDivider(),

                      // 3. Resumen Financiero
                      _buildFinancialSummary(subtotal: subtotal, iva: iva, total: total),

                      const SizedBox(height: 16),
                      // Pie del comprobante
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.receipt_long_rounded,
                              size: 28,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¡Gracias por su compra!',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Comprobante emitido electrónicamente',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptHeader(String clientName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre o Logo de la tienda y Sello de estado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'E-Commerce Móvil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Comprobante de Pedido',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildStatusStampBadge(),
          ],
        ),
        const SizedBox(height: 16),

        // Número de Pedido y Referencia Odoo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pedido #${order.id}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (order.odooOrderId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Referencia Odoo: #${order.odooOrderId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Fecha y Hora formateadas
        Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Fecha: ${DateFormatter.format(order.orderDate)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Nombre del Cliente
        Row(
          children: [
            const Icon(
              Icons.person_outline,
              size: 15,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Cliente: $clientName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptItemsSection() {
    if (_isLoadingDetail) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(height: 8),
              Text(
                'Cargando detalle de productos...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (order.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'No se encontraron líneas de productos registradas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'DETALLE DE PRODUCTOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${order.items.length} ítem(s)',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...order.items.map((item) => _buildReceiptItemRow(item)),
      ],
    );
  }

  Widget _buildReceiptItemRow(OrderItem item) {
    final double qty = item.quantity > 0 ? item.quantity : 1.0;
    final qtyFormatted = qty % 1 == 0
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);

    final String displayName = item.productName.trim().isNotEmpty
        ? item.productName.trim()
        : (item.productId > 0 ? 'Producto #${item.productId}' : 'Producto');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono sutil
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          // Nombre del producto y detalle inferior: [Cantidad] x $[Precio Unitario]
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Detalle en línea inferior: [Cantidad] x $[Precio Unitario]
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      '$qtyFormatted x \$${item.unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'x$qtyFormatted uds',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(item.unitPrice)} c/u',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Subtotal alineado a la derecha en negrita
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary({
    required double subtotal,
    required double iva,
    required double total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RESUMEN FINANCIERO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _buildFinanceRow(
          label: 'Subtotal (sin impuestos)',
          value: CurrencyFormatter.format(subtotal),
        ),
        const SizedBox(height: 8),
        _buildFinanceRow(
          label: 'IVA (15%)',
          value: CurrencyFormatter.format(iva),
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: Colors.grey.shade200,
        ),
        const SizedBox(height: 10),
        _buildFinanceRow(
          label: 'Total Pagado',
          value: CurrencyFormatter.format(total),
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
