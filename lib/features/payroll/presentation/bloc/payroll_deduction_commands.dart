import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_deduction_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';

/// Les gestes du catalogue des rubriques : chacun rend l'annonce à montrer.
class PayrollDeductionCommands {
  final CreatePayrollDeductionTypeUseCase _create;
  final UpdatePayrollDeductionTypeUseCase _update;
  final MovePayrollDeductionTypeUseCase _move;
  final RemovePayrollDeductionTypeUseCase _remove;

  const PayrollDeductionCommands({
    required CreatePayrollDeductionTypeUseCase create,
    required UpdatePayrollDeductionTypeUseCase update,
    required MovePayrollDeductionTypeUseCase move,
    required RemovePayrollDeductionTypeUseCase remove,
  }) : _create = create,
       _update = update,
       _move = move,
       _remove = remove;

  static const PayrollNotice _saved = PayrollNotice(
    PayrollNoticeKind.deductionTypeSaved,
  );

  Future<PayrollNotice> create(
    List<PayrollDeductionType> catalog,
    String label,
  ) async => _notice(await _create(catalog, label), _saved);

  Future<PayrollNotice> update(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type,
  ) async => _notice(await _update(catalog, type), _saved);

  Future<PayrollNotice> move(
    List<PayrollDeductionType> catalog,
    String id, {
    required bool up,
  }) async => _notice(await _move(catalog, id, up: up), _saved);

  Future<PayrollNotice> remove(String id) async => _notice(
    await _remove(id),
    const PayrollNotice(PayrollNoticeKind.deductionTypeRemoved),
  );

  PayrollNotice _notice(Either<Failure, Unit> result, PayrollNotice success) =>
      result.fold(
        (failure) => switch (failure) {
          PayrollRuleFailure(:final rule) => PayrollNotice(
            PayrollNoticeKind.refused,
            rule: rule,
          ),
          NetworkFailure() => const PayrollNotice(PayrollNoticeKind.offline),
          _ => const PayrollNotice(PayrollNoticeKind.writeFailed),
        },
        (_) => success,
      );
}
