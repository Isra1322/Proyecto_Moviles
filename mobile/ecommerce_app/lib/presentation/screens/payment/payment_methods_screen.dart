import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/infrastructure/models/payment_method_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payment_provider.dart';
import '../../widgets/payment/add_card_modal.dart';
import '../../widgets/common/empty_view.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_view.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<AuthProvider>().isAuthenticated) {
        context.read<PaymentProvider>().loadPaymentMethods();
      }
    });
  }

  Future<void> _confirmDelete(BuildContext context, PaymentMethodModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Tarjeta'),
        content: Text('¿Deseas eliminar la tarjeta ${card.maskedCardNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final scaffoldMessenger = ScaffoldMessenger.of(this.context);
      final success = await this.context.read<PaymentProvider>().deletePaymentMethod(card.id);
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Tarjeta eliminada exitosamente.'
                : 'No se pudo eliminar la tarjeta.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final cards = paymentProvider.paymentMethods;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Métodos de Pago'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text(
          'Nueva Tarjeta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => AddCardModal.show(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<PaymentProvider>().loadPaymentMethods(),
          child: _buildBody(context, paymentProvider, cards),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PaymentProvider provider,
    List<PaymentMethodModel> cards,
  ) {
    if (provider.isLoading && cards.isEmpty) {
      return const LoadingIndicator(message: 'Cargando métodos de pago...');
    }

    if (provider.status == ViewStatus.error && cards.isEmpty) {
      return ErrorView(
        message: provider.errorMessage ?? 'Ocurrió un error al cargar las tarjetas.',
        onRetry: () => provider.loadPaymentMethods(),
      );
    }

    if (cards.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          const EmptyView(
            message: 'No tienes métodos de pago guardados.\nAgrega una tarjeta para tus compras.',
            icon: Icons.credit_card_off_outlined,
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => AddCardModal.show(context),
              icon: const Icon(Icons.add_card_rounded, size: 20),
              label: const Text(
                'Agregar Tarjeta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _buildCardItem(context, card);
      },
    );
  }

  Widget _buildCardItem(BuildContext context, PaymentMethodModel card) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: card.isDefault
            ? const BorderSide(color: AppColors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildCardBadge(card.cardType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.maskedCardNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (card.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Predeterminada',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.cardHolderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 22,
                  ),
                  tooltip: 'Eliminar Tarjeta',
                  onPressed: () => _confirmDelete(context, card),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vence: ${card.expiryDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  card.cardType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
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
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: bg.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
