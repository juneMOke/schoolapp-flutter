import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';

/// Demander une avance ou un prêt (B5) : **une demande de dépense** de type
/// `STAFF_ADVANCE`, qui part en validation dans Dépenses ▸ Validations. Rien
/// n'est versé ni retenu avant approbation et décaissement ; la Paie ne crée
/// l'avance qu'au paiement.
class RequestSalaryAdvanceUseCase {
  final SaveExpenseUseCase _save;

  const RequestSalaryAdvanceUseCase(this._save);

  /// [title] : l'intitulé de la dépense, **sans le nom de l'agent** — le
  /// serveur ne caviarde pas le texte libre (T14).
  Future<Either<Failure, Unit>> call(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft, {
    required String title,
    required DateTime today,
    String? recordedByName,
  }) async {
    final typeId = snapshot.staffAdvanceTypeId;
    if (typeId == null) {
      return Left(PayrollRuleFailure(PayrollRule.advanceTypeMissing));
    }
    final refusal = refusalOf(snapshot, draft);
    if (refusal != null) return Left(PayrollRuleFailure(refusal));
    final saved = await _save(
      ExpenseDraft(
        typeId: typeId,
        title: title,
        description: draft.reasonDetail,
        amountInCents: draft.amount.amountInCents,
        currency: draft.amount.currency,
        expenseDate: today,
        fundingSource: switch (draft.mode) {
          PayoutMode.cash => ExpenseFundingSource.cash,
          PayoutMode.mobileMoney => ExpenseFundingSource.mobileMoney,
          PayoutMode.bank => ExpenseFundingSource.bank,
        },
        recordedByName: recordedByName,
        staffAdvance: ExpenseStaffAdvance(
          staffMemberId: draft.staffMemberId,
          kind: draft.installments > 1
              ? ExpenseStaffAdvanceKind.loan
              : ExpenseStaffAdvanceKind.advance,
          installments: draft.installments,
          reason: draft.reason.wire,
          reasonDetail: draft.reasonDetail,
        ),
      ),
    );
    return saved.map((_) => unit);
  }

  /// Le montant, les échéances (1 à 4) et la devise du contrat en vigueur
  /// (T15). Le mois de première retenue se choisit au décaissement.
  static PayrollRule? refusalOf(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft,
  ) {
    if (draft.amount.amountInCents <= 0) return PayrollRule.invalidAmount;
    if (draft.installments < 1 ||
        draft.installments > PayrollAdvanceRules.maxInstallments) {
      return PayrollRule.invalidInstallments;
    }
    final contract = PayrollAdvanceRules.contractFor(
      snapshot,
      draft.staffMemberId,
      draft.firstMonth,
    );
    if (contract == null) return PayrollRule.noContract;
    final currency = PayrollEngine.currencyOf(
      contract,
      fallback: snapshot.settings.firstCurrency,
    );
    return currency == draft.amount.currency ? null : PayrollRule.invalidAmount;
  }
}
