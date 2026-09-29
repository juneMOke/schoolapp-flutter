import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';

/// La teinte d'un statut de pointage, réutilisée partout où il s'affiche :
/// carte, ligne, puce de filtre, calendrier, pastille.
class StaffAttendanceTone {
  /// Teinte pleine (médaillon, bordure, segment actif).
  final Color color;

  /// Voile de fond.
  final Color soft;
  final Color border;

  /// Encre d'un texte posé sur [soft].
  final Color ink;
  final IconData icon;

  const StaffAttendanceTone._(
    this.color,
    this.soft,
    this.border,
    this.ink,
    this.icon,
  );

  static const StaffAttendanceTone _none = StaffAttendanceTone._(
    AppColors.staffAttendanceNone,
    AppColors.staffAttendanceNoneSoft,
    AppColors.staffAttendanceNoneBorder,
    AppColors.staffAttendanceNoneInk,
    Icons.back_hand_outlined,
  );
  static const StaffAttendanceTone _present = StaffAttendanceTone._(
    AppColors.staffAttendancePresent,
    AppColors.staffAttendancePresentSoft,
    AppColors.staffAttendancePresentBorder,
    AppColors.staffAttendancePresentInk,
    Icons.check_circle_outline,
  );
  static const StaffAttendanceTone _late = StaffAttendanceTone._(
    AppColors.staffAttendanceLate,
    AppColors.staffAttendanceLateSoft,
    AppColors.staffAttendanceLateBorder,
    AppColors.staffAttendanceLateInk,
    Icons.schedule,
  );
  static const StaffAttendanceTone _absent = StaffAttendanceTone._(
    AppColors.staffAttendanceAbsent,
    AppColors.staffAttendanceAbsentSoft,
    AppColors.staffAttendanceAbsentBorder,
    AppColors.staffAttendanceAbsentInk,
    Icons.cancel_outlined,
  );

  static StaffAttendanceTone of(StaffAttendanceStatus status) =>
      switch (status) {
        StaffAttendanceStatus.none => _none,
        StaffAttendanceStatus.present => _present,
        StaffAttendanceStatus.late => _late,
        StaffAttendanceStatus.absent => _absent,
      };
}
