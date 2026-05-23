import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/fields/dropdown_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validated_year_selector.dart';
import 'package:school_app_flutter/core/components/fields/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousYearFields extends StatelessWidget {
  final AppLocalizations l10n;
  // Année scolaire — dropdown
  final List<String> yearOptions;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;
  final TextEditingController prevSchoolController;
  // Cycle & niveau — dropdowns
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
  final bool prevYearChanged;
  final bool prevSchoolChanged;
  final bool prevCycleChanged;
  final bool prevLevelChanged;
  final bool prevRateChanged;
  final bool prevRankChanged;
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
    this.prevYearChanged = false,
    this.prevSchoolChanged = false,
    this.prevCycleChanged = false,
    this.prevLevelChanged = false,
    this.prevRateChanged = false,
    this.prevRankChanged = false,
    this.validatedPreviousYearChanged = false,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final w2 = (constraints.maxWidth - spacing) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne 1 & 2 : année / école / cycle / niveau
            Wrap(
              spacing: spacing,
              runSpacing: 14,
              children: [
                DropdownField(
                  width: w2,
                  label: l10n.academicYearLabel,
                  helpMessage: l10n.academicYearLabelHelp,
                  items: yearOptions
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt,
                          child: Text(
                            opt,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.formValueMedium,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  value: selectedYear,
                  onChanged: onYearChanged,
                  errorText: prevYearError,
                  isChanged: prevYearChanged,
                  enabled: isEditable,
                ),
                EditableField(
                  width: w2,
                  label: l10n.schoolLabel,
                  controller: prevSchoolController,
                  requiredField: true,
                  helpMessage: l10n.schoolLabelHelp,
                  errorText: prevSchoolError,
                  isChanged: prevSchoolChanged,
                  readOnly: !isEditable,
                ),
                DropdownField(
                  width: w2,
                  label: l10n.schoolCycle,
                  helpMessage: l10n.schoolCycleHelp,
                  items: cycleOptions
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt,
                          child: Text(
                            opt,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.formValueMedium,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  value: selectedCycle,
                  onChanged: onCycleChanged,
                  errorText: prevCycleError,
                  isChanged: prevCycleChanged,
                  enabled: isEditable && !isCatalogLoading,
                ),
                DropdownField(
                  width: w2,
                  label: l10n.schoolLevelLabel,
                  helpMessage: l10n.schoolLevelLabelHelp,
                  items: levelOptions
                      .map(
                        (opt) => DropdownMenuItem<String>(
                          value: opt,
                          child: Text(
                            opt,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.formValueMedium,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  value: selectedLevel,
                  onChanged: onLevelChanged,
                  errorText: prevLevelError,
                  isChanged: prevLevelChanged,
                  enabled: isEditable && !isCatalogLoading && selectedCycle != null,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Ligne 3 : moyenne | classement | année validée — toujours sur la même ligne
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: EditableField(
                      width: double.infinity,
                      label: l10n.averageLabel,
                      controller: prevRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      helpMessage: l10n.averageLabelHelp,
                      requiredField: true,
                      errorText: prevRateError,
                      isChanged: prevRateChanged,
                      readOnly: !isEditable,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: EditableField(
                      width: double.infinity,
                      label: l10n.rankingLabel,
                      controller: prevRankController,
                      keyboardType: TextInputType.number,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      helpMessage: l10n.rankingLabelHelp,
                      requiredField: true,
                      errorText: prevRankError,
                      isChanged: prevRankChanged,
                      readOnly: !isEditable,
                    ),
                  ),
                  const SizedBox(width: spacing),
                  Expanded(
                    child: ValidatedYearSelector(
                      l10n: l10n,
                      width: double.infinity,
                      validatedPreviousYear: validatedPreviousYear,
                      onChanged: onValidatedChanged,
                      isChanged: validatedPreviousYearChanged,
                      enabled: isEditable,
                      helpMessage: l10n.yearValidatedHelp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}