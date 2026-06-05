import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/previous_year_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class PreviousAcademicInfoStepBody extends StatelessWidget {
  // Année scolaire — dropdown
  final List<String> yearOptions;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;
  final TextEditingController prevSchoolController;
  // Cycle & niveau remplacés par dropdowns
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
  final bool showValidation;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final VoidCallback onSave;
  final bool isEditable;
  final ValueChanged<bool> onValidatedChanged;
  final String? prevYearError;
  final String? prevSchoolError;
  final String? prevCycleError;
  final String? prevLevelError;
  final String? prevRateError;
  final String? prevRankError;
  final bool validatedPreviousYearChanged;

  const PreviousAcademicInfoStepBody({
    super.key,
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
    required this.showValidation,
    required this.isLoading,
    required this.canSave,
    required this.showInlineSaveButton,
    required this.onSave,
    this.isEditable = true,
    required this.onValidatedChanged,
    this.prevYearError,
    this.prevSchoolError,
    this.prevCycleError,
    this.prevLevelError,
    this.prevRateError,
    this.prevRankError,
    this.validatedPreviousYearChanged = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PreviousYearFields(
            l10n: l10n,
            yearOptions: yearOptions,
            selectedYear: selectedYear,
            onYearChanged: onYearChanged,
            prevSchoolController: prevSchoolController,
            cycleOptions: cycleOptions,
            levelOptions: levelOptions,
            selectedCycle: selectedCycle,
            selectedLevel: selectedLevel,
            onCycleChanged: onCycleChanged,
            onLevelChanged: onLevelChanged,
            isCatalogLoading: isCatalogLoading,
            prevRateController: prevRateController,
            prevRankController: prevRankController,
            validatedPreviousYear: validatedPreviousYear,
            onValidatedChanged: onValidatedChanged,
            showValidation: showValidation,
            prevYearError: prevYearError,
            prevSchoolError: prevSchoolError,
            prevCycleError: prevCycleError,
            prevLevelError: prevLevelError,
            prevRateError: prevRateError,
            prevRankError: prevRankError,
            validatedPreviousYearChanged: validatedPreviousYearChanged,
            isEditable: isEditable,
          ),
          if (showInlineSaveButton) ...<Widget>[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: (isLoading || !canSave) ? null : onSave,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isLoading ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: canSave ? AppColors.info : null,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  elevation: canSave ? 6 : 0,
                  shadowColor: AppColors.info.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
