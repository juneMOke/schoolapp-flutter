import 'package:school_app_flutter/core/error/failures.dart';

/// Une règle de la paie que le geste ne respecte pas — refusée **avant** la
/// file d'envoi, où le même refus serait devenu terminal.
enum PayrollRule {
  /// La paie n'est plus en brouillon (soumise, validée, ou un geste en vol).
  notEditable,

  /// Le geste ne part pas de l'état affiché.
  wrongPhase,
  previousNotValidated,
  attendanceOpen,
  emptyLedger,
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
}

class PayrollRuleFailure extends ValidationFailure {
  final PayrollRule rule;

  PayrollRuleFailure(this.rule) : super('Paie : ${rule.name}');

  @override
  List<Object?> get props => [...super.props, rule];
}
