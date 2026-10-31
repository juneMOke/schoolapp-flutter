import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_deduction_repository.dart';

/// Les règles du catalogue, tenues avant la file : hors ligne, le refus du
/// serveur n'arriverait qu'après coup.
abstract final class PayrollDeductionCatalogRules {
  static String _normal(String label) => label.trim().toLowerCase();

  /// `null` si [type] peut s'écrire dans [catalog]. Une rubrique archivée ne
  /// compte ni pour le libellé, ni pour le plafond.
  static PayrollRule? check(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type,
  ) {
    final label = type.label.trim();
    if (label.isEmpty || label.length > PayrollDeductionType.maxLabelLength) {
      return PayrollRule.invalidData;
    }
    if (type.archived) return null;
    final others = catalog.where((t) => t.id != type.id && !t.archived);
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
    String label,
  ) async {
    final last = catalog.fold(
      0,
      (max, type) => type.sortOrder > max ? type.sortOrder : max,
    );
    final type = PayrollDeductionType(
      id: _repository.newTypeId(),
      label: label,
      sortOrder: last + orderStep,
    );
    final rule = PayrollDeductionCatalogRules.check(catalog, type);
    if (rule != null) return Left(PayrollRuleFailure(rule));
    return _repository.saveTypes([type]);
  }
}

/// Renomme, archive ou restaure une rubrique. Restaurer repasse par le libellé
/// et le plafond, comme une création.
class UpdatePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const UpdatePayrollDeductionTypeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type,
  ) async {
    final rule = PayrollDeductionCatalogRules.check(catalog, type);
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
          PayrollDeductionType(
            id: type.id,
            label: type.label,
            sortOrder:
                (index + 1) * CreatePayrollDeductionTypeUseCase.orderStep,
            archived: type.archived,
          ),
    ]);
  }
}

/// Supprime une rubrique jamais saisie ; ailleurs, le serveur la refuse.
class RemovePayrollDeductionTypeUseCase {
  final PayrollDeductionRepository _repository;

  const RemovePayrollDeductionTypeUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String id) => _repository.removeType(id);
}
