import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

InputDecoration buildInputDecoration({
  String hintText = '',
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
  bool isChanged = false,
}) {
  final changedColor = AppColors.success;
  return InputDecoration(
    hintText: hintText,
    isDense: true,
    filled: true,
    fillColor: isChanged
        ? AppColors.financeDetailSuccessSoft
        : AppColors.surface,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 2,
    enabledBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: AppColors.error, width: 1.4),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(
        color: isChanged ? changedColor : AppColors.bleuArdoise,
        width: 1.4,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm + 2,
    ),
  );
}
