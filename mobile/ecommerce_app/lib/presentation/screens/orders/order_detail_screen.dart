import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/core/services/invoice_pdf_service.dart';
import 'package:ecommerce_app/core/utils/currency_formatter.dart';
import 'package:ecommerce_app/core/utils/date_formatter.dart';
import 'package:ecommerce_app/domain/entities/order.dart';
import 'package:ecommerce_app/domain/entities/order_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

/// Línea divisoria punteada estilo comprobante / ticket
class DottedDivider extends StatelessWidget {
  final double height;
  final Color? color;
  final double dashWidth;
  final double dashSpace;

  const DottedDivider({
    super.key,
    this.height = 1.2,
    this.color,
    this.dashWidth = 6.0,
    this.dashSpace = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? (isDark ? Colors.white24 : const Color(0xFFD1D5DB));

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
                  decoration: BoxDecoration(color: effectiveColor),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text('Detalle del Pedido #${order.id}'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Descargar Factura PDF',
            onPressed: () =>
                InvoicePdfService.generateAndDownloadInvoice(context, order),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            children: [
              // Contenedor principal tipo Comprobante / Recibo
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withAlpha(50) : Colors.black.withAlpha(15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Encabezado del Comprobante
                      _buildReceiptHeader(context, clientName),

                      // Línea divisoria punteada
                      const DottedDivider(),

                      // 2. Tabla de Items
                      _buildReceiptItemsSection(context),

                      // Línea divisoria punteada
                      const DottedDivider(),

                      // 3. Resumen Financiero
                      _buildFinancialSummary(
                        context: context,
                        subtotal: subtotal,
                        iva: iva,
                        total: total,
                      ),

                      const SizedBox(height: 16),
                      // Pie del comprobante
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 28,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '¡Gracias por su compra!',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Comprobante emitido electrónicamente',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Botón destacado para descargar la factura en PDF
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
                    elevation: 2,
                  ),
                  onPressed: () =>
                      InvoicePdfService.generateAndDownloadInvoice(context, order),
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      color: Colors.white),
                  label: const Text(
                    'Descargar Factura PDF',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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

  Widget _buildReceiptHeader(BuildContext context, String clientName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre o Logo de la tienda
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withAlpha(isDark ? 40 : 20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF2196F3),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E-Commerce Móvil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Comprobante de Pedido',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Número de Pedido y Referencia Odoo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pedido #${order.id}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (order.odooOrderId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  'Referencia Odoo: #${order.odooOrderId}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Fecha y Hora formateadas
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Fecha: ${DateFormatter.format(order.orderDate)}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Nombre del Cliente
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 15,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Cliente: $clientName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptItemsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingDetail) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'Cargando detalle de productos...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (order.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: Text(
            'No se encontraron líneas de productos registradas.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              fontSize: 13,
            ),
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
            Text(
              'DETALLE DE PRODUCTOS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '${order.items.length} ítem(s)',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...order.items.map((item) => _buildReceiptItemRow(context, item)),
      ],
    );
  }

  Widget _buildReceiptItemRow(BuildContext context, OrderItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: const Color(0xFF2196F3).withAlpha(isDark ? 40 : 15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: Color(0xFF2196F3),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
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
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        'x$qtyFormatted uds',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(item.unitPrice)} c/u',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
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
              Text(
                'Subtotal',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary({
    required BuildContext context,
    required double subtotal,
    required double iva,
    required double total,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESUMEN FINANCIERO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        _buildFinanceRow(
          context: context,
          label: 'Subtotal (sin impuestos)',
          value: CurrencyFormatter.format(subtotal),
        ),
        const SizedBox(height: 8),
        _buildFinanceRow(
          context: context,
          label: 'IVA (15%)',
          value: CurrencyFormatter.format(iva),
        ),
        const SizedBox(height: 10),
        Container(
          height: 1,
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
        ),
        const SizedBox(height: 10),
        _buildFinanceRow(
          context: context,
          label: 'Total Pagado',
          value: CurrencyFormatter.format(total),
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildFinanceRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? (isDark ? Colors.white : AppColors.textPrimary)
                : (isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 20 : 13,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? const Color(0xFF2196F3)
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
