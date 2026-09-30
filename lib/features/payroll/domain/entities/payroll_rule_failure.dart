import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';

/// Une règle de la paie que le geste ne respecte pas — refusée **avant** la
/// file d'envoi, où le même refus serait devenu terminal.
enum PayrollRule {
  /// La paie n'est plus en brouillon (soumise, validée, ou un geste en vol).
  notEditable,

  /// Le geste ne part pas de l'état affiché.
  wrongPhase,
  previousNotValidated,
  attendanceOpen,
  hasDisbursements,
  reasonRequired,

  /// Un vacataire n'a pas d'heures supplémentaires.
  overtimeNotAllowed,
  invalidAmount,
  invalidInstallments,

  /// Le mois de départ d'une avance est déjà soumis ou validé.
  monthLocked,

  /// L'agent n'a pas de contrat qui le paie.
  noContract,

  /// Une retenue de cette avance est déjà figée.
  alreadyDeducted,
  notValidated,
  nothingToDisburse,
  alreadyDisbursed,
  signatureRequired,
  mobileDetailsRequired,
  invalidReference,
  bankDetailsRequired,

  /// Un mois plus récent est déjà soumis ou validé.
  laterPayrollLocked,

  /// Hors de la période de paie de l'école.
  monthOutOfRange,

  /// Une saisie que le serveur juge invalide.
  invalidData,
  alreadyCancelled,

  /// Le compte n'a pas le droit du geste (403).
  forbidden,

  /// La fiche de l'agent a été refusée : ce qui en dépend échoue avec elle.
  parentRefused,

  /// Les chiffres du serveur diffèrent de ceux vus (`PAYROLL_STALE`).
  stale,
}

class PayrollRuleFailure extends ValidationFailure {
  final PayrollRule rule;

  PayrollRuleFailure(this.rule) : super('Paie : ${rule.name}');

  @override
  List<Object?> get props => [...super.props, rule];
}

/// La règle que dit un blocage du livre.
extension PayrollBlockerRule on PayrollBlocker {
  PayrollRule get rule => switch (this) {
    PayrollBlocker.previousNotValidated => PayrollRule.previousNotValidated,
    PayrollBlocker.attendanceOpen => PayrollRule.attendanceOpen,
    PayrollBlocker.hasDisbursements => PayrollRule.hasDisbursements,
  };
}

/// La règle que dit un refus du serveur, quand elle a son libellé ; `null`
/// pour un code inconnu (il s'affiche alors tel quel).
PayrollRule? payrollRuleOfServerCode(String? code) => switch (code) {
  'PREVIOUS_PAYROLL_NOT_VALIDATED' => PayrollRule.previousNotValidated,
  'ATTENDANCE_MONTH_NOT_CLOSED' => PayrollRule.attendanceOpen,
  'PAYROLL_HAS_DISBURSEMENTS' => PayrollRule.hasDisbursements,
  'GESTURE_NOT_APPLICABLE' => PayrollRule.wrongPhase,
  'REASON_REQUIRED' => PayrollRule.reasonRequired,
  'PAYROLL_NOT_DRAFT' => PayrollRule.notEditable,
  'OVERTIME_NOT_ALLOWED' => PayrollRule.overtimeNotAllowed,
  'STAFF_NOT_ON_PAYROLL' => PayrollRule.noContract,
  'ADVANCE_MONTH_LOCKED' => PayrollRule.monthLocked,
  'ADVANCE_CURRENCY_MISMATCH' || 'AMOUNT_MISMATCH' => PayrollRule.invalidAmount,
  'ADVANCE_ALREADY_DEDUCTED' => PayrollRule.alreadyDeducted,
  'ALREADY_DISBURSED' => PayrollRule.alreadyDisbursed,
  'NOTHING_TO_DISBURSE' => PayrollRule.nothingToDisburse,
  'SIGNATURE_REQUIRED' => PayrollRule.signatureRequired,
  'PAYROLL_NOT_VALIDATED' => PayrollRule.notValidated,
  'LATER_PAYROLL_LOCKED' => PayrollRule.laterPayrollLocked,
  'PAYROLL_MONTH_OUT_OF_RANGE' => PayrollRule.monthOutOfRange,
  'ALREADY_CANCELLED' => PayrollRule.alreadyCancelled,
  'PAYROLL_GESTURE_FORBIDDEN' || 'HTTP_403' => PayrollRule.forbidden,
  'PAYROLL_STALE' => PayrollRule.stale,
  'STAFF_MEMBER_REFUSED' => PayrollRule.parentRefused,
  'FINGERPRINT_REQUIRED' ||
  'INVALID_ADVANCE' ||
  'INVALID_DISBURSEMENT' ||
  'INVALID_PAY_PROFILE' ||
  'INVALID_PAYROLL_SETTINGS' => PayrollRule.invalidData,
  final code? when code.endsWith('_ID_CONFLICT') => PayrollRule.invalidData,
  _ => null,
};
