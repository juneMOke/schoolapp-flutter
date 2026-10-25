import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_statement.dart';
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
      deductions: _deductions(context, line, advances),
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
          _payments(context, view.disbursements[line.staffMemberId]),
        ),
      ].join('\n'),
      signatures: [
        l10n.payrollPayslipSignAgent,
        l10n.payrollPayslipSignHead,
        l10n.payrollPayslipSignBursar,
      ],
    );
  }

  /// Les cinq retenues du modèle des écoles, **toujours** listées dans
  /// l'ordre du papier — « — » quand elles sont nulles —, puis leur total :
  /// chaque montant rangé par le calcul dans sa ligne.
  static List<PayslipRow> _deductions(
    BuildContext context,
    PayrollLine line,
    Map<String, SalaryAdvance> advances,
  ) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) =>
        cents == 0 ? '—' : '− ${PayrollLabels.money(cents, line.currency)}';
    final d = line.deductions;
    int taken(bool loan) => line.advances
        .where((a) => (a.installments > 1) == loan)
        .fold(0, (sum, a) => sum + a.takenInCents);
    String? notes(bool loan) {
      final parts = [
        for (final a in line.advances)
          if ((a.installments > 1) == loan && a.dueInCents > 0) ...[
            _advanceLabel(l10n, advances[a.advanceId], a.rank, a.installments),
            if (a.carriedInCents > 0)
              l10n.payrollPayslipCarried(
                PayrollLabels.money(a.carriedInCents, line.currency),
              ),
          ],
      ];
      return parts.isEmpty ? null : parts.join(' · ');
    }

    final total = d.totalInCents + line.advanceInCents;
    return [
      (
        label: l10n.payrollPayslipIprCnss,
        value: money(d.iprInCents + d.cnssInCents),
        note: null,
      ),
      (
        label: l10n.payrollPayslipAbsence,
        value: money(d.absenceInCents),
        note: d.absenceInCents > 0 && d.absentDays != null
            ? l10n.payrollPayslipAbsenceDays(d.absentDays!)
            : null,
      ),
      (
        label: l10n.payrollPayslipSalaryAdvance,
        value: money(taken(false)),
        note: notes(false),
      ),
      (
        label: l10n.payrollPayslipLoan,
        value: money(taken(true)),
        note: notes(true),
      ),
      (
        label: l10n.payrollPayslipChildcare,
        value: money(d.childcareInCents),
        note: null,
      ),
      (
        label: l10n.payrollPayslipDeductionsTotal,
        value: total == 0
            ? '—'
            : '− ${PayrollLabels.money(total, line.currency)}',
        note: null,
      ),
    ];
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

  /// Chaque versement reçu — mode, montant, preuve, date —, une ligne
  /// chacun ; « À verser » tant qu'aucun.
  static String _payments(
    BuildContext context,
    List<PayrollDisbursement>? received,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (received == null || received.isEmpty) return l10n.payrollToPay;
    return [for (final paid in received) _payment(context, paid)].join('\n');
  }

  static String _payment(BuildContext context, PayrollDisbursement paid) {
    final l10n = AppLocalizations.of(context)!;
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
