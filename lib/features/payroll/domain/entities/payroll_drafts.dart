import 'package:school_app_flutter/core/money/mobile_money_operator.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';

/// Ce qu'une avance saisie porte, avant d'être un fait.
class SalaryAdvanceDraft {
  final String staffMemberId;

  /// Dans la devise du contrat en vigueur.
  final Money amount;
  final int installments;

  /// `YYYY-MM`.
  final String firstMonth;
  final SalaryAdvanceReason reason;
  final String? reasonDetail;
  final PayoutMode mode;

  /// `YYYY-MM-DD`.
  final String grantedOn;

  const SalaryAdvanceDraft({
    required this.staffMemberId,
    required this.amount,
    required this.installments,
    required this.firstMonth,
    required this.reason,
    required this.mode,
    required this.grantedOn,
    this.reasonDetail,
  });
}

/// Ce qu'un versement saisi porte : le net figé, le mode et sa preuve.
class PayrollDisbursementDraft {
  final String month;
  final String staffMemberId;
  final String validationGestureId;
  final Money amount;
  final PayoutMode mode;
  final MobileMoneyOperator? operator;
  final String? payoutPhone;
  final String? reference;
  final String? bankName;
  final String? bankAccount;
  final bool signedRegister;

  const PayrollDisbursementDraft({
    required this.month,
    required this.staffMemberId,
    required this.validationGestureId,
    required this.amount,
    required this.mode,
    this.operator,
    this.payoutPhone,
    this.reference,
    this.bankName,
    this.bankAccount,
    this.signedRegister = false,
  });
}
