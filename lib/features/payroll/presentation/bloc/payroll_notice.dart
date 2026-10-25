import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';

enum PayrollNoticeKind {
  variablesSaved,

  /// Le taux de versement du mois ; `amount` porte le taux.
  payoutPolicySaved,
  arrearsPrioritized,
  arrearsUnprioritized,
  submitted,
  validated,
  returned,
  reopened,
  paid,
  payCancelled,
  advanceGranted,

  /// Une demande d'avance déposée en validation (B5) ; `amount` mis en forme.
  advanceRequested,

  /// Une demande d'avance tranchée depuis la Paie ; `name` et `amount`.
  advanceApproved,
  advanceRefused,
  advanceDisbursed,
  advanceCancelled,
  profileSaved,
  settingsSaved,
  shared,
  downloaded,

  /// Le bulletin scellé ne se télécharge qu'en ligne.
  offline,

  /// Le serveur n'a pas rendu le bulletin.
  downloadFailed,

  /// Le serveur compose déjà un long document (429) : réessayer plus tard.
  renderBusy,

  /// La paie a été validée pendant qu'on demandait son provisoire (P8) :
  /// c'est désormais le bulletin scellé qu'il faut demander.
  validatedMeanwhile,

  /// Une règle refusée avant la file.
  refused,

  /// L'écriture locale a échoué.
  writeFailed,
}

/// L'annonce d'un geste de la paie, montrée une fois (`seq` la distingue de
/// la précédente, même identique).
class PayrollNotice extends Equatable {
  final PayrollNoticeKind kind;
  final String? name;

  /// Déjà mis en forme, devise comprise.
  final String? amount;
  final PayrollRule? rule;
  final int seq;

  const PayrollNotice(
    this.kind, {
    this.name,
    this.amount,
    this.rule,
    this.seq = 0,
  });

  PayrollNotice withSeq(int seq) =>
      PayrollNotice(kind, name: name, amount: amount, rule: rule, seq: seq);

  @override
  List<Object?> get props => [kind, name, amount, rule, seq];
}
