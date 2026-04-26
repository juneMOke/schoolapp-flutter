import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

InputDecoration financeInputDecoration({
  required String label,
  required String hint,
  required Color accentColor,
  required bool readOnly,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
    filled: true,
    fillColor: readOnly ? AppColors.financeDetailMutedSurface : AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingM,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: BorderSide(color: accentColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
    ),
  );
}

class FinanceTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool readOnly;
  final Color accentColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const FinanceTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.accentColor,
    this.validator,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: financeInputDecoration(
        label: label,
        hint: hint,
        accentColor: accentColor,
        readOnly: readOnly,
      ),
      validator: validator,
    );
  }
}
