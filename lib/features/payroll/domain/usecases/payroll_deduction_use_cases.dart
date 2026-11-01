import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_circuit_use_cases.dart';

/// Les règles du catalogue, tenues avant la file : hors ligne, le refus du
/// serveur n'arriverait qu'après coup.
abstract final class PayrollDeductionCatalogRules {
  static String _normal(String label) => label.trim().toLowerCase();

  static bool _sameCurrency(PayrollDeductionType a, PayrollDeductionType b) =>
      CurrencyCode.normalize(a.currency) == CurrencyCode.normalize(b.currency);

  /// `null` si [type] peut s'écrire dans [catalog]. [used] : une saisie ou une
  /// ligne figée la cite, son code et sa devise ne bougent plus.
  ///
  /// Le code se juge sur tout le catalogue, archivées comprises ; le libellé et
  /// le plafond, par devise, parmi les rubriques actives seulement.
  static PayrollRule? check(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type, {
    bool used = false,
  }) {
    final label = type.label.trim();
    final previous = catalog.where((t) => t.id == type.id).firstOrNull;
    // Venue d'un serveur antérieur au contrat, une rubrique garde un code et
    // une devise vides : elle s'archive et se renomme quand même.
    final codeKept = type.code.isEmpty && previous?.code.isEmpty == true;
    final currencyKept =
        type.currency.isEmpty && previous?.currency.isEmpty == true;
    if (label.isEmpty ||
        label.length > PayrollDeductionType.maxLabelLength ||
        (!codeKept && !PayrollDeductionType.codeFormat.hasMatch(type.code)) ||
        (!currencyKept && CurrencyCode.normalize(type.currency).isEmpty) ||
        (type.description?.length ?? 0) >
            PayrollDeductionType.maxDescriptionLength) {
      return PayrollRule.invalidData;
    }
    if (type.defaultAmountInCents < 0) return PayrollRule.invalidAmount;
    if (type.code.isNotEmpty &&
        catalog.any((t) => t.id != type.id && t.code == type.code)) {
      return PayrollRule.deductionTypeCodeTaken;
    }
    if (used &&
        previous != null &&
        ((previous.code.isNotEmpty && previous.code != type.code) ||
            (previous.currency.isNotEmpty && !_sameCurrency(previous, type)))) {
      return PayrollRule.deductionTypeFieldLocked;
    }
    if (type.archived) return null;
    final others = catalog.where(
      (t) => t.id != type.id && !t.archived && _sameCurrency(t, type),
    );
    if (others.any((t) => _normal(t.label) == _normal(label))) {
      return PayrollRule.deductionTypeLabelTaken;
    }
    if (others.length >= PayrollDeductionType.maxActive) {
      return PayrollRule.deductionTypeLimitReached;
    }
    return null;
  }
}

/// Crée une rubrique en fin de liste ; l'identifiant vient de la tablette.
class CreatePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const CreatePayrollDeductionTypeUseCase(this._repository);

  static const int orderStep = 10;

  Future<Either<Failure, Unit>> call(
    List<PayrollDeductionType> catalog,
    PayrollDeductionTypeDraft draft,
  ) async {
    final last = catalog.fold(
      0,
      (max, type) => type.sortOrder > max ? type.sortOrder : max,
    );
    final type = PayrollDeductionType(
      id: _repository.newTypeId(),
      label: draft.label,
      sortOrder: last + orderStep,
    ).rewritten(draft: draft);
    final rule = PayrollDeductionCatalogRules.check(catalog, type);
    if (rule != null) return Left(PayrollRuleFailure(rule));
    return _repository.saveTypes([type]);
  }
}

/// Modifie, archive ou restaure une rubrique. Restaurer repasse par le libellé
/// et le plafond, comme une création.
class UpdatePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const UpdatePayrollDeductionTypeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type, {
    bool used = false,
  }) async {
    final rule = PayrollDeductionCatalogRules.check(catalog, type, used: used);
    if (rule != null) return Left(PayrollRuleFailure(rule));
    return _repository.saveTypes([type]);
  }
}

/// Déplace une rubrique active d'un cran : les rangs se renumérotent, et seules
/// celles qui changent de rang repartent.
class MovePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const MovePayrollDeductionTypeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    List<PayrollDeductionType> catalog,
    String id, {
    required bool up,
  }) async {
    final active = catalog.where((type) => !type.archived).toList();
    final from = active.indexWhere((type) => type.id == id);
    final to = up ? from - 1 : from + 1;
    if (from < 0 || to < 0 || to >= active.length) return const Right(unit);
    active.insert(to, active.removeAt(from));
    return _repository.saveTypes([
      for (final (index, type) in active.indexed)
        if (type.sortOrder !=
            (index + 1) * CreatePayrollDeductionTypeUseCase.orderStep)
          type.rewritten(
            sortOrder:
                (index + 1) * CreatePayrollDeductionTypeUseCase.orderStep,
          ),
    ]);
  }
}

/// Enregistre les éléments variables d'un agent et ses saisies de rubriques,
/// dans une même transaction : mêmes règles que les éléments seuls, et une
/// rubrique archivée ou d'une autre devise n'accepte que la mise à 0.
class SavePayrollDeductionsUseCase {
  final PayrollDeductionRepository _repository;

  const SavePayrollDeductionsUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollMonthView view,
    PayrollVariables variables,
    List<PayrollDeductionEntry> entries, {
    required List<PayrollDeductionType> catalog,
  }) async {
    final rule = SavePayrollVariablesUseCase.check(view, variables);
    if (rule != null) return Left(PayrollRuleFailure(rule));
    final byId = {for (final type in catalog) type.id: type};
    for (final entry in entries) {
      if (entry.amountInCents < 0) {
        return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
      }
      final type = byId[entry.deductionTypeId];
      if (entry.amountInCents == 0 || type == null) continue;
      if (type.archived) {
        return Left(PayrollRuleFailure(PayrollRule.deductionTypeArchived));
      }
      if (type.currency.isNotEmpty && !type.appliesTo(entry.currency)) {
        return Left(PayrollRuleFailure(PayrollRule.deductionCurrencyMismatch));
      }
    }
    return _repository.saveEntries(
      view.month,
      variables: variables,
      entries: entries,
    );
  }
}

/// Efface une saisie refusée que l'économe a lue.
class DismissPayrollDeductionUseCase {
  final PayrollDeductionRepository _repository;

  const DismissPayrollDeductionUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    String month,
    PayrollDeductionEntry entry,
  ) => _repository.dismissEntry(month, entry);
}

/// Supprime une rubrique jamais saisie ; ailleurs, le serveur la refuse.
class RemovePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const RemovePayrollDeductionTypeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) => _repository.removeType(id);
}
