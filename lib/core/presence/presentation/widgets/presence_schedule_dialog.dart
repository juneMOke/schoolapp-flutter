import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/clock_time.dart';
import 'package:school_app_flutter/core/presence/presentation/clock_input_formatter.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'horaire du pointage et de l'appel : début des cours et tolérance, avec
/// la phrase de règle recalculée. Rend le nouvel horaire, ou `null`.
class PresenceScheduleDialog extends StatefulWidget {
  final PresenceSchedule schedule;

  /// Sans le droit de régler (`hr.attendance.manage`), l'horaire se lit sans
  /// se modifier.
  final bool editable;

  const PresenceScheduleDialog({
    super.key,
    required this.schedule,
    required this.editable,
  });

  @override
  State<PresenceScheduleDialog> createState() =>
      _PresenceScheduleDialogState();
}

class _PresenceScheduleDialogState
    extends State<PresenceScheduleDialog> {
  late final TextEditingController _start = TextEditingController(
    text: widget.schedule.start.wire,
  );
  late int _tolerance = widget.schedule.toleranceMinutes;

  @override
  void dispose() {
    _start.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parsed = ClockTime.tryParse(_start.text);
    final tooLate =
        parsed != null && parsed.isAfter(PresenceSchedule.latestStart);
    final start = tooLate ? null : parsed;
    final draft = start == null
        ? null
        : PresenceSchedule(start: start, toleranceMinutes: _tolerance);
    return EteeloFormDialog(
      title: l10n.presenceMarkSettingsTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloTextInput(
            controller: _start,
            label: l10n.presenceMarkSettingsStart,
            readOnly: !widget.editable,
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            inputFormatters: const [ClockInputFormatter()],
            errorText: tooLate
                ? l10n.presenceMarkStartTooLate(
                    PresenceSchedule.latestStart.wire,
                  )
                : _start.text.length == 5 && start == null
                ? l10n.presenceMarkTimeInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.presenceMarkSettingsTolerance,
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final minutes in PresenceSchedule.tolerances)
                EteeloFilterChip(
                  label: l10n.presenceMarkMinutes(minutes),
                  selected: minutes == _tolerance,
                  color: AppColors.bleuArdoise,
                  soft: AppColors.bleuArdoiseSoft,
                  ink: AppColors.bleuArdoise,
                  onTap: widget.editable
                      ? () => setState(() => _tolerance = minutes)
                      : null,
                ),
            ],
          ),
          if (draft != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.presenceMarkSettingsRule(
                draft.lastOnTime.wire,
                draft.start.wire,
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.presenceMarkSettingsComing,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMutedAa,
              ),
            ),
          ],
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: widget.editable
              ? l10n.presenceMarkCancel
              : l10n.presenceMarkDismiss,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        if (widget.editable)
          EteeloButton.primary(
            label: l10n.presenceMarkSave,
            icon: Icons.check,
            onPressed: draft == null || _unchanged(draft)
                ? null
                : () => Navigator.of(context).pop(draft),
            fullWidth: false,
          ),
      ],
    );
  }

  bool _unchanged(PresenceSchedule draft) =>
      draft.start == widget.schedule.start &&
      draft.toleranceMinutes == widget.schedule.toleranceMinutes;
}
