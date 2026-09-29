import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un mois sans jour de classe : « Vacances — août 2027 ».
class StaffHolidayState extends StatelessWidget {
  final String month;
  final VoidCallback onCurrent;

  const StaffHolidayState({
    super.key,
    required this.month,
    required this.onCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloEmptyResult(
      label: l10n.staffAttendanceHolidayTitle(
        StaffAttendanceLabels.month(MaterialLocalizations.of(context), month),
      ),
      description: l10n.staffAttendanceHolidayMessage,
      medallionIcon: Icons.beach_access_outlined,
      fullWidthCard: true,
      primaryAction: EteeloButton.primary(
        label: l10n.staffAttendanceCurrentMonth,
        icon: Icons.today,
        onPressed: onCurrent,
        fullWidth: false,
      ),
    );
  }
}
