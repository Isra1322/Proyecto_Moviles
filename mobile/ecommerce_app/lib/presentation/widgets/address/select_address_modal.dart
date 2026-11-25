import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import '../../providers/address_provider.dart';
import 'add_edit_address_modal.dart';

class SelectAddressModal extends StatelessWidget {
  const SelectAddressModal({super.key});

  static Future<AddressModel?> show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SelectAddressModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addressProvider = context.watch<AddressProvider>();
    final addresses = addressProvider.addresses;
    final selectedId = addressProvider.selectedAddress?.id;

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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF2196F3),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Dirección de Entrega',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
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
            if (addresses.isEmpty) ...[
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
                    'No tienes direcciones de entrega guardadas.',
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
                  itemCount: addresses.length,
                  separatorBuilder: (ctx, index) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final address = addresses[index];
                    final isSelected = address.id == selectedId;

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

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        context.read<AddressProvider>().selectAddress(address);
                        Navigator.pop(context, address);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cardBorderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? const Color(0xFF2196F3)
                                  : (isDark
                                      ? Colors.white38
                                      : AppColors.textSecondary),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (address.isDefault) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2196F3)
                                                .withAlpha(isDark ? 40 : 25),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Predeterminada',
                                            style: TextStyle(
                                              color: isDark
                                                  ? const Color(0xFF90CAF9)
                                                  : AppColors.primaryDark,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    address.street,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? const Color(0xFFB0B0B0)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${address.city}${address.stateOrProvince.isNotEmpty ? ", ${address.stateOrProvince}" : ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFFB0B0B0)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (address.reference != null &&
                                      address.reference!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ref: ${address.reference}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: isDark
                                            ? const Color(0xFFB0B0B0)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tel: ${address.phone}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? const Color(0xFFB0B0B0)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF2196F3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final newAddr = await AddEditAddressModal.show(context);
                  if (newAddr != null && context.mounted) {
                    Navigator.pop(context, newAddr);
                  }
                },
                icon: const Icon(
                  Icons.add_location_alt_outlined,
                  size: 18,
                  color: Color(0xFF2196F3),
                ),
                label: const Text(
                  '+ Agregar nueva dirección',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
