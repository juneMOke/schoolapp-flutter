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

/// Les actes du fil (F33, plus les trois de la déclaration en v3) — **en anglais**, comme tout ce qui voyage déjà
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
  edit('EDIT'),

  /// Une dépense **déclarée** (v3) : payée tout de suite, visée ensuite.
  /// Premier message de son fil — une déclaration n'a pas de dépôt.
  declaration('DECLARATION'),

  /// Le promoteur vise une déclaration — terminal.
  visa('VISA'),

  /// Le promoteur signale une déclaration, toujours avec motif. Un simple
  /// signalement : la sortie de caisse reste.
  flag('FLAG');

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

/// Comment une dépense est née (v3) — **figé à la création**, jamais changé.
enum ExpenseMode {
  /// La demande d'avant : déposée, décidée, puis payée. Toute dépense
  /// antérieure à la v3 est de ce mode.
  authorization('AUTHORIZATION'),

  /// Payée tout de suite, sortie de la caisse à l'heure du décaissement, et
  /// visée **ensuite** par le promoteur. Photo du bon obligatoire.
  declaration('DECLARATION');

  const ExpenseMode(this.wireValue);

  final String wireValue;

  /// Absent ou inconnu se lit [authorization] : c'est ce que sont toutes les
  /// dépenses existantes, et ce qu'envoient les postes d'avant la v3 (F36).
  static ExpenseMode fromWire(String? raw) {
    final value = raw?.trim().toUpperCase();
    for (final mode in values) {
      if (mode.wireValue == value) return mode;
    }
    return authorization;
  }
}

/// Le contrôle **après coup** d'une déclaration — un second axe, jamais mêlé
/// au statut : un visa ne déplace pas l'argent, et le statut ne dit pas si
/// la dépense est visée.
enum ExpenseVisaStatus {
  /// Déclarée, pas encore contrôlée.
  pending('PENDING'),

  /// Visée par le promoteur — terminal : on ne revient pas sur un visa.
  visaed('VISAED'),

  /// Signalée avec motif ; reste visable, ce qui lève le signalement.
  flagged('FLAGGED');

  const ExpenseVisaStatus(this.wireValue);

  final String wireValue;

  /// `null` hors déclaration. Sur une déclaration, une valeur absente ou
  /// inconnue se lit [pending] : le sens prudent, « pas visée » (F36).
  static ExpenseVisaStatus? fromWire(String? raw, {required ExpenseMode mode}) {
    if (mode != ExpenseMode.declaration) return null;
    final value = raw?.trim().toUpperCase();
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return pending;
  }
}
