import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Décoration des champs de saisie propres à Facturation.
///
/// Elle n'habille plus que le champ de MONTANT d'une imputation : les champs
/// texte de la modale d'encaissement sont passés au socle
/// (`EteeloTextInput` / `EteeloPhoneInput`), dont le libellé se pose au-dessus
/// du champ. Le téléphone ne pouvait pas prendre cette décoration sans qu'on
/// recopie sa conversion national↔E.164 ; c'est donc lui qui a donné le format,
/// et la section entière qui s'y est rangée.
///
/// Ne pas la rouvrir aux champs texte : ce serait rétablir deux écritures d'un
/// même champ dans une même popin.
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
    fillColor: readOnly
        ? AppColors.financeDetailMutedSurface
        : AppColors.surface,
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
