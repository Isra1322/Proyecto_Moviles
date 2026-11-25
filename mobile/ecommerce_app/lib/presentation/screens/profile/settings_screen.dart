import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _emailController = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    await context.read<AuthProvider>().updateProfile(
      name: name,
      phone: phone.isEmpty ? null : phone,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos actualizados correctamente'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección 1: Apariencia
              _buildSectionHeader(
                context,
                icon: Icons.palette_outlined,
                title: 'Apariencia',
                subtitle: 'Personaliza el tema visual de la aplicación',
              ),
              const SizedBox(height: 10),
              _buildThemeCard(context, themeProvider),
              const SizedBox(height: 24),

              // Sección 2: Información de la Cuenta
              _buildSectionHeader(
                context,
                icon: Icons.person_outline_rounded,
                title: 'Información de la Cuenta',
                subtitle: 'Gestiona tus datos personales de contacto',
              ),
              const SizedBox(height: 10),
              if (authProvider.isAuthenticated && user != null)
                _buildAccountForm(context)
              else
                _buildGuestPromptCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeProvider themeProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            _buildThemeOption(
              context,
              mode: ThemeMode.system,
              title: 'Predeterminado del sistema',
              subtitle: 'Ajusta el tema según la configuración de tu teléfono',
              icon: Icons.brightness_auto_rounded,
              currentMode: themeProvider.themeMode,
              onSelect: () => themeProvider.setThemeMode(ThemeMode.system),
            ),
            Divider(
              height: 1,
              indent: 56,
              endIndent: 16,
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            _buildThemeOption(
              context,
              mode: ThemeMode.light,
              title: 'Modo Claro',
              subtitle: 'Fondo claro y contrastes nítidos',
              icon: Icons.light_mode_rounded,
              currentMode: themeProvider.themeMode,
              onSelect: () => themeProvider.setThemeMode(ThemeMode.light),
            ),
            Divider(
              height: 1,
              indent: 56,
              endIndent: 16,
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            _buildThemeOption(
              context,
              mode: ThemeMode.dark,
              title: 'Modo Oscuro',
              subtitle: 'Reduce el brillo y cuida tu vista',
              icon: Icons.dark_mode_rounded,
              currentMode: themeProvider.themeMode,
              onSelect: () => themeProvider.setThemeMode(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode currentMode,
    required VoidCallback onSelect,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = mode == currentMode;
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentMode,
      onChanged: (_) => onSelect(),
      activeColor: AppColors.primary,
      secondary: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(isDark ? 40 : 25)
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      dense: true,
    );
  }

  Widget _buildAccountForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark ? const Color(0xFF2A2A2A) : AppColors.background;
    final borderColor =
        isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final labelColor = isDark ? const Color(0xFFAAAAAA) : null;
    final hintColor = isDark ? const Color(0xFF757575) : null;
    final iconColor = isDark ? const Color(0xFFAAAAAA) : null;

    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Nombre Completo
              TextFormField(
                controller: _nameController,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ ]'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Nombre Completo *',
                  labelStyle: TextStyle(color: labelColor),
                  hintText: 'Ej. Juan Pérez',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: iconColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: inputFill,
                  counterText: '',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  if (text.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 2. Teléfono de Contacto (Prefijo 09, 10 dígitos)
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Teléfono de Contacto',
                  labelStyle: TextStyle(color: labelColor),
                  hintText: 'Ej. 0991234567',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    size: 20,
                    color: iconColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: inputFill,
                  counterText: '',
                ),
                validator: (val) {
                  final text = val?.trim() ?? '';
                  if (text.isNotEmpty && !RegExp(r'^09\d{8}$').hasMatch(text)) {
                    return 'Debe empezar con 09 y tener 10 dígitos exactos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 3. Correo Electrónico (Solo Lectura)
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  labelStyle: TextStyle(color: labelColor),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: iconColor,
                  ),
                  suffixIcon: Tooltip(
                    message:
                        'El correo identifica la cuenta y no se puede modificar',
                    child: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: isDark
                          ? const Color(0xFFAAAAAA)
                          : AppColors.textSecondary,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                  helperText:
                      'El correo identifica tu cuenta y no puede ser modificado.',
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFFAAAAAA)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Guardar Cambios
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _handleSaveProfile,
                  icon: _isSaving
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
                    _isSaving ? 'Guardando...' : 'Guardar Cambios',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestPromptCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 48,
              color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'Sesión no iniciada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Inicia sesión o regístrate para editar tus datos personales y direcciones.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFFAAAAAA)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
