import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import 'add_card_modal.dart';

class SelectCardModal extends StatelessWidget {
  const SelectCardModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SelectCardModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final cards = paymentProvider.paymentMethods;
    final selectedId = paymentProvider.selectedMethod?.id;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Seleccionar Método de Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'No tienes tarjetas registradas aún.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ] else ...[
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cards.length,
                  separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final card = cards[index];
                    final isSelected = card.id == selectedId;

                    return Material(
                      color: isSelected
                          ? AppColors.primary.withAlpha(15)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: _buildCardIcon(card.cardType),
                          title: Text(
                            card.maskedCardNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            '${card.cardHolderName} • Exp: ${card.expiryDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 24,
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked,
                                  color: Colors.grey,
                                  size: 24,
                                ),
                          onTap: () {
                            paymentProvider.selectMethod(card);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () {
                Navigator.pop(context);
                AddCardModal.show(context);
              },
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text(
                'Agregar otra tarjeta',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCardIcon(String cardType) {
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
      width: 44,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
