import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_arrear.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_arrears.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_ledger.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_money_use_cases.dart';

/// Verse des arriérés (B4) : une saisie, répartie du mois le plus ancien au
/// plus récent, **un versement ordinaire par mois d'origine** — chacun sous
/// la validation de son mois, chacun jugé par la règle du versement.
class PayPayrollArrearsUseCase {
  final PayrollRepository _repository;

  const PayPayrollArrearsUseCase(this._repository);

  /// [proof] porte le mode et sa preuve ; son mois et son montant sont
  /// ignorés.
  Future<Either<Failure, Unit>> call(
    PayrollSnapshot snapshot,
    PayrollArrearsAgent agent, {
    required String currency,
    required int amountInCents,
    required PayrollDisbursementDraft proof,
  }) async {
    final drafts = draftsOf(
      snapshot,
      agent,
      currency: currency,
      amountInCents: amountInCents,
      proof: proof,
    );
    return drafts.fold(
      (rule) async => Left(PayrollRuleFailure(rule)),
      _repository.disburseAll,
    );
  }

  /// Les versements à poser, ou la première règle qui les refuse.
  static Either<PayrollRule, List<PayrollDisbursementDraft>> draftsOf(
    PayrollSnapshot snapshot,
    PayrollArrearsAgent agent, {
    required String currency,
    required int amountInCents,
    required PayrollDisbursementDraft proof,
  }) {
    if (amountInCents <= 0) return const Left(PayrollRule.invalidAmount);
    if (amountInCents > agent.dueIn(currency)) {
      return const Left(PayrollRule.exceedsBalance);
    }
    final drafts = <PayrollDisbursementDraft>[];
    for (final (arrear, cents) in PayrollArrears.split(
      agent,
      currency,
      amountInCents,
    )) {
      final draft = proof.forLine(
        month: arrear.month,
        validationGestureId: arrear.validationGestureId,
        amount: Money(cents, currency),
        netInCents: arrear.line.netInCents,
      );
      final refusal = DisbursePayrollUseCase.refusalOf(
        PayrollLedger.monthView(snapshot, arrear.month),
        draft,
      );
      if (refusal != null) return Left(refusal);
      drafts.add(draft);
    }
    return Right(drafts);
  }
}

/// Lève ou baisse le drapeau « priorité » d'un arriéré — sans effet sur les
/// montants.
class SetPayrollArrearsPriorityUseCase {
  final PayrollRepository _repository;

  const SetPayrollArrearsPriorityUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollArrear arrear, {
    required bool prioritized,
  }) => _repository.setArrearsPriority(
    staffMemberId: arrear.staffMemberId,
    month: arrear.month,
    prioritized: prioritized,
  );
}
