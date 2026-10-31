import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/usecases/payroll_deduction_use_cases.dart';
import 'package:school_app_flutter/features/payroll/presentation/bloc/payroll_notice.dart';

/// Les gestes du catalogue des rubriques : chacun rend l'annonce à montrer.
class PayrollDeductionCommands {
  final CreatePayrollDeductionTypeUseCase _create;
  final UpdatePayrollDeductionTypeUseCase _update;
  final MovePayrollDeductionTypeUseCase _move;
  final RemovePayrollDeductionTypeUseCase _remove;
  final SavePayrollDeductionsUseCase _entries;
  final DismissPayrollDeductionUseCase _dismiss;

  const PayrollDeductionCommands({
    required CreatePayrollDeductionTypeUseCase create,
    required UpdatePayrollDeductionTypeUseCase update,
    required MovePayrollDeductionTypeUseCase move,
    required RemovePayrollDeductionTypeUseCase remove,
    required SavePayrollDeductionsUseCase entries,
    required DismissPayrollDeductionUseCase dismiss,
  }) : _create = create,
       _update = update,
       _move = move,
       _remove = remove,
       _entries = entries,
       _dismiss = dismiss;

  static const PayrollNotice _saved = PayrollNotice(
    PayrollNoticeKind.deductionTypeSaved,
  );

  Future<PayrollNotice> create(
    List<PayrollDeductionType> catalog,
    PayrollDeductionTypeDraft draft,
  ) async => _notice(await _create(catalog, draft), _saved);

  Future<PayrollNotice> update(
    List<PayrollDeductionType> catalog,
    PayrollDeductionType type, {
    bool used = false,
  }) async => _notice(await _update(catalog, type, used: used), _saved);

  Future<PayrollNotice> move(
    List<PayrollDeductionType> catalog,
    String id, {
    required bool up,
  }) async => _notice(await _move(catalog, id, up: up), _saved);

  Future<PayrollNotice> remove(String id) async => _notice(
    await _remove(id),
    const PayrollNotice(PayrollNoticeKind.deductionTypeRemoved),
  );

  /// Les éléments variables et les saisies modifiées d'un agent.
  Future<PayrollNotice> saveEntries(
    PayrollMonthView view,
    PayrollVariables variables,
    List<PayrollDeductionEntry> entries, {
    required List<PayrollDeductionType> catalog,
    required String name,
  }) async => _notice(
    await _entries(view, variables, entries, catalog: catalog),
    PayrollNotice(PayrollNoticeKind.variablesSaved, name: name),
  );

  /// Une saisie refusée, lue : rien à annoncer.
  Future<PayrollNotice?> dismiss(
    String month,
    PayrollDeductionEntry entry,
  ) async => (await _dismiss(month, entry)).fold(
    (_) => const PayrollNotice(PayrollNoticeKind.writeFailed),
    (_) => null,
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
