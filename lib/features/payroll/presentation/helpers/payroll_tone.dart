import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/agent/staff_notice.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_card_tabs.dart';

/// La teinte d'un statut de paie : brouillon gris, soumise ambre, validée
/// bleu profond, versée vert — les trois premières empruntées au Pointage.
class PayrollTone {
  final Color color;
  final Color soft;
  final Color ink;

  const PayrollTone._(this.color, this.soft, this.ink);

  static const PayrollTone draft = PayrollTone._(
    AppColors.staffAttendanceNone,
    AppColors.staffAttendanceNoneSoft,
    AppColors.staffAttendanceNoneInk,
  );
  static const PayrollTone submitted = PayrollTone._(
    AppColors.staffAttendanceLate,
    AppColors.staffAttendanceLateSoft,
    AppColors.staffAttendanceLateInk,
  );
  static const PayrollTone validated = PayrollTone._(
    AppColors.payrollValidated,
    AppColors.payrollValidatedSoft,
    AppColors.payrollValidatedInk,
  );
  static const PayrollTone paid = PayrollTone._(
    AppColors.staffAttendancePresent,
    AppColors.staffAttendancePresentSoft,
    AppColors.staffAttendancePresentInk,
  );

  /// Une retenue, un refus, une absence signalée.
  static const PayrollTone alert = PayrollTone._(
    AppColors.staffAttendanceAbsent,
    AppColors.staffAttendanceAbsentSoft,
    AppColors.staffAttendanceAbsentInk,
  );

  /// Un geste en vol se lit dans la teinte de là où il va.
  static PayrollTone of(PayrollPhase phase) => switch (phase) {
    PayrollPhase.draft || PayrollPhase.returning => draft,
    PayrollPhase.submitted || PayrollPhase.submitting => submitted,
    PayrollPhase.validated ||
    PayrollPhase.validating ||
    PayrollPhase.reopening => validated,
    PayrollPhase.paid => paid,
  };

  StaffTabBadge badge(String label) => (label: label, soft: soft, ink: ink);

  /// Un bandeau d'une ligne à cette teinte.
  Widget notice(String message, {IconData icon = Icons.info_outline}) =>
      StaffNotice.tinted(
        message: message,
        icon: icon,
        ink: ink,
        background: soft,
      );
}
