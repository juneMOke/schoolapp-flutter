import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_diploma.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_job_catalog.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_field_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_synced_text_input.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 4 · Diplômes — du plus élevé au plus ancien. Facultatifs : un
/// dossier incomplet n'empêche jamais d'enregistrer l'agent.
class StaffDiplomasStep extends StatelessWidget {
  final StaffAgentState state;
  final ValueChanged<StaffMemberDraft Function(StaffMemberDraft)> onChanged;

  const StaffDiplomasStep({
    super.key,
    required this.state,
    required this.onChanged,
  });

  static const StaffDiploma _blank = StaffDiploma(level: '', title: '');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final readOnly = !state.isEditable;
    final diplomas = state.draft.diplomas;
    final rows = diplomas.isEmpty && !readOnly ? const [_blank] : diplomas;
    final error = StaffFieldMessages.forField(
      l10n,
      state.visibleErrors,
      StaffField.diplomas,
    );

    void replace(int index, StaffDiploma diploma) => onChanged((d) {
      final next = [
        ...(d.diplomas.isEmpty ? const [_blank] : d.diplomas),
      ];
      next[index] = diploma;
      return d.copyWith(diplomas: next);
    });

    return StaffFormBlock(
      title: l10n.staffBlockDiplomas,
      subtitle: state.mode == StaffAgentMode.create
          ? l10n.staffBlockDiplomasCreateHint
          : l10n.staffBlockDiplomasHint,
      icon: Icons.school_outlined,
      color: StaffStepStyle.of(3).color,
      children: [
        if (error != null) EteeloNotice.error(error),
        if (rows.isEmpty)
          Text(
            l10n.staffDiplomasNone,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMutedAa,
            ),
          ),
        for (final (index, diploma) in rows.indexed)
          _DiplomaRow(
            diploma: diploma,
            readOnly: readOnly,
            canRemove: rows.length > 1,
            onChanged: (value) => replace(index, value),
            onRemove: () => onChanged(
              (d) => d.copyWith(
                diplomas: [
                  for (final (i, item) in d.diplomas.indexed)
                    if (i != index) item,
                ],
              ),
            ),
          ),
        if (!readOnly)
          Align(
            alignment: Alignment.centerLeft,
            child: EteeloButton.secondary(
              label: l10n.staffDiplomaAdd,
              icon: Icons.add,
              fullWidth: false,
              onPressed: () => onChanged(
                (d) => d.copyWith(
                  diplomas: [
                    ...(d.diplomas.isEmpty ? const [_blank] : d.diplomas),
                    _blank,
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiplomaRow extends StatelessWidget {
  final StaffDiploma diploma;
  final bool readOnly;
  final bool canRemove;
  final ValueChanged<StaffDiploma> onChanged;
  final VoidCallback onRemove;

  const _DiplomaRow({
    required this.diploma,
    required this.readOnly,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  StaffDiploma _with({
    String? level,
    String? title,
    String? institution,
    int? Function()? year,
  }) => StaffDiploma(
    level: level ?? diploma.level,
    title: title ?? diploma.title,
    institution: institution ?? diploma.institution,
    graduationYear: year == null ? diploma.graduationYear : year(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final levels = [
      if (diploma.level.isNotEmpty &&
          !StaffJobCatalog.diplomaLevels.contains(diploma.level))
        diploma.level,
      ...StaffJobCatalog.diplomaLevels,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StaffFieldRow(
            children: [
              EteeloSelectInput<String>(
                label: l10n.staffFieldDiplomaLevel,
                readOnly: readOnly,
                value: diploma.level.isEmpty ? null : diploma.level,
                items: [
                  for (final level in levels)
                    EteeloSelectItem(value: level, label: level),
                ],
                onChanged: (v) => onChanged(_with(level: v ?? '')),
              ),
              StaffSyncedTextInput(
                value: diploma.title,
                label: l10n.staffFieldDiplomaTitle,
                readOnly: readOnly,
                onChanged: (v) => onChanged(_with(title: v)),
              ),
              StaffSyncedTextInput(
                value: diploma.institution ?? '',
                label: l10n.staffFieldDiplomaInstitution,
                readOnly: readOnly,
                onChanged: (v) => onChanged(_with(institution: v)),
              ),
              StaffSyncedTextInput(
                value: diploma.graduationYear?.toString() ?? '',
                label: l10n.staffFieldDiplomaYear,
                readOnly: readOnly,
                keyboardType: EteeloTextInputType.number,
                onChanged: (v) =>
                    onChanged(_with(year: () => int.tryParse(v.trim()))),
              ),
            ],
          ),
        ),
        if (!readOnly)
          IconButton(
            tooltip: l10n.staffDiplomaRemove,
            onPressed: canRemove ? onRemove : null,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}
