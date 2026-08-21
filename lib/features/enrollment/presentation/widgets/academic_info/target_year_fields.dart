import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/forms/wizard_fields_grid.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

typedef OnTargetGroupChanged =
    void Function(String groupId, String firstLevelId);

class TargetYearFields extends StatelessWidget {
  final AppLocalizations l10n;
  final AcademicYearContext? bootstrap;
  final TextEditingController currYearController;
  final TextEditingController targetOptionController;
  final String selectedSchoolLevelGroupId;
  final String selectedSchoolLevelId;
  final OnTargetGroupChanged onGroupChanged;
  final ValueChanged<String> onLevelChanged;
  final String? groupError;
  final String? levelError;
  final bool isEditable;

  /// Classe cible calculée automatiquement (réinscription) et pas encore
  /// modifiée à la main — affiche un badge « Auto ».
  final bool isAutoComputed;

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
    this.isEditable = true,
    this.isAutoComputed = false,
  });

  @override
  Widget build(BuildContext context) {
    final groupBundles = bootstrap?.schoolLevelGroups ?? const [];
    final selectedGroupBundle = groupBundles
        .where((g) => g.group.id == selectedSchoolLevelGroupId)
        .firstOrNull;

    final groupItems = groupBundles
        .map(
          (bundle) => EteeloSelectItem<String>(
            value: bundle.group.id,
            label: bundle.group.name,
          ),
        )
        .toList(growable: false);

    final levelItems = (selectedGroupBundle?.levels ?? const [])
        .map(
          (level) =>
              EteeloSelectItem<String>(value: level.id, label: level.name),
        )
        .toList(growable: false);

    final hasSelectedGroup = groupItems.any(
      (item) => item.value == selectedSchoolLevelGroupId,
    );
    final hasSelectedLevel = levelItems.any(
      (item) => item.value == selectedSchoolLevelId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAutoComputed) ...[
          Tooltip(
            message: l10n.targetLevelAutoBadgeHelp,
            child: EteeloChip(
              icon: Icons.auto_awesome,
              label: l10n.targetLevelAutoBadge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        WizardFieldsGrid(
          fields: [
            WizardGridField(
              EteeloTextInput(
                controller: currYearController,
                label: l10n.currentAcademicYearLabel,
                required: true,
                readOnly: true,
              ),
            ),
            WizardGridField(
              EteeloSelectInput<String>(
                label: l10n.targetCycleLabel,
                required: true,
                value: hasSelectedGroup ? selectedSchoolLevelGroupId : null,
                items: groupItems,
                onChanged: (value) {
                  if (value == null) return;
                  final newBundle = groupBundles
                      .where((g) => g.group.id == value)
                      .firstOrNull;
                  onGroupChanged(
                    value,
                    newBundle?.levels.firstOrNull?.id ?? '',
                  );
                },
                errorText: groupError,
                enabled: isEditable,
                readOnly: !isEditable,
              ),
            ),
            WizardGridField(
              EteeloSelectInput<String>(
                label: l10n.targetLevelLabel,
                required: true,
                value: hasSelectedLevel ? selectedSchoolLevelId : null,
                items: levelItems,
                onChanged: (value) {
                  if (value == null) return;
                  onLevelChanged(value);
                },
                errorText: levelError,
                // Cascade : le niveau est désactivé tant que le cycle est vide.
                enabled: isEditable && selectedSchoolLevelGroupId.isNotEmpty,
                readOnly: !isEditable,
              ),
            ),
            WizardGridField(
              EteeloTextInput(
                controller: targetOptionController,
                label: l10n.optionLabel,
                readOnly: !isEditable,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
