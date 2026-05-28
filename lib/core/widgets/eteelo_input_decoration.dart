import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

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
    labelStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    helperStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    prefixIcon: Icon(prefixIcon, size: 18, color: AppColors.textSecondary),
    suffixIcon: suffixIcon,
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.bleuArdoise, width: 1.5),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.error, width: 1.5),
    ),
    disabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.stateDisabled),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md,
    ),
  );
}
