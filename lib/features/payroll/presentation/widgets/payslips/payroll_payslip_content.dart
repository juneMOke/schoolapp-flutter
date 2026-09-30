import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
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
  final String legalNote;
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
      deductions: [
        for (final deduction in line.advances)
          if (deduction.dueInCents > 0)
            (
              label: _advanceLabel(
                l10n,
                advances[deduction.advanceId],
                deduction.rank,
                deduction.installments,
              ),
              value: '− ${money(deduction.takenInCents)}',
              note: deduction.carriedInCents > 0
                  ? l10n.payrollPayslipCarried(money(deduction.carriedInCents))
                  : null,
            ),
      ],
      net: (
        label: l10n.payrollPayslipNet,
        value: money(line.netInCents),
        note: null,
      ),
      legalNote: l10n.payrollPayslipNoLegal,
      attendance: l10n.payrollPayslipAttendance(
        PayrollLabels.month(context, line.attendanceMonth ?? view.month),
        line.attendance.unjustifiedAbsences,
        line.attendance.justifiedAbsences,
        line.attendance.lates,
        line.attendance.lateMinutes,
      ),
      payment: l10n.payrollPayslipPayment(
        _payment(context, view.disbursements[line.staffMemberId]),
      ),
      signatures: [
        l10n.payrollPayslipSignAgent,
        l10n.payrollPayslipSignBursar,
        l10n.payrollPayslipSignHead,
      ],
    );
  }

  static String _advanceLabel(
    AppLocalizations l10n,
    SalaryAdvance? advance,
    int rank,
    int installments,
  ) {
    final count = installments > 0 ? installments : advance?.installments ?? 1;
    final label = l10n.payrollPayslipAdvance(rank, count);
    return advance == null
        ? label
        : '$label · ${PayrollLabels.reason(l10n, advance.reason)}';
  }

  /// Le mode et sa preuve, ou « À verser ».
  static String _payment(BuildContext context, PayrollDisbursement? paid) {
    final l10n = AppLocalizations.of(context)!;
    if (paid == null) return l10n.payrollToPay;
    final mode = PayrollLabels.mode(l10n, paid.mode);
    final proof = switch (paid.mode) {
      PayoutMode.cash => paid.signedRegister ? l10n.payrollPaySigned : null,
      PayoutMode.mobileMoney || PayoutMode.bank => paid.reference,
    };
    return [
      mode,
      MoneyFormat.format(paid.amount),
      ?proof,
      PayrollLabels.day(context, paid.paidAt),
    ].join(' · ');
  }
}
