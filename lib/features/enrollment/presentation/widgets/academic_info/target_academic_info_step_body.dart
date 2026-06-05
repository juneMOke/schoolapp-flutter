import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/target_year_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class TargetAcademicInfoStepBody extends StatelessWidget {
  final Bootstrap? bootstrap;
  final TextEditingController currYearController;
  final TextEditingController targetOptionController;
  final String selectedSchoolLevelGroupId;
  final String selectedSchoolLevelId;
  final bool showValidation;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final VoidCallback onSave;
  final bool isEditable;
  final void Function(String groupId, String firstLevelId) onGroupChanged;
  final ValueChanged<String> onLevelChanged;
  final String? groupError;
  final String? levelError;

  const TargetAcademicInfoStepBody({
    super.key,
    required this.bootstrap,
    required this.currYearController,
    required this.targetOptionController,
    required this.selectedSchoolLevelGroupId,
    required this.selectedSchoolLevelId,
    required this.showValidation,
    required this.isLoading,
    required this.canSave,
    required this.showInlineSaveButton,
    required this.onSave,
    this.isEditable = true,
    required this.onGroupChanged,
    required this.onLevelChanged,
    this.groupError,
    this.levelError,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TargetYearFields(
            l10n: l10n,
            bootstrap: bootstrap,
            currYearController: currYearController,
            targetOptionController: targetOptionController,
            selectedSchoolLevelGroupId: selectedSchoolLevelGroupId,
            selectedSchoolLevelId: selectedSchoolLevelId,
            groupError: groupError,
            levelError: levelError,
            onGroupChanged: onGroupChanged,
            onLevelChanged: onLevelChanged,
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
                          color: AppColors.textOnDark,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isLoading ? l10n.savingAcademicInfo : l10n.saveAcademicInfo,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: canSave ? AppColors.info : null,
                  foregroundColor: AppColors.textOnDark,
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
