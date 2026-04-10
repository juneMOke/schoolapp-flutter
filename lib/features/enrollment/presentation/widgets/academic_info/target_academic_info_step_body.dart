import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/academic_info_widgets.dart';
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
  final void Function(String groupId, String firstLevelId) onGroupChanged;
  final ValueChanged<String> onLevelChanged;
  final String? groupError;
  final String? levelError;
  final bool groupChanged;
  final bool levelChanged;

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
    required this.onGroupChanged,
    required this.onLevelChanged,
    this.groupError,
    this.levelError,
    this.groupChanged = false,
    this.levelChanged = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: <Widget>[
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