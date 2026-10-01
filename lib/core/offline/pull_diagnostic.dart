import 'package:equatable/equatable.dart';

/// Pourquoi un flux n'a pas été ramené par le dernier cycle de lecture.
///
/// Les quatre causes que [PullRunReport.isDegraded] résume en un seul booléen,
/// et que la pastille ne peut pas nommer : sans elles, « Certaines données ne
/// descendent pas » laisse le support chercher à l'aveugle quel flux se tait.
enum PullDiagnosticKind {
  /// Le flux a été tiré et a échoué (transport, réponse illisible, écriture
  /// locale) — [PullDiagnostic.detail] porte le message.
  failed,

  /// Sauté parce qu'un flux dont il dépend a échoué dans le même cycle.
  blocked,

  /// Sauté faute du droit local, en repli sans plan de synchronisation.
  forbidden,

  /// Annoncé par le plan du serveur, mais que cet APK ne sait pas tirer.
  notPulled,
}

/// Un flux en défaut du dernier cycle, et sa cause.
class PullDiagnostic extends Equatable {
  /// La ressource du handler (`finance_payments`) ou, pour [PullDiagnosticKind.notPulled],
  /// la clé du plan (`hr.payrolls`) — il n'existe alors aucun handler à nommer.
  final String resource;
  final PullDiagnosticKind kind;

  /// Le message d'échec, seulement pour [PullDiagnosticKind.failed].
  final String? detail;

  const PullDiagnostic(this.resource, this.kind, {this.detail});

  @override
  List<Object?> get props => [resource, kind, detail];
}
