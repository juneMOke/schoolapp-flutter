import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les libellés de la paie, en un seul endroit.
abstract final class PayrollLabels {
  static String money(int cents, String currency) =>
      MoneyFormat.format(Money(cents, currency));

  /// Des montants groupés par devise, une ligne par devise triée par code —
  /// jamais additionnés entre devises. `—` quand il n'y a rien.
  static List<String> perCurrency(Iterable<(int, String)> amounts) {
    final sums = <String, int>{};
    for (final (cents, currency) in amounts) {
      sums[currency] = (sums[currency] ?? 0) + cents;
    }
    final currencies = sums.keys.toList()..sort();
    return currencies.isEmpty
        ? const ['—']
        : [for (final currency in currencies) money(sums[currency]!, currency)];
  }

  /// « octobre 2026 ».
  static String month(BuildContext context, String month) =>
      StaffAttendanceLabels.month(MaterialLocalizations.of(context), month);

  /// « 12 oct. 2026 » depuis un jour ou un instant.
  static String day(BuildContext context, String iso) {
    final date = DateTime.tryParse(iso)?.toLocal();
    return date == null
        ? iso
        : MaterialLocalizations.of(context).formatMediumDate(date);
  }

  /// « 38 h » ou « 3 h 30 ».
  static String hours(AppLocalizations l10n, int minutes) =>
      StaffAttendanceLabels.hours(l10n, minutes);

  static String phase(AppLocalizations l10n, PayrollPhase phase) =>
      switch (phase) {
        PayrollPhase.draft => l10n.payrollPhaseDraft,
        PayrollPhase.submitting => l10n.payrollPhaseSubmitting,
        PayrollPhase.submitted => l10n.payrollPhaseSubmitted,
        PayrollPhase.returning => l10n.payrollPhaseReturning,
        PayrollPhase.validating => l10n.payrollPhaseValidating,
        PayrollPhase.validated => l10n.payrollPhaseValidated,
        PayrollPhase.reopening => l10n.payrollPhaseReopening,
        PayrollPhase.paid => l10n.payrollPhasePaid,
      };

  static String mode(AppLocalizations l10n, PayoutMode mode) => switch (mode) {
    PayoutMode.cash => l10n.payrollModeCash,
    PayoutMode.mobileMoney => l10n.payrollModeMobile,
    PayoutMode.bank => l10n.payrollModeBank,
  };

  static String operator(AppLocalizations l10n, MobileMoneyOperator op) =>
      switch (op) {
        MobileMoneyOperator.mpesa => l10n.payrollOperatorMpesa,
        MobileMoneyOperator.orangeMoney => l10n.payrollOperatorOrange,
        MobileMoneyOperator.airtelMoney => l10n.payrollOperatorAirtel,
      };

  static String reason(AppLocalizations l10n, SalaryAdvanceReason reason) =>
      switch (reason) {
        SalaryAdvanceReason.medical => l10n.payrollReasonMedical,
        SalaryAdvanceReason.schooling => l10n.payrollReasonSchooling,
        SalaryAdvanceReason.rent => l10n.payrollReasonRent,
        SalaryAdvanceReason.bereavement => l10n.payrollReasonBereavement,
        SalaryAdvanceReason.transport => l10n.payrollReasonTransport,
        SalaryAdvanceReason.other => l10n.payrollReasonOther,
      };

  static String rule(
    AppLocalizations l10n,
    PayrollRule rule, {
    String? month,
  }) => switch (rule) {
    PayrollRule.notEditable => l10n.payrollRuleNotEditable,
    PayrollRule.wrongPhase => l10n.payrollRuleWrongPhase,
    PayrollRule.previousNotValidated => l10n.payrollBlockerPrevious,
    PayrollRule.attendanceOpen => l10n.payrollBlockerAttendance(month ?? ''),
    PayrollRule.hasDisbursements => l10n.payrollBlockerDisbursed,
    PayrollRule.reasonRequired => l10n.payrollRuleReasonRequired,
    PayrollRule.overtimeNotAllowed => l10n.payrollRuleOvertimeNotAllowed,
    PayrollRule.invalidAmount => l10n.payrollRuleInvalidAmount,
    PayrollRule.invalidInstallments => l10n.payrollRuleInvalidInstallments,
    PayrollRule.monthLocked => l10n.payrollRuleMonthLocked,
    PayrollRule.noContract => l10n.payrollRuleNoContract,
    PayrollRule.alreadyDeducted => l10n.payrollRuleAlreadyDeducted,
    PayrollRule.notValidated => l10n.payrollRuleNotValidated,
    PayrollRule.nothingToDisburse => l10n.payrollRuleNothingToDisburse,
    PayrollRule.alreadyDisbursed => l10n.payrollRuleAlreadyDisbursed,
    PayrollRule.signatureRequired => l10n.payrollRuleSignatureRequired,
    PayrollRule.mobileDetailsRequired => l10n.payrollRuleMobileDetails,
    PayrollRule.invalidReference => l10n.payrollRuleInvalidReference,
    PayrollRule.bankDetailsRequired => l10n.payrollRuleBankDetails,
    PayrollRule.laterPayrollLocked => l10n.payrollRuleLaterLocked,
    PayrollRule.monthOutOfRange => l10n.payrollRuleMonthOutOfRange,
    PayrollRule.invalidData => l10n.payrollRuleInvalidData,
    PayrollRule.alreadyCancelled => l10n.payrollRuleAlreadyCancelled,
    PayrollRule.forbidden => l10n.payrollRuleForbidden,
    PayrollRule.parentRefused => l10n.payrollRuleParentRefused,
    PayrollRule.stale => l10n.payrollStaleBanner,
  };

  /// Un refus du serveur en mots : la règle qu'il dit quand on la connaît,
  /// sinon son code tel quel.
  static String serverRefusal(
    AppLocalizations l10n,
    String? code, {
    String? month,
  }) {
    final rule = payrollRuleOfServerCode(code);
    return rule == null
        ? l10n.payrollRefusedOther(code ?? '—')
        : PayrollLabels.rule(l10n, rule, month: month);
  }

  /// Pourquoi un versement attend d'être régularisé.
  static String refusal(AppLocalizations l10n, String? code) => switch (code) {
    'PAYROLL_REOPENED_SINCE' => l10n.payrollRefusedReopened,
    'ALREADY_DISBURSED' => l10n.payrollRefusedDouble,
    _ => serverRefusal(l10n, code),
  };
}
