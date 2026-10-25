import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_statement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_rows.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne libellé → montant (ou valeur) du bulletin.
typedef PayslipRow = ({String label, String value, String? note});

/// Le bulletin d'un agent, **déjà mis en mots** : l'écran et le PDF le
/// rendent tous deux, sans refaire un seul calcul ni un seul libellé — deux
/// rendus d'une même source ne peuvent pas diverger.
class PayrollPayslipContent {
  final String schoolName;
  final String? schoolAddress;
  final String title;
  final String monthLabel;

  /// Bandeau « Provisoire » tant que la paie n'est pas validée.
  final String? banner;
  final List<PayslipRow> identity;
  final List<PayslipRow> gains;
  final PayslipRow gross;
  final List<PayslipRow> deductions;
  final PayslipRow net;

  /// « Paie nette, sans retenue légale » — `null` dès qu'un IPR ou une CNSS
  /// est retenu (v2).
  final String? legalNote;
  final String attendance;
  final String payment;
  final List<String> signatures;

  const PayrollPayslipContent({
    required this.schoolName,
    required this.schoolAddress,
    required this.title,
    required this.monthLabel,
    required this.banner,
    required this.identity,
    required this.gains,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.legalNote,
    required this.attendance,
    required this.payment,
    required this.signatures,
  });

  factory PayrollPayslipContent.of(
    BuildContext context, {
    required PayrollSnapshot snapshot,
    required PayrollMonthView view,
    required PayrollLine line,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final member = snapshot.member(line.staffMemberId);
    String money(int cents) => PayrollLabels.money(cents, line.currency);
    final school = snapshot.school;
    final advances = {for (final a in snapshot.advances) a.id: a};
    final contractFrom = line.contractFrom;
    final kind = StaffLabels.contract(l10n, line.contractKind);
    final settlement = view.settlementOf(line);
    return PayrollPayslipContent(
      schoolName: school?.name ?? '',
      schoolAddress: [
        school?.address,
        school?.locality,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · '),
      title: l10n.payrollPayslipTitle,
      monthLabel: PayrollLabels.month(context, view.month),
      banner: line.frozen ? null : l10n.payrollPayslipProvisional,
      identity: [
        (
          label: l10n.payrollColAgent,
          value: member?.fullName ?? line.staffMemberId,
          note: null,
        ),
        (
          label: l10n.payrollPayslipStaffNumber,
          value: member?.staffNumber ?? '—',
          note: null,
        ),
        (
          label: l10n.payrollPayslipJob,
          value: member?.jobTitle ?? '—',
          note: null,
        ),
        (
          label: l10n.payrollPayslipGrade,
          value: PayrollStatement.gradeOf(member) ?? '—',
          note: null,
        ),
        if (line.deductions.workDaysDivisor case final divisor?)
          (
            label: l10n.payrollPayslipWorkedDays,
            value: l10n.payrollPayslipWorkedDaysValue(
              line.deductions.workedDays ?? divisor,
              divisor,
            ),
            note: null,
          ),
        (
          label: l10n.payrollPayslipContract,
          value: contractFrom == null
              ? kind
              : l10n.payrollPayslipContractFrom(
                  kind,
                  PayrollLabels.day(context, contractFrom),
                ),
          note: null,
        ),
      ],
      gains: [
        (
          label: l10n.payrollPayslipBase,
          value: money(line.baseInCents),
          note: line.isHourly
              ? l10n.payrollHoursOf(
                  PayrollLabels.hours(l10n, line.baseMinutes ?? 0),
                  PayrollLabels.month(context, line.hoursMonth ?? view.month),
                )
              : null,
        ),
        if (line.overtimeInCents > 0)
          (
            label: l10n.payrollPayslipOvertime(
              PayrollLabels.hours(l10n, line.overtimeMinutes),
              money(line.overtimeRateInCents),
            ),
            value: money(line.overtimeInCents),
            note: null,
          ),
        if (line.allowanceInCents > 0)
          (
            label: l10n.payrollPayslipAllowance(
              line.children,
              money(
                line.children == 0 ? 0 : line.allowanceInCents ~/ line.children,
              ),
            ),
            value: money(line.allowanceInCents),
            note: null,
          ),
      ],
      gross: (
        label: l10n.payrollPayslipGross,
        value: money(line.grossInCents),
        note: null,
      ),
      deductions: PayrollPayslipRows.deductions(context, line, advances),
      net: (
        label: l10n.payrollPayslipNet,
        value: money(line.netInCents),
        note: null,
      ),
      legalNote: line.deductions.iprInCents + line.deductions.cnssInCents > 0
          ? null
          : l10n.payrollPayslipNoLegal,
      attendance:
          (line.deductions.absenceInCents > 0
          ? l10n.payrollPayslipAttendanceDeducted
          : l10n.payrollPayslipAttendance)(
            PayrollLabels.month(context, line.attendanceMonth ?? view.month),
            line.attendance.unjustifiedAbsences,
            line.attendance.justifiedAbsences,
            line.attendance.lates,
            line.attendance.lateMinutes,
          ),
      payment: [
        l10n.payrollPayslipBalance(
          money(line.netInCents),
          money(settlement.paidInCents),
          money(settlement.remainingInCents),
        ),
        l10n.payrollPayslipPayment(
          PayrollPayslipRows.payments(
            context,
            view.disbursements[line.staffMemberId],
          ),
        ),
      ].join('\n'),
      signatures: [
        l10n.payrollPayslipSignAgent,
        l10n.payrollPayslipSignHead,
        l10n.payrollPayslipSignBursar,
      ],
    );
  }
}
