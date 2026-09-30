import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dialog.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_attendance_warning.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/common/staff_count_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que rend la modale du rapport : valider, en marquant ou non les agents
/// encore « à pointer ».
class StaffReportChoice {
  final bool markRemaining;

  const StaffReportChoice({required this.markRemaining});
}

/// Valider le rapport journalier : le résumé, les avertissements, et la case
/// des non pointés (cochée par défaut).
class StaffDayReportDialog extends StatefulWidget {
  final StaffDayRegister register;
  final String dayLabel;

  const StaffDayReportDialog({
    super.key,
    required this.register,
    required this.dayLabel,
  });

  @override
  State<StaffDayReportDialog> createState() => _StaffDayReportDialogState();
}

class _StaffDayReportDialogState extends State<StaffDayReportDialog> {
  bool _markRemaining = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = widget.register;
    // Seuls ceux qu'un contrat couvre ce jour-là sont marqués d'office.
    final unmarked = register.unmarked.length;
    final present =
        register.count(StaffAttendanceStatus.present) +
        (_markRemaining ? unmarked : 0);
    Widget tile(StaffAttendanceStatus status, int value) => Expanded(
      child: StaffCountTile(
        tone: status,
        label: StaffAttendanceLabels.filter(l10n, status),
        value: '$value',
      ),
    );
    return StaffDialog(
      eyebrow: widget.dayLabel,
      title: l10n.staffAttendanceReportTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              tile(StaffAttendanceStatus.present, present),
              const SizedBox(width: AppSpacing.sm),
              tile(
                StaffAttendanceStatus.late,
                register.count(StaffAttendanceStatus.late),
              ),
              const SizedBox(width: AppSpacing.sm),
              tile(
                StaffAttendanceStatus.absent,
                register.count(StaffAttendanceStatus.absent),
              ),
            ],
          ),
          if (unmarked > 0) ...[
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _markRemaining,
              onChanged: (value) =>
                  setState(() => _markRemaining = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.staffAttendanceReportMarkRemaining(unmarked)),
              subtitle: _markRemaining
                  ? null
                  : Text(l10n.staffAttendanceReportUnmarkedReminder),
            ),
          ],
          if (register.toJustify > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            StaffAttendanceWarning(
              icon: Icons.warning_amber_rounded,
              message: l10n.staffAttendanceReportUnjustified(
                register.toJustify,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          StaffAttendanceWarning(
            icon: Icons.lock_outline,
            tone: StaffAttendanceStatus.none,
            message: l10n.staffAttendanceReportLock,
          ),
        ],
      ),
      actions: [
        EteeloButton.ghost(
          label: l10n.staffAttendanceCancel,
          onPressed: () => Navigator.of(context).pop(),
          fullWidth: false,
        ),
        EteeloButton.primary(
          label: l10n.staffAttendanceReportConfirm,
          icon: Icons.task_alt,
          onPressed: () => Navigator.of(context).pop(
            StaffReportChoice(markRemaining: _markRemaining && unmarked > 0),
          ),
          fullWidth: false,
        ),
      ],
    );
  }
}
