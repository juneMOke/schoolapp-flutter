import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_advance_payment.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_draft.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_enums.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_gesture.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_staff_advance.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/find_expense_use_case.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/expense_write_use_cases.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_drafts.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_snapshot.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_advance_rules.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_engine.dart';

/// Demander une avance ou un prêt (B5) : **une demande de dépense** de type
/// `STAFF_ADVANCE`, qui part en validation — dans Dépenses ▸ Validations
/// comme dans RH · Paie ▸ Avances & prêts. Rien
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

  /// Le montant, les échéances (1 au plafond de l'école) et la devise du
  /// contrat en vigueur
  /// (T15). Le mois de première retenue se choisit au décaissement.
  static PayrollRule? refusalOf(
    PayrollSnapshot snapshot,
    SalaryAdvanceDraft draft,
  ) {
    if (draft.amount.amountInCents <= 0) return PayrollRule.invalidAmount;
    if (draft.installments < 1 ||
        draft.installments > PayrollAdvanceRules.maxInstallmentsOf(snapshot)) {
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

/// Trancher une demande d'avance depuis la Paie (spec §10) : l'approuver, la
/// refuser ou la décaisser. Ce sont les gestes **de la dépense** — même file,
/// mêmes règles, même accusé — posés d'un autre écran.
class DecideSalaryAdvanceUseCase {
  final FindExpenseUseCase _find;
  final ApplyExpenseGestureUseCase _apply;

  const DecideSalaryAdvanceUseCase(this._find, this._apply);

  /// Les seuls gestes que la Paie offre sur une demande.
  static const Set<ExpenseGesture> decisions = {
    ExpenseGesture.approve,
    ExpenseGesture.refuse,
    ExpenseGesture.pay,
  };

  /// La demande telle que la tablette la tient : la modale de décaissement
  /// la montre, et le geste part de cette copie.
  Future<Either<Failure, Expense?>> requestOf(String expenseId) =>
      _find(expenseId);

  Future<Either<Failure, Unit>> call(
    Expense expense,
    ExpenseGesture gesture, {
    String note = '',
    String? actorName,
    ExpenseAdvancePayment? advancePayment,
  }) async {
    if (!decisions.contains(gesture)) {
      return Left(PayrollRuleFailure(PayrollRule.wrongPhase));
    }
    if (gesture == ExpenseGesture.refuse && note.trim().isEmpty) {
      return Left(PayrollRuleFailure(PayrollRule.reasonRequired));
    }
    final result = await _apply(
      expense,
      gesture,
      note: note,
      actorName: actorName,
      advancePayment: advancePayment,
    );
    final failure = result.fold((failure) => failure, (_) => null);
    if (failure == null) return result;
    return Left(await _inPayrollTerms(failure, expense, gesture));
  }

  /// Les refus du dépôt des dépenses, dits dans la langue de la Paie.
  Future<Failure> _inPayrollTerms(
    Failure failure,
    Expense expense,
    ExpenseGesture gesture,
  ) async {
    switch (failure) {
      case ConflictFailure():
        // Décaisser refusé sur une demande toujours accordée : c'est le mois
        // de première retenue qui s'est fermé — en choisir un autre. Sinon
        // un collègue a tranché entre-temps.
        if (gesture == ExpenseGesture.pay) {
          final current = (await _find(expense.id)).fold((_) => null, (e) => e);
          if (current?.status == ExpenseStatus.approved) {
            return PayrollRuleFailure(PayrollRule.monthLocked);
          }
        }
        return PayrollRuleFailure(PayrollRule.wrongPhase);
      case ValidationFailure() when gesture == ExpenseGesture.refuse:
        return PayrollRuleFailure(PayrollRule.reasonRequired);
      // La preuve d'un décaissement : l'émargement en espèces, sinon la
      // référence de l'opération.
      case ValidationFailure() when gesture == ExpenseGesture.pay:
        return PayrollRuleFailure(
          expense.fundingSource == ExpenseFundingSource.cash
              ? PayrollRule.signatureRequired
              : PayrollRule.invalidReference,
        );
      default:
        return failure;
    }
  }
}
