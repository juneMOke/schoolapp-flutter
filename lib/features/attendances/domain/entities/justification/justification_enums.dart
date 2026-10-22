/// Où en est une justification côté serveur.
enum JustificationStatus {
  pending('PENDING'),
  accepted('ACCEPTED'),
  rejected('REJECTED'),

  /// Un statut que cette tablette ne connaît pas (un contrat plus récent :
  /// demande retirée par le parent…). Ni à traiter, ni tranchée par l'école :
  /// la tablette ne propose aucun geste qu'elle ne saurait pas juger.
  unknown('');

  const JustificationStatus(this.apiValue);

  final String apiValue;

  static JustificationStatus fromApi(String? value) => switch (value) {
    'PENDING' || null => pending,
    'ACCEPTED' => accepted,
    'REJECTED' => rejected,
    _ => unknown,
  };

  /// Une décision de l'école, d'ici ou d'ailleurs.
  bool get isDecision => this == accepted || this == rejected;
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

/// Pourquoi la dernière décision de cette tablette n'est pas passée. Rangé en
/// code, jamais en phrase : l'écran le dit dans la langue de l'utilisateur.
enum JustificationRefusal {
  /// Décision prise sans utilisateur connu : il faut se reconnecter.
  noAuthor('NO_AUTHOR'),

  /// Le droit de modifier l'appel manque (403 du compte connecté).
  forbidden('FORBIDDEN'),

  /// Refus du serveur sans motif que la tablette sache dire.
  rejected('REJECTED'),

  /// Le geste n'a jamais pu partir (essais épuisés) : rien n'a été tranché.
  notSent('NOT_SENT');

  const JustificationRefusal(this.code);

  final String code;

  static JustificationRefusal? fromCode(String? code) => code == null
      ? null
      : JustificationRefusal.values.firstWhere(
          (refusal) => refusal.code == code,
          orElse: () => rejected,
        );
}
