import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validated_year_selector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/forms/wizard_fields_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousYearFields extends StatelessWidget {
  final AppLocalizations l10n;
  // Année scolaire — liste
  final List<String> yearOptions;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;
  final TextEditingController prevSchoolController;
  // Cycle & niveau — listes
  final List<String> cycleOptions;
  final List<String> levelOptions;
  final String? selectedCycle;
  final String? selectedLevel;
  final ValueChanged<String?> onCycleChanged;
  final ValueChanged<String?> onLevelChanged;
  final bool isCatalogLoading;
  final TextEditingController prevRateController;
  final TextEditingController prevRankController;
  final bool validatedPreviousYear;
  final ValueChanged<bool> onValidatedChanged;
  final bool showValidation;
  final String? prevYearError;
  final String? prevSchoolError;
  final String? prevCycleError;
  final String? prevLevelError;
  final String? prevRateError;
  final String? prevRankError;
  final bool validatedPreviousYearChanged;
  final bool isEditable;

  const PreviousYearFields({
    super.key,
    required this.l10n,
    required this.yearOptions,
    required this.selectedYear,
    required this.onYearChanged,
    required this.prevSchoolController,
    required this.cycleOptions,
    required this.levelOptions,
    required this.selectedCycle,
    required this.selectedLevel,
    required this.onCycleChanged,
    required this.onLevelChanged,
    this.isCatalogLoading = false,
    required this.prevRateController,
    required this.prevRankController,
    required this.validatedPreviousYear,
    required this.onValidatedChanged,
    this.showValidation = false,
    this.prevYearError,
    this.prevSchoolError,
    this.prevCycleError,
    this.prevLevelError,
    this.prevRateError,
    this.prevRankError,
    this.validatedPreviousYearChanged = false,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return WizardFieldsGrid(
      fields: [
        // Année scolaire
        WizardGridField(
          EteeloSelectInput<String>(
            label: l10n.academicYearLabel,
            required: true,
            value: selectedYear,
            items: _itemsFrom(yearOptions),
            onChanged: onYearChanged,
            errorText: prevYearError,
            enabled: isEditable,
            readOnly: !isEditable,
          ),
        ),
        // École
        WizardGridField(
          EteeloTextInput(
            controller: prevSchoolController,
            label: l10n.schoolLabel,
            required: true,
            errorText: prevSchoolError,
            readOnly: !isEditable,
            inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
          ),
        ),
        // Cycle — cascade : désactivé tant que l'année est vide.
        WizardGridField(
          EteeloSelectInput<String>(
            label: l10n.schoolCycle,
            required: true,
            value: selectedCycle,
            items: _itemsFrom(cycleOptions),
            onChanged: onCycleChanged,
            errorText: prevCycleError,
            enabled: isEditable && !isCatalogLoading && selectedYear != null,
            readOnly: !isEditable,
          ),
        ),
        // Niveau — cascade : désactivé tant que le cycle est vide.
        WizardGridField(
          EteeloSelectInput<String>(
            label: l10n.schoolLevelLabel,
            required: true,
            value: selectedLevel,
            items: _itemsFrom(levelOptions),
            onChanged: onLevelChanged,
            errorText: prevLevelError,
            enabled: isEditable && !isCatalogLoading && selectedCycle != null,
            readOnly: !isEditable,
          ),
        ),
        // Moyenne
        WizardGridField(
          EteeloTextInput(
            controller: prevRateController,
            label: l10n.averageLabel,
            required: true,
            keyboardType: EteeloTextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            errorText: prevRateError,
            readOnly: !isEditable,
          ),
        ),
        // Classement
        WizardGridField(
          EteeloTextInput(
            controller: prevRankController,
            label: l10n.rankingLabel,
            required: true,
            keyboardType: EteeloTextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            errorText: prevRankError,
            readOnly: !isEditable,
          ),
        ),
        // Année validée (contrôle segmenté Oui/Non) — pleine largeur, pour une
        // meilleure présence visuelle sur sa propre ligne.
        WizardGridField(
          ValidatedYearSelector(
            l10n: l10n,
            width: double.infinity,
            validatedPreviousYear: validatedPreviousYear,
            onChanged: onValidatedChanged,
            isChanged: validatedPreviousYearChanged,
            enabled: isEditable,
            readOnly: !isEditable,
            helpMessage: l10n.yearValidatedHelp,
          ),
          fullWidth: true,
        ),
      ],
    );
  }

  List<EteeloSelectItem<String>> _itemsFrom(List<String> options) {
    return options
        .map((option) => EteeloSelectItem<String>(value: option, label: option))
        .toList(growable: false);
  }
}
