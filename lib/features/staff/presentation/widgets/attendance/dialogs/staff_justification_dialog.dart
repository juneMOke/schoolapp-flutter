import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_record.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/filters/staff_filter_chip.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale de justification : une justification, ou son
/// retrait ([justification] `null`).
class StaffJustificationChoice {
  final StaffAttendanceJustification? justification;

  const StaffJustificationChoice(this.justification);
}

/// Justifier un retard ou une absence : un motif (requis), une précision.
/// La pièce jointe est reportée en V1.1 : ni Numériser, ni Importer.
class StaffJustificationDialog extends StatefulWidget {
  final String name;

  /// Le pointage à justifier (retard ou absence).
  final StaffAttendanceRecord record;

  /// Le jour, en toutes lettres, pour le surtitre.
  final String dayLabel;

  const StaffJustificationDialog({
    super.key,
    required this.name,
    required this.record,
    required this.dayLabel,
  });

  @override
  State<StaffJustificationDialog> createState() =>
      _StaffJustificationDialogState();
}

class _StaffJustificationDialogState extends State<StaffJustificationDialog> {
  late StaffAbsenceReason? _reason = widget.record.justification?.reason;
  late final TextEditingController _note = TextEditingController(
    text: widget.record.justification?.note ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _eyebrow(AppLocalizations l10n) {
    final record = widget.record;
    return [
      StaffAttendanceLabels.status(l10n, record.status),
      if (record.status == StaffAttendanceStatus.late)
        '+${l10n.staffAttendanceMinutes(record.lateMinutes)}',
      widget.dayLabel,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = StaffAttendanceTone.of(widget.record.status);
    final reason = _reason;
    return StaffAttendanceDialog(
      eyebrow: _eyebrow(l10n),
      title: l10n.staffAttendanceJustifyTitle(widget.name),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${l10n.staffAttendanceReasonLabel} *',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final value in StaffAbsenceReason.values)
                StaffFilterChip(
                  label: StaffAttendanceLabels.reason(l10n, value),
                  selected: value == reason,
                  color: tone.color,
                  soft: tone.soft,
                  ink: tone.ink,
                  onTap: () => setState(() => _reason = value),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          EteeloTextInput(
            controller: _note,
            label: l10n.staffAttendanceNoteLabel,
            placeholder: l10n.staffAttendanceNotePlaceholder,
            keyboardType: EteeloTextInputType.multiline,
            minLines: 2,
            maxLines: 4,
            // Coupé à la frappe, en caractères entiers : jamais de
            // troncature silencieuse au milieu d'un emoji.
            inputFormatters: [
              LengthLimitingTextInputFormatter(
                StaffAttendanceJustification.maxNoteLength,
              ),
            ],
          ),
        ],
      ),
      leading: widget.record.isJustified
          ? EteeloButton.ghost(
              label: l10n.staffAttendanceRemoveJustification,
              icon: Icons.delete_outline,
              onPressed: () => Navigator.of(
                context,
              ).pop(const StaffJustificationChoice(null)),
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
          onPressed: reason == null ? null : () => _save(reason),
          fullWidth: false,
        ),
      ],
    );
  }

  void _save(StaffAbsenceReason reason) {
    final note = _note.text.trim();
    Navigator.of(context).pop(
      StaffJustificationChoice(
        StaffAttendanceJustification(
          reason: reason,
          note: note.isEmpty ? null : note,
        ),
      ),
    );
  }
}
