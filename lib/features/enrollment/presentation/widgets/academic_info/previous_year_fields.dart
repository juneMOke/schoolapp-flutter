import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validated_year_selector.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousYearFields extends StatelessWidget {
  final AppLocalizations l10n;
  final TextEditingController prevYearController;
  final TextEditingController prevSchoolController;
  final TextEditingController prevCycleController;
  final TextEditingController prevLevelController;
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
    required this.prevYearController,
    required this.prevSchoolController,
    required this.prevCycleController,
    required this.prevLevelController,
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
            EditableField(
              width: w2,
              label: l10n.academicYearLabel,
              controller: prevYearController,
              requiredField: true,
              helpMessage: l10n.academicYearLabelHelp,
              errorText: prevYearError,
              isChanged: prevYearChanged,
              readOnly: !isEditable,
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
            EditableField(
              width: w2,
              label: l10n.schoolCycle,
              controller: prevCycleController,
              requiredField: true,
              helpMessage: l10n.schoolCycleHelp,
              errorText: prevCycleError,
              isChanged: prevCycleChanged,
              readOnly: !isEditable,
            ),
            EditableField(
              width: w2,
              label: l10n.schoolLevelLabel,
              controller: prevLevelController,
              requiredField: true,
              helpMessage: l10n.schoolLevelLabelHelp,
              errorText: prevLevelError,
              isChanged: prevLevelChanged,
              readOnly: !isEditable,
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
