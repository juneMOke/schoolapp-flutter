import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_clock_input_formatter.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les réglages du Pointage : début des cours et tolérance, avec la phrase de
/// règle recalculée. Rend les nouveaux réglages, ou `null`.
class StaffAttendanceSettingsDialog extends StatefulWidget {
  final StaffAttendanceSettings settings;

  /// Sans `hr.attendance.manage`, les réglages se lisent sans se modifier.
  final bool editable;

  const StaffAttendanceSettingsDialog({
    super.key,
    required this.settings,
    required this.editable,
  });

  @override
  State<StaffAttendanceSettingsDialog> createState() =>
      _StaffAttendanceSettingsDialogState();
}

class _StaffAttendanceSettingsDialogState
    extends State<StaffAttendanceSettingsDialog> {
  late final TextEditingController _start = TextEditingController(
    text: widget.settings.start.wire,
  );
  late int _tolerance = widget.settings.toleranceMinutes;

  @override
  void dispose() {
    _start.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final start = StaffClockTime.tryParse(_start.text);
    final draft = start == null
        ? null
        : StaffAttendanceSettings(start: start, toleranceMinutes: _tolerance);
    return StaffAttendanceDialog(
      title: l10n.staffAttendanceSettingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloTextInput(
            controller: _start,
            label: l10n.staffAttendanceSettingsStart,
            readOnly: !widget.editable,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            inputFormatters: const [StaffClockInputFormatter()],
            errorText: _start.text.length == 5 && start == null
                ? l10n.staffAttendanceTimeInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.staffAttendanceSettingsTolerance,
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final minutes in StaffAttendanceSettings.tolerances)
                StaffFilterChip(
                  label: l10n.staffAttendanceMinutes(minutes),
                  selected: minutes == _tolerance,
                  color: AppColors.bleuArdoise,
                  soft: AppColors.bleuArdoiseSoft,
                  ink: AppColors.bleuArdoise,
                  onTap: widget.editable
                      ? () => setState(() => _tolerance = minutes)
                      : () {},
                ),
            ],
          ),
          if (draft != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.staffAttendanceSettingsRule(
                draft.lastOnTime.wire,
                draft.start.wire,
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.staffAttendanceSettingsComing,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.staffAttendanceCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        if (widget.editable)
          EteeloButton.primary(
            label: l10n.staffAttendanceSave,
            icon: Icons.check,
            onPressed: draft == null || draft == widget.settings
                ? null
                : () => Navigator.of(context).pop(draft),
            fullWidth: false,
          ),
      ],
    );
  }
}
