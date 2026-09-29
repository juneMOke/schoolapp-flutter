import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_job_catalog.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_seniority.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_field_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_branches_field.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_day_field.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 3 · Poste : catégorie, fonction (liste dépendante), date d'entrée et,
/// pour un enseignant, les matières qu'il déclare pouvoir tenir.
class StaffJobStep extends StatelessWidget {
  final StaffAgentState state;
  final String today;
  final ValueChanged<StaffMemberDraft Function(StaffMemberDraft)> onChanged;

  const StaffJobStep({
    super.key,
    required this.state,
    required this.today,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;
    final readOnly = !state.isEditable;
    String? error(StaffField field) =>
        StaffFieldMessages.forField(l10n, state.visibleErrors, field);
    final jobs = StaffJobCatalog.jobsFor(
      draft.category,
      current: draft.jobTitle,
    );
    final years = StaffSeniority.yearsAt(draft.entryDate, today);

    return StaffFormBlock(
      title: l10n.staffBlockJob,
      subtitle: l10n.staffBlockJobHint,
      icon: Icons.work_outline,
      color: StaffStepStyle.of(2).color,
      children: [
        StaffFieldRow(
          children: [
            EteeloSelectInput<String>(
              label: l10n.staffFieldCategory,
              required: !readOnly,
              readOnly: readOnly,
              value: draft.category?.wire,
              errorText: error(StaffField.category),
              items: [
                for (final category in StaffCategory.values)
                  EteeloSelectItem(
                    value: category.wire,
                    label: StaffLabels.category(l10n, category),
                  ),
              ],
              // Changer de catégorie vide la fonction : l'ancienne n'est plus
              // dans la liste proposée.
              onChanged: (wire) => onChanged(
                (d) => d.copyWith(
                  category: () => StaffCategory.fromWire(wire),
                  jobTitle: '',
                ),
              ),
            ),
            EteeloSelectInput<String>(
              label: l10n.staffFieldJob,
              required: !readOnly,
              readOnly: readOnly,
              enabled: draft.category != null,
              placeholder: draft.category == null
                  ? l10n.staffPickCategoryFirst
                  : null,
              value: draft.jobTitle.isEmpty ? null : draft.jobTitle,
              errorText: error(StaffField.jobTitle),
              items: [
                for (final job in jobs)
                  EteeloSelectItem(value: job, label: job),
              ],
              onChanged: (v) => onChanged((d) => d.copyWith(jobTitle: v ?? '')),
            ),
            StaffDayField(
              label: l10n.staffFieldEntryDate,
              value: draft.entryDate,
              required: !readOnly,
              readOnly: readOnly,
              errorText: error(StaffField.entryDate),
              onChanged: (v) =>
                  onChanged((d) => d.copyWith(entryDate: () => v)),
            ),
          ],
        ),
        if (readOnly && years != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              l10n.staffSeniority(years),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        if (draft.isTeacher)
          StaffBranchesField(
            branches: draft.branches,
            readOnly: readOnly,
            onChanged: (v) => onChanged((d) => d.copyWith(branches: v)),
          ),
      ],
    );
  }
}
