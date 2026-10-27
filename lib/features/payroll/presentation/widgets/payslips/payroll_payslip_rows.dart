import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_labels.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/payslips/payroll_payslip_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les lignes calculées du bulletin : les retenues du modèle et les
/// versements reçus — mises en mots une fois, pour l'écran et le PDF.
abstract final class PayrollPayslipRows {
  /// Le montant d'une retenue nulle : la ligne reste listée (modèle papier).
  static const none = '—';

  /// Le rang de l'absence parmi [deductions] — le détail du calcul y ajoute
  /// sa formule.
  static const absenceIndex = 1;

  /// Les cinq retenues du modèle des écoles, **toujours** listées dans
  /// l'ordre du papier — « — » quand elles sont nulles —, puis leur total :
  /// chaque montant rangé par le calcul dans sa ligne.
  static List<PayslipRow> deductions(
    BuildContext context,
    PayrollLine line,
    Map<String, SalaryAdvance> advances,
  ) {
    final l10n = AppLocalizations.of(context)!;
    String money(int cents) =>
        cents == 0 ? none : '− ${PayrollLabels.money(cents, line.currency)}';
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
            ? none
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
  static String payments(
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
