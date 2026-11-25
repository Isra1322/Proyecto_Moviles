import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../../core/utils/card_input_formatters.dart';
import '../../providers/payment_provider.dart';

class AddCardModal extends StatefulWidget {
  const AddCardModal({super.key});

  static Future<dynamic> show(BuildContext context) {
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
      builder: (_) => const AddCardModal(),
    );
  }

  @override
  State<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends State<AddCardModal> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isDefault = true;
  bool _isLoading = false;
  String _cardType = 'Tarjeta';

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_updateCardType);
    _holderNameController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_updateCardType);
    _cardNumberController.dispose();
    _holderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _updateCardType() {
    final digits = _cardNumberController.text.replaceAll(' ', '');
    String detected = 'Tarjeta';
    if (digits.startsWith('4')) {
      detected = 'Visa';
    } else if (digits.startsWith(RegExp(r'^(5[1-5]|2[2-7])'))) {
      detected = 'MasterCard';
    } else if (digits.startsWith('34') || digits.startsWith('37')) {
      detected = 'American Express';
    } else if (digits.startsWith('6011') || digits.startsWith('65')) {
      detected = 'Discover';
    }

    if (detected != _cardType) {
      setState(() {
        _cardType = detected;
      });
    } else {
      setState(() {});
    }
  }

  bool _isValidLuhn(String number) {
    if (number.length < 13) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.tryParse(number[i]) ?? 0;
      if (alternate) {
        n *= 2;
        if (n > 9) n = (n % 10) + 1;
      }
      sum += n;
      alternate = !alternate;
    }
    return (sum % 10 == 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final cleanCardNumber = _cardNumberController.text.replaceAll(' ', '');
    final cleanExpiry = _expiryController.text.trim();
    final cleanHolder = _holderNameController.text.trim().toUpperCase();
    final cleanCvv = _cvvController.text.trim();

    final newCard = await context.read<PaymentProvider>().addPaymentMethod(
          cardNumber: cleanCardNumber,
          cardHolderName: cleanHolder,
          expiryDate: cleanExpiry,
          cvv: cleanCvv,
          isDefault: _isDefault,
        );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (newCard != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarjeta guardada exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, newCard);
    } else {
      final error = context.read<PaymentProvider>().errorMessage ??
          'No se pudo registrar la tarjeta.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
    String? counterText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: counterText,
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          fontSize: 13,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon,
                color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.transparent,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.transparent,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: isDark
          ? const Color(0xFF1E1E1E)
          : Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Indicador superior de arrastre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabecera del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nueva Tarjeta',
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

              // Tarjeta visual interactiva con degradado contemporáneo Deep Blue/Indigo
              _buildCardPreview(),
              const SizedBox(height: 20),

              // Input: Número de Tarjeta
              _buildTextField(
                controller: _cardNumberController,
                label: 'Número de Tarjeta',
                hint: '0000 0000 0000 0000',
                prefixIcon: Icons.credit_card,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CardNumberInputFormatter(),
                ],
                validator: (val) {
                  final digits = (val ?? '').replaceAll(' ', '');
                  if (digits.isEmpty) {
                    return 'Ingresa el número de tu tarjeta';
                  }
                  if (digits.length != 16) {
                    return 'El número debe contener 16 dígitos';
                  }
                  if (!_isValidLuhn(digits)) {
                    return 'Número de tarjeta inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Input: Nombre del Titular con límite estricto de 35 caracteres y counterText oculto
              _buildTextField(
                controller: _holderNameController,
                label: 'Nombre del Titular',
                hint: 'Como aparece en la tarjeta',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.characters,
                maxLength: 35,
                counterText: '',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  LengthLimitingTextInputFormatter(35),
                ],
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'Ingresa el nombre completo del titular';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Fila Expiración y CVV con Row simétrico y SizedBox(width: 16)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _expiryController,
                      label: 'Expiración',
                      hint: 'MM/AA',
                      prefixIcon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CardExpiryInputFormatter(),
                      ],
                      validator: (val) {
                        final text = (val ?? '').trim();
                        if (text.isEmpty) return 'Requerido';
                        final parts = text.split('/');
                        if (parts.length != 2) return 'MM/AA inválido';
                        final m = int.tryParse(parts[0]) ?? 0;
                        final y = int.tryParse(parts[1]) ?? 0;
                        if (m < 1 || m > 12) return 'Mes 01-12';
                        final now = DateTime.now();
                        final currentYear = now.year % 100;
                        if (y < currentYear || (y == currentYear && m < now.month)) {
                          return 'Tarjeta expirada';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _cvvController,
                      label: 'CVV',
                      hint: '123',
                      prefixIcon: Icons.lock_outline,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 4,
                      counterText: '',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (val) {
                        final text = (val ?? '').trim();
                        if (text.length < 3) return '3-4 dígitos';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Switch Tarjeta Predeterminada
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: Text(
                  'Tarjeta predeterminada',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Usar automáticamente para futuros pedidos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : AppColors.textSecondary,
                  ),
                ),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 16),

              // Botón Guardar Tarjeta moderno elevado con altura 54 y esquinas redondeadas
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: AppColors.primary.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Guardar Tarjeta',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCardPreview() {
    final digits = _cardNumberController.text.trim();
    final holder = _holderNameController.text.trim().toUpperCase();
    final expiry = _expiryController.text.trim();

    return Container(
      width: double.infinity,
      height: 195,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withAlpha(70),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Chip inteligente y contactless
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.credit_card, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.wifi_rounded, color: Colors.white70, size: 18),
                ],
              ),
              // Logo de franquicia con proporciones elegantes
              _buildBrandBadge(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              digits.isEmpty ? '•••• •••• •••• ••••' : digits,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAR',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holder.isEmpty ? 'NOMBRE DEL TITULAR' : holder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRA',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 9,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry.isEmpty ? 'MM/AA' : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandBadge() {
    if (_cardType == 'Visa') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A1F71),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 1.0,
          ),
        ),
      );
    } else if (_cardType == 'MasterCard') {
      return SizedBox(
        width: 44,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFEB001B),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF79E1B).withAlpha(225),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_cardType == 'American Express') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF007BC1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white54),
        ),
        child: const Text(
          'AMEX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(45),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withAlpha(60)),
        ),
        child: Text(
          _cardType.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
      );
    }
  }
}
