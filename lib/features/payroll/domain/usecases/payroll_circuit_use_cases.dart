import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';

/// Enregistre les éléments variables d'un agent, brouillon seulement.
class SavePayrollVariablesUseCase {
  final PayrollRepository _repository;

  const SavePayrollVariablesUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollMonthView view,
    PayrollVariables variables,
  ) async {
    if (!view.isEditable) {
      return Left(PayrollRuleFailure(PayrollRule.notEditable));
    }
    final line = view.line(variables.staffMemberId);
    if (line == null) return Left(PayrollRuleFailure(PayrollRule.noContract));
    if (!line.overtimeAllowed && (variables.overtimeMinutes ?? 0) > 0) {
      return Left(PayrollRuleFailure(PayrollRule.overtimeNotAllowed));
    }
    if ((variables.overtimeMinutes ?? 0) < 0 ||
        (variables.overtimeRateInCents ?? 0) < 0 ||
        (variables.dependentChildren ?? 0) < 0) {
      return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
    }
    return _repository.saveVariables(view.month, variables);
  }
}

/// Pose un geste du circuit sur le livre **tel qu'il est affiché** : l'empreinte
/// part avec lui, le serveur recalcule et refuse s'il trouve autre chose.
class RecordPayrollGestureUseCase {
  final PayrollRepository _repository;

  const RecordPayrollGestureUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollMonthView view,
    PayrollGestureKind kind, {
    String? reason,
  }) async {
    final refusal = refusalOf(view, kind, reason: reason);
    if (refusal != null) return Left(PayrollRuleFailure(refusal));
    return _repository.recordGesture(
      view.month,
      kind,
      reason: kind.needsReason ? reason!.trim() : null,
      expected: kind.carriesFingerprint
          ? await PayrollFingerprinter.of(view.lines)
          : null,
    );
  }

  /// Pourquoi [kind] ne peut pas partir de [view] ; `null` = il peut.
  static PayrollRule? refusalOf(
    PayrollMonthView view,
    PayrollGestureKind kind, {
    String? reason,
  }) {
    final from = switch (kind.source) {
      PayrollStatus.draft => PayrollPhase.draft,
      PayrollStatus.submitted => PayrollPhase.submitted,
      PayrollStatus.validated => PayrollPhase.validated,
    };
    final phase = view.phase == PayrollPhase.paid
        ? PayrollPhase.validated
        : view.phase;
    if (phase != from) return PayrollRule.wrongPhase;
    if (kind.needsReason && (reason == null || reason.trim().isEmpty)) {
      return PayrollRule.reasonRequired;
    }
    final blocker = switch (kind) {
      PayrollGestureKind.submit => view.submitBlocker,
      PayrollGestureKind.validate => view.validateBlocker,
      PayrollGestureKind.reopen => view.reopenBlocker,
      PayrollGestureKind.returnToDraft => null,
    };
    return switch (blocker) {
      null => null,
      PayrollBlocker.previousNotValidated => PayrollRule.previousNotValidated,
      PayrollBlocker.attendanceOpen => PayrollRule.attendanceOpen,
      PayrollBlocker.emptyLedger => PayrollRule.emptyLedger,
      PayrollBlocker.hasDisbursements => PayrollRule.hasDisbursements,
    };
  }
}
