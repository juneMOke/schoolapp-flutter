import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/dropdown_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validated_year_selector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
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
        final w3 = constraints.maxWidth >= 700
            ? (constraints.maxWidth - spacing * 2) / 3
            : w2;

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            // Année scolaire — liste déroulante
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
            // Cycle — liste déroulante
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
            // Niveau — liste déroulante (dépend du cycle)
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
            EditableField(
              width: w3,
              label: l10n.averageLabel,
              controller: prevRateController,
              helpMessage: l10n.averageLabelHelp,
              requiredField: true,
              errorText: prevRateError,
              isChanged: prevRateChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: w3,
              label: l10n.rankingLabel,
              controller: prevRankController,
              helpMessage: l10n.rankingLabelHelp,
              requiredField: true,
              errorText: prevRankError,
              isChanged: prevRankChanged,
              readOnly: !isEditable,
            ),
            ValidatedYearSelector(
              l10n: l10n,
              width: w3,
              validatedPreviousYear: validatedPreviousYear,
              onChanged: onValidatedChanged,
              isChanged: validatedPreviousYearChanged,
              enabled: isEditable,
            ),
          ],
        );
      },
    );
  }
}