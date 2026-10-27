import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_settlement.dart';
import 'package:school_app_flutter/features/payroll/presentation/helpers/payroll_tone.dart';
import 'package:school_app_flutter/features/payroll/presentation/widgets/common/payroll_tone_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Où en est le règlement d'un salaire validé : non payé, partiel, différé,
/// soldé — au voile de son sens.
class PayrollSettlementPill extends StatelessWidget {
  final PayrollSettlementStatus status;

  const PayrollSettlementPill({super.key, required this.status});

  static PayrollTone toneOf(PayrollSettlementStatus status) => switch (status) {
    PayrollSettlementStatus.unpaid => PayrollTone.alert,
    PayrollSettlementStatus.partial ||
    PayrollSettlementStatus.deferred => PayrollTone.submitted,
    PayrollSettlementStatus.settled => PayrollTone.paid,
    PayrollSettlementStatus.nothingToPay => PayrollTone.draft,
  };

  static String labelOf(
    AppLocalizations l10n,
    PayrollSettlementStatus status,
  ) => switch (status) {
    PayrollSettlementStatus.unpaid => l10n.payrollSettlementUnpaid,
    PayrollSettlementStatus.partial => l10n.payrollSettlementPartial,
    PayrollSettlementStatus.deferred => l10n.payrollSettlementDeferred,
    PayrollSettlementStatus.settled => l10n.payrollSettlementSettled,
    PayrollSettlementStatus.nothingToPay => l10n.payrollSettlementNothing,
  };

  @override
  Widget build(BuildContext context) => PayrollTonePill(
    label: labelOf(AppLocalizations.of(context)!, status),
    tone: toneOf(status),
  );
}
