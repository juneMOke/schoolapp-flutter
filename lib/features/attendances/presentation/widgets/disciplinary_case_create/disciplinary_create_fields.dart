import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/formatters/text_capitalization_formatters.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_category.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_sanction.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'intitulé posé au-dessus d'un champ de la modale « Nouveau cas » : la
/// modale garde UN seul style d'intitulé.
class DisciplinaryCreateFieldLabel extends StatelessWidget {
  final String label;

  const DisciplinaryCreateFieldLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTextStyles.caption.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Pas de `labelText` : chaque champ porte déjà un libellé au-dessus
/// ([DisciplinaryCreateFieldLabel]), le label flottant ferait doublon.
InputDecoration disciplinaryCreateInputDecoration({String? hintText}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.spacingM),
      borderSide: const BorderSide(color: AppColors.disciplinaryDetailAccent),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.spacingM,
      vertical: AppDimensions.spacingM,
    ),
  );
}

/// Un champ de texte libre de la modale, sous son intitulé : obligatoire,
/// capitalisé en phrase.
class DisciplinaryCreateTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;

  /// Vrai pour le récit du fait (3 à 5 lignes).
  final bool multiline;

  const DisciplinaryCreateTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryCreateFieldLabel(label),
        const SizedBox(height: AppDimensions.spacingXS),
        TextFormField(
          controller: controller,
          enabled: enabled,
          inputFormatters: const [SentenceCapitalizationInputFormatter()],
          textCapitalization: TextCapitalization.sentences,
          decoration: disciplinaryCreateInputDecoration(hintText: hint),
          minLines: multiline ? 3 : null,
          maxLines: multiline ? 5 : 1,
          validator: (value) => value == null || value.trim().isEmpty
              ? l10n.disciplinaryCaseCreateDialogRequiredFieldError
              : null,
        ),
      ],
    );
  }
}

/// La catégorie du fait : elle sert de gabarit (gravité, titre).
class DisciplinaryCreateCategoryField extends StatelessWidget {
  static const _categories = [
    DisciplinaryCategory.disruptiveBehavior,
    DisciplinaryCategory.lateness,
    DisciplinaryCategory.repeatedLateness,
    DisciplinaryCategory.unjustifiedAbsence,
    DisciplinaryCategory.insolence,
    DisciplinaryCategory.cheating,
    DisciplinaryCategory.fighting,
    DisciplinaryCategory.dressCodeViolation,
    DisciplinaryCategory.talkingInClass,
  ];

  final DisciplinaryCategory value;
  final bool enabled;
  final ValueChanged<DisciplinaryCategory> onChanged;

  const DisciplinaryCreateCategoryField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryCreateFieldLabel(l10n.disciplinaryFieldCategory),
        const SizedBox(height: AppDimensions.spacingXS),
        EteeloSelectInput<DisciplinaryCategory>(
          // Le libellé reste porté par l'intitulé, comme pour les champs
          // texte voisins : la modale garde UN seul style d'intitulé.
          label: l10n.disciplinaryFieldCategory,
          hideLabel: true,
          value: value,
          enabled: enabled,
          minWidth: 0,
          items: [
            for (final category in _categories)
              EteeloSelectItem<DisciplinaryCategory>(
                value: category,
                label: category.getDisplayName(l10n),
              ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    );
  }
}

/// La gravité, en trois onglets équilibrés.
class DisciplinaryCreateSeverityField extends StatelessWidget {
  final DisciplinarySeverity value;
  final ValueChanged<DisciplinarySeverity> onChanged;

  const DisciplinaryCreateSeverityField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryCreateFieldLabel(l10n.disciplinaryFieldSeverity),
        const SizedBox(height: AppDimensions.spacingXS),
        SegmentedTabFilter<DisciplinarySeverity>(
          options: [
            for (final severity in const [
              DisciplinarySeverity.minor,
              DisciplinarySeverity.major,
              DisciplinarySeverity.serious,
            ])
              SegmentedTabOption(
                label: severity.getDisplayName(l10n),
                value: severity,
              ),
          ],
          selected: value,
          onSelected: onChanged,
          // Modale étroite : onglets équilibrés pleine largeur (pas de débordement).
          expand: true,
        ),
      ],
    );
  }
}

/// La sanction, facultative (« non décidée » par défaut).
class DisciplinaryCreateSanctionField extends StatelessWidget {
  static const _sanctions = [
    DisciplinarySanction.unknown,
    DisciplinarySanction.oralWarning,
    DisciplinarySanction.writtenWarning,
    DisciplinarySanction.detention,
    DisciplinarySanction.parentsSummoned,
    DisciplinarySanction.temporaryExclusion,
    DisciplinarySanction.disciplinaryCouncil,
    DisciplinarySanction.permanentExclusion,
  ];

  final DisciplinarySanction value;
  final bool enabled;
  final ValueChanged<DisciplinarySanction> onChanged;

  const DisciplinaryCreateSanctionField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisciplinaryCreateFieldLabel(l10n.disciplinaryFieldSanction),
        const SizedBox(height: AppDimensions.spacingXS),
        EteeloSelectInput<DisciplinarySanction>(
          label: l10n.disciplinaryFieldSanction,
          hideLabel: true,
          value: value,
          enabled: enabled,
          minWidth: 0,
          items: [
            for (final sanction in _sanctions)
              EteeloSelectItem<DisciplinarySanction>(
                value: sanction,
                label: sanction.getDisplayName(l10n),
              ),
          ],
          onChanged: (value) =>
              onChanged(value ?? DisciplinarySanction.unknown),
        ),
      ],
    );
  }
}
