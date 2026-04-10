import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/dropdown_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/read_only_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

typedef OnTargetGroupChanged = void Function(String groupId, String firstLevelId);

class TargetYearFields extends StatelessWidget {
  final AppLocalizations l10n;
  final Bootstrap? bootstrap;
  final TextEditingController currYearController;
  final TextEditingController targetOptionController;
  final String selectedSchoolLevelGroupId;
  final String selectedSchoolLevelId;
  final OnTargetGroupChanged onGroupChanged;
  final ValueChanged<String> onLevelChanged;
  final String? groupError;
  final String? levelError;
  final bool groupChanged;
  final bool levelChanged;

  const TargetYearFields({
    super.key,
    required this.l10n,
    required this.bootstrap,
    required this.currYearController,
    required this.targetOptionController,
    required this.selectedSchoolLevelGroupId,
    required this.selectedSchoolLevelId,
    required this.onGroupChanged,
    required this.onLevelChanged,
    this.groupError,
    this.levelError,
    this.groupChanged = false,
    this.levelChanged = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final w = (constraints.maxWidth - spacing) / 2;
        final groupBundles = bootstrap?.schoolLevelGroups ?? const [];
        final selectedGroupBundle = groupBundles
            .where((g) => g.schoolLevelGroup.id == selectedSchoolLevelGroupId)
            .firstOrNull;

        final groupItems = groupBundles
            .map(
              (bundle) => DropdownMenuItem<String>(
                value: bundle.schoolLevelGroup.id,
                child: Text(bundle.schoolLevelGroup.name),
              ),
            )
            .toList();

        final levelItems = (selectedGroupBundle?.schoolLevels ?? const [])
            .map(
              (levelBundle) => DropdownMenuItem<String>(
                value: levelBundle.schoolLevel.id,
                child: Text(levelBundle.schoolLevel.name),
              ),
            )
            .toList();

        return Wrap(
          spacing: spacing,
          runSpacing: 14,
          children: [
            ReadOnlyField(
              width: w,
              label: l10n.currentAcademicYearLabel,
              controller: currYearController,
              requiredField: true,
              helpMessage: l10n.currentAcademicYearHelp,
            ),
            DropdownField(
              width: w,
              label: l10n.targetCycleLabel,
              value: groupItems.any((item) => item.value == selectedSchoolLevelGroupId)
                  ? selectedSchoolLevelGroupId
                  : null,
              items: groupItems,
              onChanged: (value) {
                if (value == null) return;
                final newBundle = groupBundles
                    .where((g) => g.schoolLevelGroup.id == value)
                    .firstOrNull;
                onGroupChanged(
                  value,
                  newBundle?.schoolLevels.firstOrNull?.schoolLevel.id ?? '',
                );
              },
              helpMessage: l10n.targetCycleLabelHelp,
              errorText: groupError,
              isChanged: groupChanged,
            ),
            DropdownField(
              width: w,
              label: l10n.targetLevelLabel,
              value: levelItems.any((item) => item.value == selectedSchoolLevelId)
                  ? selectedSchoolLevelId
                  : null,
              items: levelItems,
              onChanged: (value) {
                if (value == null) return;
                onLevelChanged(value);
              },
              helpMessage: l10n.targetLevelLabelHelp,
              errorText: levelError,
              isChanged: levelChanged,
            ),
            EditableField(
              width: w,
              label: l10n.optionLabel,
              controller: targetOptionController,
              helpMessage: l10n.optionLabelHelp,
            ),
          ],
        );
      },
    );
  }
}
