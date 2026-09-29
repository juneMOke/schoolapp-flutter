import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_draft_validator.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_field_messages.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_step_style.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_day_field.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_form_block.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_phone_field.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_synced_text_input.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_identity_lines.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member_draft.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Étape 1 · Identité & contacts.
class StaffIdentityStep extends StatelessWidget {
  final StaffAgentState state;
  final ValueChanged<StaffMemberDraft Function(StaffMemberDraft)> onChanged;

  const StaffIdentityStep({
    super.key,
    required this.state,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;
    final readOnly = !state.isEditable;
    final errors = state.visibleErrors;
    String? error(StaffField field) =>
        StaffFieldMessages.forField(l10n, errors, field);
    final style = StaffStepStyle.of(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffFormBlock(
          title: l10n.staffBlockIdentification,
          subtitle: l10n.staffBlockIdentificationHint,
          icon: Icons.badge_outlined,
          color: style.color,
          children: [
            StaffFieldRow(
              children: [
                StaffSyncedTextInput(
                  value: draft.lastName,
                  label: l10n.staffFieldLastName,
                  required: !readOnly,
                  readOnly: readOnly,
                  errorText: error(StaffField.lastName),
                  onChanged: (v) => onChanged((d) => d.copyWith(lastName: v)),
                ),
                StaffSyncedTextInput(
                  value: draft.middleName,
                  label: l10n.staffFieldMiddleName,
                  required: !readOnly,
                  readOnly: readOnly,
                  errorText: error(StaffField.middleName),
                  onChanged: (v) => onChanged((d) => d.copyWith(middleName: v)),
                ),
                StaffSyncedTextInput(
                  value: draft.firstName,
                  label: l10n.staffFieldFirstName,
                  required: !readOnly,
                  readOnly: readOnly,
                  errorText: error(StaffField.firstName),
                  onChanged: (v) => onChanged((d) => d.copyWith(firstName: v)),
                ),
              ],
            ),
            if (state.mode == StaffAgentMode.create &&
                state.validation.possibleDuplicate)
              StaffNotice.warning(l10n.staffDuplicateWarning),
            StaffFieldRow(
              children: [
                _SexField(
                  value: draft.sex,
                  readOnly: readOnly,
                  error: error(StaffField.sex),
                  onChanged: (v) => onChanged((d) => d.copyWith(sex: () => v)),
                ),
                StaffDayField(
                  label: l10n.staffFieldBirthDate,
                  value: draft.birthDate,
                  readOnly: readOnly,
                  errorText: error(StaffField.birthDate),
                  lastDate: DateTime.now(),
                  onChanged: (v) =>
                      onChanged((d) => d.copyWith(birthDate: () => v)),
                ),
                if (state.mode != StaffAgentMode.create)
                  _StaffNumberField(staffNumber: state.member?.staffNumber),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StaffFormBlock(
          title: l10n.staffBlockContacts,
          icon: Icons.call_outlined,
          color: style.color,
          children: [
            StaffFieldRow(
              children: [
                StaffPhoneField(
                  value: draft.phone,
                  label: l10n.staffFieldPhone,
                  readOnly: readOnly,
                  errorText: error(StaffField.phone),
                  onChanged: (v) => onChanged((d) => d.copyWith(phone: v)),
                ),
                StaffSyncedTextInput(
                  value: draft.email,
                  label: l10n.staffFieldEmail,
                  readOnly: readOnly,
                  keyboardType: EteeloTextInputType.email,
                  errorText: error(StaffField.email),
                  onChanged: (v) => onChanged((d) => d.copyWith(email: v)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _SexField extends StatelessWidget {
  final StaffSex? value;
  final bool readOnly;
  final String? error;
  final ValueChanged<StaffSex> onChanged;

  const _SexField({
    required this.value,
    required this.readOnly,
    required this.error,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.staffFieldSex, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        SegmentedTabFilter<String>(
          semanticsLabel: l10n.staffFieldSex,
          enabled: !readOnly,
          selected: value?.wire ?? '',
          onSelected: (wire) {
            final sex = StaffSex.fromWire(wire);
            if (sex != null) onChanged(sex);
          },
          options: [
            SegmentedTabOption(label: l10n.staffSexMale, value: 'M'),
            SegmentedTabOption(label: l10n.staffSexFemale, value: 'F'),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              error!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

class _StaffNumberField extends StatelessWidget {
  final String? staffNumber;

  const _StaffNumberField({required this.staffNumber});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        AppLocalizations.of(context)!.staffFieldStaffNumber,
        style: AppTypography.labelMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      StaffNumberText(staffNumber: staffNumber),
    ],
  );
}
