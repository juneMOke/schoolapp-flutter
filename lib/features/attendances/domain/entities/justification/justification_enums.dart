/// Où en est une justification côté serveur.
enum JustificationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED');

  const JustificationStatus(this.apiValue);

  final String apiValue;

  /// Une valeur inconnue se lit « en attente » : une demande qu'on ne sait pas
  /// lire reste devant l'école plutôt que de disparaître des traitées.
  static JustificationStatus fromApi(String? value) => switch (value) {
    'ACCEPTED' => accepted,
    'REJECTED' => rejected,
    _ => pending,
  };
}

/// Ce que l'école décide d'une demande.
enum JustificationDecision {
  accept('ACCEPT'),
  reject('REJECT');

  const JustificationDecision(this.apiValue);

  final String apiValue;

  static JustificationDecision? fromApi(String? value) => switch (value) {
    'ACCEPT' => accept,
    'REJECT' => reject,
    _ => null,
  };

  /// Le statut serveur que cette décision produit.
  JustificationStatus get status => switch (this) {
    accept => JustificationStatus.accepted,
    reject => JustificationStatus.rejected,
  };
}

/// Pourquoi le serveur a refusé une ACCEPTATION. La demande reste en attente,
/// et seul le refus reste possible : refuser n'est jamais bloqué.
enum JustificationAcceptBlock {
  /// L'appel a été corrigé entre-temps : l'élève n'est plus absent ce jour-là.
  notAnAbsence('NOT_AN_ABSENCE'),

  /// Le mois de l'absence a été clôturé entre-temps.
  monthClosed('MONTH_CLOSED');

  const JustificationAcceptBlock(this.code);

  final String code;

  static JustificationAcceptBlock? fromCode(String? code) => switch (code) {
    'NOT_AN_ABSENCE' => notAnAbsence,
    'MONTH_CLOSED' => monthClosed,
    _ => null,
  };
}
