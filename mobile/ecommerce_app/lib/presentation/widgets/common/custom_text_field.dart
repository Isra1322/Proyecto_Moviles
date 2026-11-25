import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ecommerce_app/core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? counterText;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.inputFormatters,
    this.maxLength,
    this.counterText,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? const Color(0xFFAAAAAA) : AppColors.textSecondary,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF757575) : AppColors.textSecondary,
        ),
        counterText: counterText,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              )
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}


