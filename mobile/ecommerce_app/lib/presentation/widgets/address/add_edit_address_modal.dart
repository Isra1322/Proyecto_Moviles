import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import 'package:ecommerce_app/infrastructure/models/address_model.dart';
import '../../providers/address_provider.dart';

class AddEditAddressModal extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressModal({super.key, this.address});

  static Future<AddressModel?> show(BuildContext context, {AddressModel? address}) {
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
      builder: (_) => AddEditAddressModal(address: address),
    );
  }

  @override
  State<AddEditAddressModal> createState() => _AddEditAddressModalState();
}

class _AddEditAddressModalState extends State<AddEditAddressModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalController;
  late final TextEditingController _referenceController;
  late final TextEditingController _phoneController;

  bool _isDefault = false;
  bool _isLoading = false;

  static final TextInputFormatter _titleCaseFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
    String text = newValue.text;
    // 1. No permitir espacios al inicio
    if (text.startsWith(' ')) {
      text = text.replaceFirst(RegExp(r'^\s+'), '');
    }
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 2. Capitalizar primera letra y letras después de cada espacio
    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == ' ') {
        capitalizeNext = true;
        buffer.write(char);
      } else if (capitalizeNext) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }
    }

    final formattedText = buffer.toString();
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(
        offset: newValue.selection.baseOffset.clamp(0, formattedText.length),
      ),
    );
  });

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _titleController = TextEditingController(text: a?.title ?? '');
    _streetController = TextEditingController(text: a?.street ?? '');
    _cityController = TextEditingController(text: a?.city ?? '');
    _stateController = TextEditingController(text: a?.stateOrProvince ?? '');
    _postalController = TextEditingController(text: a?.postalCode ?? '');
    _referenceController = TextEditingController(text: a?.reference ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _isDefault = a?.isDefault ?? false;

    _titleController.addListener(_onFieldChanged);
    _streetController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onFieldChanged);
    _streetController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);

    _titleController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _referenceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final title = _titleController.text.trim();
    final rawStreet = _streetController.text;
    final street = rawStreet.trim();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();

    final isTitleValid = title.length >= 2 && title.length <= 25;
    final isStreetValid = street.length >= 5 &&
        street.length <= 60 &&
        !rawStreet.startsWith(' ') &&
        !RegExp(r'(\s{2,}|([.#\-/])\2+)').hasMatch(rawStreet) &&
        !RegExp(r'^[.#\-/]').hasMatch(street) &&
        !RegExp(r'[.#\-/]$').hasMatch(street);
    final isCityValid = city.length >= 2 && city.length <= 30;
    final isPhoneValid = RegExp(r'^09\d{8}$').hasMatch(phone);

    return isTitleValid && isStreetValid && isCityValid && isPhoneValid;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final title = _titleController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final postal = _postalController.text.trim();
    final ref = _referenceController.text.trim();
    final phone = _phoneController.text.trim();

    final addressProvider = context.read<AddressProvider>();
    AddressModel? result;

    if (_isEditing) {
      result = await addressProvider.updateAddress(
        id: widget.address!.id,
        title: title,
        street: street,
        city: city,
        stateOrProvince: state,
        postalCode: postal.isEmpty ? null : postal,
        reference: ref.isEmpty ? null : ref,
        phone: phone,
        isDefault: _isDefault,
      );
    } else {
      result = await addressProvider.createAddress(
        title: title,
        street: street,
        city: city,
        stateOrProvince: state,
        postalCode: postal.isEmpty ? null : postal,
        reference: ref.isEmpty ? null : ref,
        phone: phone,
        isDefault: _isDefault,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result != null) {
      Navigator.pop(context, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Dirección actualizada exitosamente.'
              : 'Dirección guardada exitosamente.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(addressProvider.errorMessage ??
              'Error al procesar la dirección. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final surfaceColor = isDark
        ? const Color(0xFF1E1E1E)
        : Theme.of(context).colorScheme.surface;
    final fieldFillColor = isDark ? const Color(0xFF2A2A2A) : AppColors.background;
    final fieldBorderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final labelColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
    final iconColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;

    InputDecoration buildInputDecoration({
      required String labelText,
      required String hintText,
      IconData? prefixIcon,
    }) {
      return InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: labelColor),
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: iconColor, size: 20)
            : null,
        filled: true,
        fillColor: fieldFillColor,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
    }

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Barra superior de cierre y título
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Editar Dirección' : 'Nueva Dirección de Entrega',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
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
              const SizedBox(height: 16),

              // 1. Campo Título / Nombre personalizado (Máximo 25 caracteres, sin símbolos especiales)
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.words,
                maxLength: 25,
                style: TextStyle(color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ ]')),
                  _titleCaseFormatter,
                ],
                decoration: buildInputDecoration(
                  labelText: 'Nombre o Alias de la Dirección *',
                  hintText: 'Ej. Casa, Oficina, Departamento Mamá',
                  prefixIcon: Icons.bookmark_outline,
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Ingresa un alias para identificar la dirección';
                  }
                  if (text.length < 2) {
                    return 'El alias debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 2. Calle principal y número (Máximo 60 caracteres, caracteres de calles)
              TextFormField(
                controller: _streetController,
                textCapitalization: TextCapitalization.words,
                maxLength: 60,
                style: TextStyle(color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ .#\-/]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    // Impide dos espacios seguidos o dos signos iguales/consecutivos de la lista [. - # /]
                    if (RegExp(r'(\s{2,}|([.#\-/])\2+)').hasMatch(text)) {
                      return oldValue;
                    }
                    return newValue;
                  }),
                  _titleCaseFormatter,
                ],
                decoration: buildInputDecoration(
                  labelText: 'Calle Principal y Número / Intersección *',
                  hintText: 'Ej. Av. Amazonas N24-196 y Colón',
                  prefixIcon: Icons.signpost_outlined,
                ),
                validator: (val) {
                  final rawText = val ?? '';
                  final text = rawText.trim();
                  if (text.isEmpty) {
                    return 'Ingresa la calle y número (mínimo 5 caracteres)';
                  }
                  if (text.length < 5) {
                    return 'Ingresa la calle y número (mínimo 5 caracteres)';
                  }
                  if (RegExp(r'(\s{2,}|([.#\-/])\2+)').hasMatch(rawText)) {
                    return 'No se permiten espacios ni caracteres especiales consecutivos';
                  }
                  if (rawText.startsWith(' ')) {
                    return 'No debe iniciar con espacios';
                  }
                  if (RegExp(r'^[.#\-/]').hasMatch(text)) {
                    return 'No debe iniciar con caracteres especiales';
                  }
                  if (RegExp(r'[.#\-/]$').hasMatch(text)) {
                    return 'No debe terminar con caracteres especiales';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 3. Ciudad y Provincia en fila (Máximo 30 caracteres cada una, solo letras y espacios)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 30,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]')),
                        _titleCaseFormatter,
                      ],
                      decoration: buildInputDecoration(
                        labelText: 'Ciudad *',
                        hintText: 'Ej. Quito',
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Ciudad obligatoria';
                        }
                        if (text.length < 2) {
                          return 'Mínimo 2 letras';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _stateController,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 30,
                      style: TextStyle(color: textColor),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]')),
                        _titleCaseFormatter,
                      ],
                      decoration: buildInputDecoration(
                        labelText: 'Provincia',
                        hintText: 'Ej. Pichincha',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Teléfono de contacto (Prefijo 09, exactamente 10 dígitos numéricos)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: TextStyle(color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: buildInputDecoration(
                  labelText: 'Teléfono para el Repartidor *',
                  hintText: 'Ej. 0991234567',
                  prefixIcon: Icons.phone_outlined,
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'El teléfono es obligatorio';
                  }
                  if (!RegExp(r'^09\d{8}$').hasMatch(text)) {
                    return 'Debe empezar con 09 y tener 10 dígitos exactos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 5. Referencias de Entrega (Opcional, máximo 80 caracteres)
              TextFormField(
                controller: _referenceController,
                textCapitalization: TextCapitalization.words,
                maxLines: 2,
                maxLength: 80,
                style: TextStyle(color: textColor),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ .,\-]')),
                  _titleCaseFormatter,
                ],
                decoration: buildInputDecoration(
                  labelText: 'Referencias de Entrega (Opcional)',
                  hintText: 'Ej. Frente a la farmacia, casa blanca de rejas negras, timbre #3',
                  prefixIcon: Icons.notes_outlined,
                ),
              ),
              const SizedBox(height: 8),

              // Switch Dirección Predeterminada
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
                title: Text(
                  'Usar como dirección predeterminada',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                subtitle: Text(
                  'Se seleccionará automáticamente en tus próximas compras',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary,
                  ),
                ),
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              // 6. Botón Guardar / Actualizar (deshabilitado si _isLoading o !_isFormValid)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (_isLoading || !_isFormValid) ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    _isLoading
                        ? 'Guardando...'
                        : (_isEditing ? 'Actualizar Dirección' : 'Guardar Dirección'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
}
