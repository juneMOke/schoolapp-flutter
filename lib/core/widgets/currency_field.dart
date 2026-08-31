import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Un nombre, mis en forme **sans sa devise** — et donc sans la règle qui en
/// dépend.
///
/// Les décimales s'y décident encore sur la valeur, faute de savoir de quelle
/// devise il s'agit. Ce n'est pas un oubli : cette fonction sert aussi à
/// remplir un champ de saisie, où un « 425,00 » imposé serait pénible à
/// corriger.
///
/// **Pour afficher de l'argent, utiliser `MoneyFormat.format`**, qui connaît la
/// devise et applique sa règle.
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

/// Façade sur [MoneyFormat.format], le temps que les écrans portent des
/// [Money] plutôt que des paires (double, String).
///
/// L'aller-retour cents → double → cents est l'héritage de cette signature ;
/// l'arrondi le referme (`80,07` vaut `80.069999…` en binaire, et une
/// troncature y emporterait le centime).
String formatMonetaryAmountWithCurrency({
  required double amount,
  required String currency,
}) => MoneyFormat.format(Money.parse((amount * 100).round(), currency));

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
