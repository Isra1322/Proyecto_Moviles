import 'dart:typed_data';
import 'package:flutter/material.dart'
    show BuildContext, Colors, ScaffoldMessenger, SnackBar, Text;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/user.dart';
import '../../presentation/providers/address_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/order_provider.dart';
import '../../presentation/providers/payment_provider.dart';

/// Servicio para la generación y descarga de Factura Electrónica Profesional en PDF
class InvoicePdfService {
  /// Genera una clave de acceso numérica simulada de 49 dígitos siguiendo el estándar SRI
  static String generateAccessKey(Order order) {
    final dateStr = DateFormat('ddMMyyyy').format(order.orderDate);
    const docType = '01'; // 01 = Factura
    const ruc = '1790012345001';
    const env = '2'; // 2 = Producción
    const serie = '001001';
    final sequential = order.id.toString().padLeft(9, '0');
    const numericCode = '12345678';
    const emissionType = '1'; // 1 = Normal

    final base48 =
        '$dateStr$docType$ruc$env$serie$sequential$numericCode$emissionType';

    // Algoritmo Módulo 11 oficial para el dígito verificador del SRI
    int sum = 0;
    int factor = 2;
    for (int i = base48.length - 1; i >= 0; i--) {
      sum += int.parse(base48[i]) * factor;
      factor = factor == 7 ? 2 : factor + 1;
    }
    final remainder = sum % 11;
    final checkDigit =
        (remainder == 0) ? 0 : (remainder == 1 ? 1 : 11 - remainder);

    return '$base48$checkDigit';
  }

  /// Construye el documento PDF con diseño tributario corporativo profesional
  static Future<Uint8List> buildInvoicePdf({
    required Order order,
    User? user,
    String? addressSummary,
    String? paymentLabel,
  }) async {
    final pdf = pw.Document();

    // Cálculos financieros precisos (IVA 15% estándar)
    final double total = order.totalAmount;
    double subtotal;
    if (order.items.isNotEmpty) {
      final itemsSum = order.items.fold<double>(0.0, (s, i) => s + i.subtotal);
      if (itemsSum > 0 && (itemsSum * 1.15 - total).abs() < 0.05) {
        subtotal = itemsSum;
      } else {
        subtotal = total / 1.15;
      }
    } else {
      subtotal = total / 1.15;
    }
    final double iva = total - subtotal;

    // Datos del cliente normalizados
    final String clientName = (order.customerName.trim().isNotEmpty &&
            order.customerName.trim() != 'Cliente')
        ? order.customerName.trim()
        : (user?.name.trim().isNotEmpty == true
            ? user!.name.trim()
            : (user?.username.trim().isNotEmpty == true
                ? user!.username.trim()
                : 'CONSUMIDOR FINAL'));

    final String clientEmail = user?.username.trim().isNotEmpty == true
        ? user!.username.trim()
        : 'cliente@ecommercemovil.com.ec';

    final String clientPhone = user?.phone?.trim().isNotEmpty == true
        ? user!.phone!.trim()
        : '0991234567';

    final String clientRuc = (user?.partnerId != null && user!.partnerId! > 0)
        ? '17${user.partnerId.toString().padLeft(8, '0')}001'
        : (order.customerId > 0
            ? '17${order.customerId.toString().padLeft(8, '0')}001'
            : '9999999999999');

    final String deliveryAddress = addressSummary?.trim().isNotEmpty == true
        ? addressSummary!.trim()
        : 'Av. 10 de Agosto y Colón, Quito - Ecuador';

    final String paymentMethod = (paymentLabel?.trim().isNotEmpty == true
            ? paymentLabel!.trim()
            : 'TARJETA DE CRÉDITO / DÉBITO')
        .replaceAll('•', '*');

    final String accessKey = generateAccessKey(order);
    final String formattedDate =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(order.orderDate);
    final String invoiceNumber =
        '001-001-${order.id.toString().padLeft(9, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(
                invoiceNumber: invoiceNumber,
                accessKey: accessKey,
                formattedDate: formattedDate,
              ),
              pw.SizedBox(height: 12),
              _buildCustomerInfo(
                clientName: clientName,
                clientRuc: clientRuc,
                clientEmail: clientEmail,
                clientPhone: clientPhone,
                deliveryAddress: deliveryAddress,
                paymentMethod: paymentMethod,
              ),
              pw.SizedBox(height: 12),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            _buildProductsTable(order.items),
            pw.SizedBox(height: 10),
            _buildTotalsBlock(subtotal: subtotal, iva: iva, total: total),
            pw.SizedBox(height: 14),
          ];
        },
        footer: (pw.Context context) {
          return _buildFooter(accessKey: accessKey, context: context);
        },
      ),
    );

    return pdf.save();
  }

  /// 1. Encabezado / Membrete + Caja de Datos de Factura
  static pw.Widget _buildHeader({
    required String invoiceNumber,
    required String accessKey,
    required String formattedDate,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Membrete de la Empresa
        pw.Expanded(
          flex: 5,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 38,
                    height: 38,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'EM',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'E-COMMERCE MÓVIL S.A.',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'Tienda de Tecnología y Accesorios',
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'RUC: 1790012345001',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.Text(
                'Dirección Matriz: Av. Amazonas y Naciones Unidas, Quito - Ecuador',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
              ),
              pw.Text(
                'Dirección Sucursal: Centro Comercial Quicentro Norte, Local 210',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Contribuyente Especial Resolución Nº: 0042',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
              ),
              pw.Text(
                'OBLIGADO A LLEVAR CONTABILIDAD: SÍ',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.Text(
                'Tel: (02) 299-0000 | Email: facturacion@ecommercemovil.com.ec',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 14),
        // Caja de Factura Electrónica
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.blue800, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'FACTURA ELECTRÓNICA',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Nº:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      invoiceNumber,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.red800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'NÚMERO DE AUTORIZACIÓN / CLAVE DE ACCESO:',
                  style: pw.TextStyle(
                    fontSize: 6.8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  accessKey,
                  style: pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfColors.black,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Text(
                      'AMBIENTE: ',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('PRODUCCIÓN', style: const pw.TextStyle(fontSize: 7)),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'EMISIÓN: ',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('NORMAL', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      'FECHA EMISIÓN: ',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 2. Datos del Cliente / Facturar a
  static pw.Widget _buildCustomerInfo({
    required String clientName,
    required String clientRuc,
    required String clientEmail,
    required String clientPhone,
    required String deliveryAddress,
    required String paymentMethod,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAFAFA'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DATOS DEL CLIENTE / FACTURAR A',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine('Razón Social / Nombres:', clientName),
                    pw.SizedBox(height: 2),
                    _buildInfoLine('Identificación (C.I./RUC):', clientRuc),
                    pw.SizedBox(height: 2),
                    _buildInfoLine('Dirección de Entrega:', deliveryAddress),
                  ],
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                flex: 5,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoLine('Correo Electrónico:', clientEmail),
                    pw.SizedBox(height: 2),
                    _buildInfoLine('Teléfono:', clientPhone),
                    pw.SizedBox(height: 2),
                    _buildInfoLine('Método de Pago:', paymentMethod),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label ',
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey800,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  /// 3. Tabla de Productos Estilizada
  static pw.Widget _buildProductsTable(List<OrderItem> items) {
    if (items.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Center(
          child: pw.Text(
            'Detalle de compra general registrado',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        bottom: const pw.BorderSide(color: PdfColors.grey400, width: 0.8),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.8), // Código
        1: pw.FlexColumnWidth(4.5), // Descripción
        2: pw.FlexColumnWidth(1.2), // Cant.
        3: pw.FlexColumnWidth(2.0), // Precio Unitario
        4: pw.FlexColumnWidth(2.0), // Subtotal
      },
      children: [
        // Encabezado
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue800,
            borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
          ),
          children: [
            _buildTableHeaderCell('Código'),
            _buildTableHeaderCell('Descripción'),
            _buildTableHeaderCell('Cant.', align: pw.TextAlign.right),
            _buildTableHeaderCell('Precio Unit.', align: pw.TextAlign.right),
            _buildTableHeaderCell('Subtotal', align: pw.TextAlign.right),
          ],
        ),
        // Filas de productos
        ...items.asMap().entries.map((entry) {
          final int index = entry.key;
          final OrderItem item = entry.value;
          final bool isEven = index.isEven;
          final rowBg = isEven ? PdfColors.white : PdfColor.fromHex('#F8FAFC');

          final String code = item.productId > 0
              ? 'PRD-${item.productId.toString().padLeft(4, '0')}'
              : 'PRD-0001';

          final qtyFormatted = item.quantity % 1 == 0
              ? item.quantity.toInt().toString()
              : item.quantity.toStringAsFixed(2);

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _buildTableCell(code),
              _buildTableCell(item.productName),
              _buildTableCell(qtyFormatted, align: pw.TextAlign.right),
              _buildTableCell('\$${item.unitPrice.toStringAsFixed(2)}',
                  align: pw.TextAlign.right),
              _buildTableCell(
                '\$${item.subtotal.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.grey900,
        ),
      ),
    );
  }

  /// 4. Bloque de Totales
  static pw.Widget _buildTotalsBlock({
    required double subtotal,
    required double iva,
    required double total,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Información Adicional
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INFORMACIÓN ADICIONAL',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Moneda: DÓLARES AMERICANOS (USD)',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Forma de Pago: Otros con utilización del sistema financiero',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
                pw.Text(
                  'Garantía: 12 meses contra defectos de fábrica',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        // Desglose de Totales alineado a la derecha
        pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow('SUBTOTAL 15%:', '\$${subtotal.toStringAsFixed(2)}'),
              _buildSummaryRow('SUBTOTAL 0%:', '\$0.00'),
              _buildSummaryRow(
                  'SUBTOTAL NO OBJETO DE IVA:', '\$0.00'),
              _buildSummaryRow(
                  'SUBTOTAL EXENTO DE IVA:', '\$0.00'),
              _buildSummaryRow('SUBTOTAL SIN IMPUESTOS:',
                  '\$${subtotal.toStringAsFixed(2)}'),
              _buildSummaryRow('TOTAL DESCUENTO:', '\$0.00'),
              _buildSummaryRow('IVA 15%:', '\$${iva.toStringAsFixed(2)}'),
              pw.Divider(color: PdfColors.grey300, height: 1, thickness: 0.8),
              pw.Container(
                color: PdfColor.fromHex('#EBF5FF'),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'VALOR TOTAL:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10.5,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      '\$${total.toStringAsFixed(2)} USD',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11.5,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Pie de Página con Código QR y Paginación
  static pw.Widget _buildFooter({
    required String accessKey,
    required pw.Context context,
  }) {
    final qrData =
        'https://sri.gob.ec/comprobantes-electronicos?clave=$accessKey';

    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, thickness: 0.8),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 52,
              height: 52,
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Documento tributario electrónico generado de conformidad con la normativa del Servicio de Rentas Internas (SRI).',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'La validez de este comprobante puede ser verificada con la Clave de Acceso en el portal oficial del SRI (www.sri.gob.ec).',
                    style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Comprobante emitido electrónicamente por E-COMMERCE MÓVIL S.A. - Todos los derechos reservados.',
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  /// Descarga / Comparte la Factura en PDF para el Pedido seleccionado
  static Future<void> generateAndDownloadInvoice(
    BuildContext context,
    Order order,
  ) async {
    // 1. Extraer datos del contexto sincrónicamente antes de cualquier operación asíncrona
    final authUser = context.read<AuthProvider?>()?.currentUser;
    final address = context.read<AddressProvider?>()?.selectedAddress;
    final payment = context.read<PaymentProvider?>()?.selectedMethod;
    final orderProvider = context.read<OrderProvider?>();
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      // 2. Obtener detalles completos de la orden si los ítems vienen vacíos
      Order completeOrder = order;
      if (completeOrder.items.isEmpty && orderProvider != null) {
        final fresh = await orderProvider.getOrderById(order.id);
        if (fresh != null) {
          completeOrder = fresh;
        }
      }

      final paymentLabel = payment != null
          ? '${payment.cardType} (${payment.maskedCardNumber})'
          : null;

      // 3. Generar el documento PDF
      final pdfBytes = await buildInvoicePdf(
        order: completeOrder,
        user: authUser,
        addressSummary: address?.fullSummary,
        paymentLabel: paymentLabel,
      );

      // 4. Compartir / Descargar mediante Printing
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Factura_${completeOrder.id}.pdf',
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('No se pudo procesar la factura: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
