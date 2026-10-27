import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tone_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le statut d'une avance au mois affiché : refusée, annulée, soldée, à
/// venir, reportée, ou l'échéance en cours.
class PayrollAdvanceStatusPill extends StatelessWidget {
  final SalaryAdvanceStatus status;
  final SalaryAdvance advance;

  const PayrollAdvanceStatusPill({
    super.key,
    required this.status,
    required this.advance,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, tone) = switch (status.phase) {
      SalaryAdvancePhase.refused => (
        l10n.payrollAdvanceStatusRefused,
        PayrollTone.alert,
      ),
      SalaryAdvancePhase.cancelled => (
        l10n.payrollAdvanceStatusCancelled,
        PayrollTone.draft,
      ),
      SalaryAdvancePhase.settled => (
        l10n.payrollAdvanceStatusSettled,
        PayrollTone.paid,
      ),
      SalaryAdvancePhase.upcoming => (
        l10n.payrollAdvanceStatusUpcoming,
        PayrollTone.validated,
      ),
      SalaryAdvancePhase.carried => (
        l10n.payrollAdvanceStatusCarried,
        PayrollTone.alert,
      ),
      SalaryAdvancePhase.running => (
        l10n.payrollAdvanceStatusInstallment(status.rank, advance.installments),
        PayrollTone.submitted,
      ),
    };
    return PayrollTonePill(label: label, tone: tone);
  }
}
