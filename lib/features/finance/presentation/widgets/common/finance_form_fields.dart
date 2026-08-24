import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';

/// Libellé d'un champ requis : le libellé traduit suivi d'une étoile rouge.
///
/// L'étoile est un WIDGET, jamais un `*` concaténé au libellé : collée dans la
/// chaîne, elle traverse la traduction (deux `.arb` à tenir), se retrouve lue
/// à voix haute par le lecteur d'écran au milieu du nom du champ, et sort dans
/// la couleur du libellé — indiscernable de la ponctuation. Même rendu et même
/// couleur que le socle `EteeloTextInput`, pour que « obligatoire » se lise
/// pareil dans toute l'application.
Widget financeRequiredLabel(String label, {TextStyle? style}) => Text.rich(
  TextSpan(
    text: label,
    children: const [
      TextSpan(
        text: ' *',
        style: TextStyle(color: AppColors.error),
      ),
    ],
  ),
  style: style,
);

InputDecoration financeInputDecoration({
  required String label,
  required String hint,
  required Color accentColor,
  required bool readOnly,
  bool isRequired = false,
}) {
  final labelStyle = AppTextStyles.caption.copyWith(
    color: AppColors.textSecondary,
  );
  return InputDecoration(
    // `label` (widget) et `labelText` (chaîne) s'excluent : Material lève si
    // les deux sont posés. Le champ facultatif garde la chaîne — moins de
    // travail de mise en page pour le cas le plus courant.
    label: isRequired ? financeRequiredLabel(label, style: labelStyle) : null,
    labelText: isRequired ? null : label,
    hintText: hint,
    labelStyle: labelStyle,
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

class FinanceTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final bool readOnly;
  final Color accentColor;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Champ obligatoire : le libellé porte l'étoile rouge du socle. Le drapeau
  /// ne valide RIEN à lui seul — c'est un marqueur visuel. La validité reste
  /// portée par [validator] et par la garde du formulaire appelant.
  final bool isRequired;

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
    this.isRequired = false,
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
        isRequired: isRequired,
      ),
      validator: validator,
    );
  }
}
