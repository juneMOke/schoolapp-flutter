import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_rule_failure.dart';

enum PayrollNoticeKind {
  variablesSaved,
  submitted,
  validated,
  returned,
  reopened,
  paid,
  payCancelled,
  advanceGranted,
  advanceCancelled,
  profileSaved,
  settingsSaved,
  shared,
  downloaded,

  /// Le bulletin scellé ne se télécharge qu'en ligne.
  offline,

  /// Le serveur n'a pas rendu le bulletin.
  downloadFailed,

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
