import 'package:school_app_flutter/features/payroll/domain/entities/payroll_enums.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_gesture.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';

/// Le statut affiché = statut descendu + geste de cette tablette pas encore
/// accusé. Un geste refusé ne compte pas : l'écran revient au statut serveur.
abstract final class PayrollPhaseResolver {
  static PayrollPhase resolve({
    required PayrollStatus server,
    required List<PayrollGesture> monthGestures,
    required bool allPaid,
  }) {
    PayrollGesture? latest;
    for (final gesture in monthGestures) {
      if (gesture.isInFlight) latest = gesture;
    }
    if (latest != null) {
      return switch (latest.kind) {
        PayrollGestureKind.submit => PayrollPhase.submitting,
        PayrollGestureKind.returnToDraft => PayrollPhase.returning,
        PayrollGestureKind.validate => PayrollPhase.validating,
        PayrollGestureKind.reopen => PayrollPhase.reopening,
      };
    }
    return switch (server) {
      PayrollStatus.draft => PayrollPhase.draft,
      PayrollStatus.submitted => PayrollPhase.submitted,
      PayrollStatus.validated =>
        allPaid ? PayrollPhase.paid : PayrollPhase.validated,
    };
  }
}
