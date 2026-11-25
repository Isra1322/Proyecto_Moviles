import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import 'add_card_modal.dart';

class SelectCardModal extends StatelessWidget {
  const SelectCardModal({super.key});

  static Future<void> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SelectCardModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentProvider = context.watch<PaymentProvider>();
    final cards = paymentProvider.paymentMethods;
    final selectedId = paymentProvider.selectedMethod?.id;

    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : Theme.of(context).colorScheme.surface;

    return Material(
      color: surfaceColor,
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
                Text(
                  'Seleccionar Método de Pago',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cards.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252525)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'No tienes tarjetas registradas aún.',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white70
                          : AppColors.textSecondary,
                    ),
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

                    final cardBg = isSelected
                        ? (isDark
                            ? const Color(0xFF2196F3).withAlpha(35)
                            : AppColors.primary.withAlpha(15))
                        : (isDark ? const Color(0xFF252525) : Colors.white);

                    final cardBorderColor = isSelected
                        ? const Color(0xFF2196F3)
                        : (isDark
                            ? const Color(0xFF3A3A3A)
                            : Colors.grey.shade300);

                    return Material(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cardBorderColor,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${card.cardHolderName} • Exp: ${card.expiryDate}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFFB0B0B0)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF2196F3),
                                  size: 24,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey,
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
                  side: const BorderSide(color: Color(0xFF2196F3)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  AddCardModal.show(context);
                },
                icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
                label: const Text(
                  'Agregar otra tarjeta',
                  style: TextStyle(
                    color: Color(0xFF2196F3),
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
