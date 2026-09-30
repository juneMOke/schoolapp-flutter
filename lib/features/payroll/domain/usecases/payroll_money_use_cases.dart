import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_disbursement.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/salary_advance.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';

/// Octroie une avance — dans la devise du contrat, sur un mois encore en
/// brouillon.
class GrantSalaryAdvanceUseCase {
  final PayrollRepository _repository;

  const GrantSalaryAdvanceUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft,
  ) async {
    final refusal = PayrollAdvanceRules.refusalOf(snapshot, draft);
    if (refusal != null) return Left(PayrollRuleFailure(refusal));
    return _repository.grantAdvance(draft);
  }
}

/// Annule une avance dont aucune retenue n'est encore figée.
class CancelSalaryAdvanceUseCase {
  final PayrollRepository _repository;

  const CancelSalaryAdvanceUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollSnapshot snapshot,
    SalaryAdvance advance,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      return Left(PayrollRuleFailure(PayrollRule.reasonRequired));
    }
    if (advance.isCancelled) return const Right(unit);
    if (PayrollAdvanceRules.hasFrozenDeduction(snapshot, advance)) {
      return Left(PayrollRuleFailure(PayrollRule.alreadyDeducted));
    }
    return _repository.cancelAdvance(advance.id, reason.trim());
  }
}

/// Verse le net figé d'un agent. Le montant n'est jamais une saisie.
class DisbursePayrollUseCase {
  final PayrollRepository _repository;

  const DisbursePayrollUseCase(this._repository);

  /// Une référence de transaction : six caractères au moins.
  static const int minReferenceLength = 6;

  Future<Either<Failure, Unit>> call(
    PayrollMonthView view,
    PayrollDisbursementDraft draft,
  ) async {
    final refusal = refusalOf(view, draft);
    if (refusal != null) return Left(PayrollRuleFailure(refusal));
    return _repository.disburse(draft);
  }

  static PayrollRule? refusalOf(
    PayrollMonthView view,
    PayrollDisbursementDraft draft,
  ) {
    if (!view.canPay ||
        draft.validationGestureId != view.header?.validationGestureId) {
      return PayrollRule.notValidated;
    }
    final line = view.line(draft.staffMemberId);
    if (line == null || line.netInCents <= 0) {
      return PayrollRule.nothingToDisburse;
    }
    if (view.disbursements.containsKey(draft.staffMemberId)) {
      return PayrollRule.alreadyDisbursed;
    }
    if (draft.amount.amountInCents != line.netInCents ||
        draft.amount.currency != line.currency) {
      return PayrollRule.invalidAmount;
    }
    final reference = draft.reference?.trim() ?? '';
    return switch (draft.mode) {
      PayoutMode.cash =>
        draft.signedRegister ? null : PayrollRule.signatureRequired,
      PayoutMode.mobileMoney =>
        draft.operator == null ||
                !PhoneNumberFormat.isValid(draft.payoutPhone ?? '')
            ? PayrollRule.mobileDetailsRequired
            : reference.length < minReferenceLength
            ? PayrollRule.invalidReference
            : null,
      PayoutMode.bank =>
        (draft.bankName?.trim() ?? '').isEmpty || reference.isEmpty
            ? PayrollRule.bankDetailsRequired
            : null,
    };
  }
}

/// Annule un versement, motif obligatoire : la ligne repasse « à verser ».
class CancelPayrollDisbursementUseCase {
  final PayrollRepository _repository;

  const CancelPayrollDisbursementUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollDisbursement disbursement,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      return Left(PayrollRuleFailure(PayrollRule.reasonRequired));
    }
    if (disbursement.isCancelled) return const Right(unit);
    return _repository.cancelDisbursement(disbursement, reason.trim());
  }
}
