import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_variables.dart';
import 'package:school_app_flutter/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:school_app_flutter/features/payroll/domain/services/payroll_fingerprinter.dart';

/// Le motif d'un versement réduit (taux du mois ou montant fixe).
const int minPayoutReasonLength = 3;

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
        (variables.dependentChildren ?? 0) < 0 ||
        (variables.childcareInCents ?? 0) < 0 ||
        (variables.fixedPayoutInCents ?? 0) < 0) {
      return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
    }
    // NJP ∈ [0, diviseur] ; un vacataire à l'heure n'en a pas (T5).
    if (variables.workedDays case final days?) {
      final divisor = line.deductions.workDaysDivisor;
      if (divisor == null || days < 0 || days > divisor) {
        return Left(PayrollRuleFailure(PayrollRule.workedDaysOutOfRange));
      }
    }
    if (variables.fixedPayoutInCents != null &&
        (variables.fixedPayoutReason?.trim().length ?? 0) <
            minPayoutReasonLength) {
      return Left(PayrollRuleFailure(PayrollRule.reasonRequired));
    }
    return _repository.saveVariables(view.month, variables);
  }
}

/// Règle le taux de versement du mois (v2) : brouillon seulement, de 0 à
/// 100 %, motif requis sous 100 %. Le net dû ne change pas.
class SavePayrollPayoutPolicyUseCase {
  final PayrollRepository _repository;

  const SavePayrollPayoutPolicyUseCase(this._repository);

  Future<Either<Failure, Unit>> call(
    PayrollMonthView view,
    int ratePercent, {
    String? reason,
  }) async {
    if (!view.isEditable) {
      return Left(PayrollRuleFailure(PayrollRule.notEditable));
    }
    if (ratePercent < 0 || ratePercent > 100) {
      return Left(PayrollRuleFailure(PayrollRule.invalidAmount));
    }
    if (ratePercent < 100 &&
        (reason?.trim().length ?? 0) < minPayoutReasonLength) {
      return Left(PayrollRuleFailure(PayrollRule.reasonRequired));
    }
    return _repository.savePayoutPolicy(
      view.month,
      ratePercent,
      reason: reason,
    );
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
    return blocker?.rule;
  }
}
