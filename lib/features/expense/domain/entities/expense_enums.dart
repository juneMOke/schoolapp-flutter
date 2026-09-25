/// Où en est une **demande** de dépense dans le circuit de validation (v2).
///
/// Cinq états, et un drapeau qui les partage en deux : [isFirm] dit si
/// l'argent est engagé pour de bon. Toute agrégation d'argent du module passe
/// par lui — une comparaison de statut écrite en dur dans une vue est un
/// défaut de conception, pas un raccourci.
///
/// Le statut n'est **jamais saisi** : il naît [pending] et ne change que par
/// un geste de décision (D8). Le formulaire ne l'offre plus.
enum ExpenseStatus {
  /// Déposée, pas encore décidée. Hors des totaux : rien n'est engagé tant
  /// que rien n'est décidé.
  pending('PENDING', isFirm: false),

  /// Accordée — reste à payer. Porte le décideur et sa date.
  approved('APPROVED', isFirm: true),

  /// Décaissée et soldée ; jamais sans décision préalable.
  paid('PAID', isFirm: true),

  /// Rejetée avec motif — corrigeable par son demandeur.
  refused('REFUSED', isFirm: false),

  /// Reprise par son demandeur ; réengageable après correction. Ce n'est pas
  /// une suppression — celle-ci reste le retrait du registre (`deletedAt`).
  retracted('RETRACTED', isFirm: false);

  const ExpenseStatus(this.wireValue, {required this.isFirm});

  /// Valeur du contrat (`ExpenseStatus` de l'`openApi.yaml`).
  final String wireValue;

  /// Engagement ferme : approuvée et payée, elles seules, comptent comme de
  /// l'argent sorti.
  final bool isFirm;

  /// Lecture tolérante : une valeur inconnue devient [pending], le sens
  /// prudent — une demande qu'on ne sait pas lire n'est pas de l'argent
  /// engagé, et elle n'est pas non plus décidée.
  static ExpenseStatus fromWire(String? raw) {
    final value = raw?.trim().toUpperCase();
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return pending;
  }
}

/// Source des fonds — enregistrée pour la traçabilité, elle ne débite
/// **aucune** caisse en V1.
enum ExpenseFundingSource {
  cash('CASH'),
  bank('BANK'),
  mobileMoney('MOBILE_MONEY');

  const ExpenseFundingSource(this.wireValue);

  final String wireValue;

  /// `CASH` à défaut, comme le serveur.
  static ExpenseFundingSource fromWire(String? raw) {
    final value = raw?.trim().toUpperCase();
    for (final source in values) {
      if (source.wireValue == value) return source;
    }
    return cash;
  }
}

/// Où en est la remontée d'une dépense saisie sur ce poste.
///
/// Les valeurs de colonne sont celles du socle (`SyncState`) : le registre des
/// disparitions compare `sync_status` à `SYNCED` pour ne jamais effacer une
/// écriture locale non poussée.
enum ExpenseSyncState {
  /// Le serveur a accusé l'état affiché.
  synced('SYNCED'),

  /// Un geste attend dans la file d'écritures.
  pending('PENDING_SYNC'),

  /// Le serveur a refusé le dernier geste : la ligne est à corriger (A4).
  rejected('SYNC_ERROR');

  const ExpenseSyncState(this.dbValue);

  final String dbValue;

  /// Une valeur inconnue se lit « en attente » : jamais « accusée » sans
  /// preuve.
  static ExpenseSyncState fromDb(String? raw) {
    for (final state in values) {
      if (state.dbValue == raw) return state;
    }
    return pending;
  }
}

/// Les neuf actes du fil (F33) — **en anglais**, comme tout ce qui voyage déjà
/// dans ce module (`PAID`, `CASH`, `MOBILE_MONEY`). Les libellés affichés
/// restent en français, dans les `.arb`.
///
/// `null` n'est pas une valeur manquante : c'est le **commentaire libre**, le
/// seul message du fil qui ne constate aucun geste.
enum ExpenseAct {
  /// La demande est déposée — premier message de tout fil.
  deposit('DEPOSIT'),

  /// Le demandeur pousse : le compteur de relances monte d'un.
  reminder('REMINDER'),

  approval('APPROVAL'),

  /// Toujours motivé : un refus sans motif laisse le demandeur sans issue.
  refusal('REFUSAL'),

  payment('PAYMENT'),

  /// Reprise par son demandeur, réengageable après correction.
  retraction('RETRACTION'),

  /// La direction défait une décision : la demande revient en attente.
  reopening('REOPENING'),

  /// Corrigée puis renvoyée par son demandeur — deux gestes, un acte.
  correction('CORRECTION'),

  /// Modifiée sans changer d'état : elle était déjà en attente.
  edit('EDIT');

  const ExpenseAct(this.wireValue);

  final String wireValue;

  /// Lecture tolérante, et son défaut est **`null`** : un acte qu'on ne sait
  /// pas lire — un serveur plus récent que ce poste — se rend comme un
  /// commentaire libre. Le texte reste lisible, seule la vignette perd son
  /// nom. Le deviner serait pire : « Refus » affiché sur un acte inconnu
  /// mentirait sur ce qui s'est passé.
  static ExpenseAct? fromWire(String? raw) {
    final value = raw?.trim().toUpperCase();
    if (value == null || value.isEmpty) return null;
    for (final act in values) {
      if (act.wireValue == value) return act;
    }
    return null;
  }
}
