import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

String formatMonetaryAmount(double amount) {
  final isInteger = amount == amount.roundToDouble();
  final raw = isInteger ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  final parts = raw.split('.');
  final whole = parts.first;

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('\u00A0');
    }
  }

  if (parts.length == 2) {
    return '${buffer.toString()},${parts[1]}';
  }

  return buffer.toString();
}

double? parseMonetaryAmount(String rawValue) {
  final normalized = rawValue
      .trim()
      .replaceAll(' ', '')
      .replaceAll('\u00A0', '')
      .replaceAll(',', '.');

  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}

String formatMonetaryAmountWithCurrency({
  required double amount,
  required String currency,
}) {
  return '${formatMonetaryAmount(amount)}\u00A0$currency';
}

class CurrencyField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final bool enabled;
  final String? labelText;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const CurrencyField({
    super.key,
    required this.controller,
    required this.currency,
    this.enabled = true,
    this.labelText,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        errorText: errorText,
        suffixText: currency,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(color: AppColors.bleuArdoise, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      style: AppTextStyles.moneyTabular.copyWith(color: AppColors.textPrimary),
    );
  }
}
