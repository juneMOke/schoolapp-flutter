import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/labels/form_field_label.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Sélecteur **tri-état** de l'année précédente : validée / non validée / non
/// renseignée.
///
/// Le troisième segment est explicite, et non une déselection : « non validée »
/// est un redoublement, « non renseignée » n'est rien du tout, et le calcul
/// automatique de la classe cible traite les deux différemment. Tant que ce
/// sélecteur n'avait que deux positions, un dossier neuf s'affichait « Non »
/// sans que personne l'ait dit — la même valeur inventée que le serveur a
/// cessé de fabriquer. Une déselection ferait l'affaire techniquement, mais
/// personne ne devine qu'un segment se déclique.
class ValidatedYearSelector extends StatelessWidget {
  final AppLocalizations l10n;
  final double width;
  final bool? validatedPreviousYear;
  final ValueChanged<bool?> onChanged;
  final bool isChanged;
  final bool enabled;

  /// Lecture seule : non interactif mais garde l'apparence active (segment
  /// sélectionné mis en évidence, pleine couleur), contrairement à
  /// [enabled] = false qui grise tout.
  final bool readOnly;
  final String helpMessage;

  const ValidatedYearSelector({
    super.key,
    required this.l10n,
    required this.width,
    required this.validatedPreviousYear,
    required this.onChanged,
    this.isChanged = false,
    this.enabled = true,
    this.readOnly = false,
    this.helpMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !readOnly;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: l10n.yearValidated,
            // Oui/Non = teinte neutre unique (bleu ardoise), pas de connotation.
            labelColor: isChanged ? AppColors.bleuArdoise : null,
            helpMessage: helpMessage,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: IgnorePointer(
              ignoring: !interactive,
              child: ExcludeFocus(
                excluding: !interactive,
                child: SegmentedButton<bool?>(
                  segments: [
                    ButtonSegment<bool?>(
                      value: true,
                      label: Text(l10n.yearValidated),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                    ),
                    ButtonSegment<bool?>(
                      value: false,
                      label: Text(l10n.yearNotValidated),
                      icon: const Icon(Icons.cancel_rounded, size: 16),
                    ),
                    ButtonSegment<bool?>(
                      value: null,
                      label: Text(l10n.yearValidationUnknown),
                      icon: const Icon(Icons.help_outline_rounded, size: 16),
                    ),
                  ],
                  selected: {validatedPreviousYear},
                  // En lecture seule, handler no-op : conserve l'apparence active
                  // (sélection visible) ; taps neutralisés par IgnorePointer.
                  onSelectionChanged: interactive
                      // `firstOrNull` ne peut plus servir de garde : `null` est
                      // désormais une valeur choisie, pas une sélection vide.
                      // Le sélecteur n'autorisant pas la sélection vide, la
                      // liste porte toujours exactement un élément.
                      ? (selection) => onChanged(selection.first)
                      : readOnly
                      ? (_) {}
                      : null,
                  style: SegmentedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textSecondary,
                    selectedForegroundColor: AppColors.textOnDark,
                    selectedBackgroundColor: AppColors.bleuArdoise,
                    side: BorderSide(
                      color: AppColors.bleuArdoise.withValues(alpha: 0.25),
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brSm,
                    ),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
