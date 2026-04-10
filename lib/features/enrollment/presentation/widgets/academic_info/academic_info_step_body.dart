import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AcademicInfoStepBody extends StatelessWidget {
  final Bootstrap? bootstrap;
  final TextEditingController? prevYearController;
  final TextEditingController? prevSchoolController;
  final TextEditingController? prevCycleController;
  final TextEditingController? prevLevelController;
  final TextEditingController? prevRateController;
  final TextEditingController? prevRankController;
  final TextEditingController currYearController;
  final TextEditingController targetOptionController;
  final bool validatedPreviousYear;
  final String selectedSchoolLevelGroupId;
  final String selectedSchoolLevelId;
  final bool showValidation;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final bool showPreviousSection;
  final bool showTargetSection;
  final VoidCallback onSave;
  final ValueChanged<bool>? onValidatedChanged;
  final void Function(String groupId, String firstLevelId) onGroupChanged;
  final ValueChanged<String> onLevelChanged;
  final String? prevYearError;
  final String? prevSchoolError;
  final String? prevCycleError;
  final String? prevLevelError;
  final String? prevRateError;
  final String? prevRankError;
  final String? groupError;
  final String? levelError;
  final bool prevYearChanged;
  final bool prevSchoolChanged;
  final bool prevCycleChanged;
  final bool prevLevelChanged;
  final bool prevRateChanged;
  final bool prevRankChanged;
  final bool validatedPreviousYearChanged;
  final bool groupChanged;
  final bool levelChanged;

  const AcademicInfoStepBody({
    super.key,
    required this.bootstrap,
    this.prevYearController,
    this.prevSchoolController,
    this.prevCycleController,
    this.prevLevelController,
    this.prevRateController,
    this.prevRankController,
    required this.currYearController,
    required this.targetOptionController,
    this.validatedPreviousYear = false,
    required this.selectedSchoolLevelGroupId,
    required this.selectedSchoolLevelId,
    required this.showValidation,
    required this.isLoading,
    required this.canSave,
    required this.showInlineSaveButton,
    this.showPreviousSection = true,
    this.showTargetSection = true,
    required this.onSave,
    this.onValidatedChanged,
    required this.onGroupChanged,
    required this.onLevelChanged,
    this.prevYearError,
    this.prevSchoolError,
    this.prevCycleError,
    this.prevLevelError,
    this.prevRateError,
    this.prevRankError,
    this.groupError,
    this.levelError,
    this.prevYearChanged = false,
    this.prevSchoolChanged = false,
    this.prevCycleChanged = false,
    this.prevLevelChanged = false,
    this.prevRateChanged = false,
    this.prevRankChanged = false,
    this.validatedPreviousYearChanged = false,
    this.groupChanged = false,
    this.levelChanged = false,
  }) : assert(
         !showPreviousSection ||
             (prevYearController != null &&
                 prevSchoolController != null &&
                 prevCycleController != null &&
                 prevLevelController != null &&
                 prevRateController != null &&
                 prevRankController != null &&
                 onValidatedChanged != null),
         'Les champs previous* et onValidatedChanged sont requis si showPreviousSection est true.',
       );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (showPreviousSection)
          AcademicInfoCard(
            icon: Icons.school_outlined,
            iconColor: AppTheme.primaryColor,
            title: l10n.previousYear,
            titleColor: AppTheme.primaryColor,
            child: PreviousYearFields(
              l10n: l10n,
              prevYearController: prevYearController!,
              prevSchoolController: prevSchoolController!,
              prevCycleController: prevCycleController!,
              prevLevelController: prevLevelController!,
              prevRateController: prevRateController!,
              prevRankController: prevRankController!,
              validatedPreviousYear: validatedPreviousYear,
              onValidatedChanged: onValidatedChanged!,
              showValidation: showValidation,
              prevYearError: prevYearError,
              prevSchoolError: prevSchoolError,
              prevCycleError: prevCycleError,
              prevLevelError: prevLevelError,
              prevRateError: prevRateError,
              prevRankError: prevRankError,
              prevYearChanged: prevYearChanged,
              prevSchoolChanged: prevSchoolChanged,
              prevCycleChanged: prevCycleChanged,
              prevLevelChanged: prevLevelChanged,
              prevRateChanged: prevRateChanged,
              prevRankChanged: prevRankChanged,
              validatedPreviousYearChanged: validatedPreviousYearChanged,
            ),
          ),
        if (showPreviousSection && showTargetSection)
          const SizedBox(height: 20),
        if (showTargetSection)
          AcademicInfoCard(
            icon: Icons.flag_outlined,
            iconColor: Colors.green[600]!,
            title: l10n.targetYear,
            titleColor: Colors.green[600]!,
            child: TargetYearFields(
              l10n: l10n,
              bootstrap: bootstrap,
              currYearController: currYearController,
              targetOptionController: targetOptionController,
              selectedSchoolLevelGroupId: selectedSchoolLevelGroupId,
              selectedSchoolLevelId: selectedSchoolLevelId,
              groupError: groupError,
              levelError: levelError,
              groupChanged: groupChanged,
              levelChanged: levelChanged,
              onGroupChanged: onGroupChanged,
              onLevelChanged: onLevelChanged,
            ),
          ),
        if (showInlineSaveButton) ...[
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
                backgroundColor: canSave ? const Color(0xFF0EA5E9) : null,
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
                shadowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
