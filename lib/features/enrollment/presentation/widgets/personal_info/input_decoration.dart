import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

InputDecoration buildInputDecoration({
  String hintText = '',
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  bool isChanged = false,
}) {
  final changedColor = const Color(0xFF16A34A);
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: isChanged ? const Color(0xFFF0FDF4) : Colors.white,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isChanged
            ? changedColor.withValues(alpha: 0.55)
            : AppTheme.primaryColor.withValues(alpha: 0.25),
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: Color(0xFFEF4444),
        width: 1.4,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: isChanged ? changedColor : AppTheme.primaryColor,
        width: 1.4,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );
}
