import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

InputDecoration buildEteeloInputDecoration({
  required String labelText,
  required IconData prefixIcon,
  Widget? suffixIcon,
  String? helperText,
  String? counterText,
}) {
  return InputDecoration(
    labelText: labelText,
    helperText: helperText,
    counterText: counterText,
    labelStyle: const TextStyle(
      fontSize: 13,
      color: AppTheme.textSecondaryColor,
    ),
    helperStyle: const TextStyle(
      fontSize: 12,
      color: AppTheme.textSecondaryColor,
    ),
    prefixIcon: Icon(
      prefixIcon,
      size: 18,
      color: AppTheme.textSecondaryColor,
    ),
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: AppTheme.backgroundColor,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFF87171)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}
