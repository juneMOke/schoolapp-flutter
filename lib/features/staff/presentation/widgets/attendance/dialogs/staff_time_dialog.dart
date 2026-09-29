import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_clock_time.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_attendance_rules.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_clock_input_formatter.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/dialogs/staff_arrival_preview.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale d'heure : une heure, ou l'effacement du départ.
class StaffTimeChoice {
  final StaffClockTime? time;

  const StaffTimeChoice(this.time);
}

/// Un raccourci d'heure : un libellé et l'heure qu'il pose.
class StaffTimeShortcut {
  final String label;
  final StaffClockTime time;

  const StaffTimeShortcut(this.label, this.time);
}

/// Saisie de l'heure d'arrivée ou de départ. Pour l'arrivée, [settings]
/// donne l'aperçu du classement (présent ou en retard) avant d'enregistrer.
class StaffTimeDialog extends StatefulWidget {
  final String title;
  final StaffClockTime? initial;
  final List<StaffTimeShortcut> shortcuts;

  /// Réglages du classement : aperçu seulement pour l'arrivée.
  final StaffAttendanceSettings? settings;

  /// Propose « Effacer » (un départ existant).
  final bool canClear;

  const StaffTimeDialog({
    super.key,
    required this.title,
    required this.shortcuts,
    this.initial,
    this.settings,
    this.canClear = false,
  });

  @override
  State<StaffTimeDialog> createState() => _StaffTimeDialogState();
}

class _StaffTimeDialogState extends State<StaffTimeDialog> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initial?.wire ?? '',
  );

  StaffClockTime? get _time => StaffClockTime.tryParse(_field.text);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _pick(StaffClockTime time) => setState(() => _field.text = time.wire);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final time = _time;
    final settings = widget.settings;
    return StaffAttendanceDialog(
      title: widget.title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EteeloTextInput(
            controller: _field,
            label: l10n.staffAttendanceTimeField,
            placeholder: '07:30',
            keyboardType: EteeloTextInputType.number,
            capitalization: EteeloTextCapitalization.none,
            inputFormatters: const [StaffClockInputFormatter()],
            errorText: _field.text.length == 5 && time == null
                ? l10n.staffAttendanceTimeInvalid
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final shortcut in widget.shortcuts)
                EteeloButton.secondary(
                  label: shortcut.label,
                  onPressed: () => _pick(shortcut.time),
                  fullWidth: false,
                ),
            ],
          ),
          if (settings != null && time != null) ...[
            const SizedBox(height: AppSpacing.lg),
            StaffArrivalPreview(
              result: StaffAttendanceRules(settings).classify(time),
              settings: settings,
            ),
          ],
        ],
      ),
      leading: widget.canClear
          ? EteeloButton.ghost(
              label: l10n.staffAttendanceTimeClear,
              icon: Icons.backspace_outlined,
              onPressed: () =>
                  Navigator.of(context).pop(const StaffTimeChoice(null)),
              fullWidth: false,
            )
          : null,
      actions: [
        EteeloButton.ghost(
          label: l10n.staffAttendanceCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.staffAttendanceSave,
          icon: Icons.check,
          onPressed: time == null
              ? null
              : () => Navigator.of(context).pop(StaffTimeChoice(time)),
          fullWidth: false,
        ),
      ],
    );
  }
}
