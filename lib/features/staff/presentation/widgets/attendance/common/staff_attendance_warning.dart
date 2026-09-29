import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_notice.dart';

/// Un bandeau du module RH ([StaffNotice]) dans la teinte d'un statut de
/// pointage : ambre (retard) pour ce qui reste à faire, gris (à pointer) pour
/// ce qui est simplement dit, rouge (absent) pour l'irréversible.
class StaffAttendanceWarning extends StatelessWidget {
  final String message;
  final IconData icon;
  final StaffAttendanceStatus tone;

  const StaffAttendanceWarning({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.tone = StaffAttendanceStatus.late,
  });

  @override
  Widget build(BuildContext context) {
    final colors = StaffAttendanceTone.of(tone);
    return StaffNotice.tinted(
      message: message,
      icon: icon,
      ink: colors.ink,
      background: colors.soft,
      border: colors.border,
    );
  }
}
