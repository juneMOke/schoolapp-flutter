/// Statut d'une dépense — binaire en V1 (ni approbation ni annulation : une
/// saisie erronée se **retire**).
///
/// Une énumération plutôt qu'un booléen : un statut ajouté en V2 ne touchera
/// ni le filtre ni la pastille, qui itèrent sur [values].
enum ExpenseStatus {
  paid('PAID'),
  unpaid('UNPAID');

  const ExpenseStatus(this.wireValue);

  /// Valeur du contrat (`ExpenseStatus` de l'`openApi.yaml`).
  final String wireValue;

  /// Lecture tolérante : une valeur inconnue devient `unpaid`, le sens
  /// prudent — une dépense qu'on ne sait pas lire n'est pas comptée réglée.
  static ExpenseStatus fromWire(String? raw) {
    final value = raw?.trim().toUpperCase();
    return value == paid.wireValue ? paid : unpaid;
  }

  ExpenseStatus get toggled => this == paid ? unpaid : paid;
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
