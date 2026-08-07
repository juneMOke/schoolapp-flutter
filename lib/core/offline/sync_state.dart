// États et énumérations transverses du socle offline (persistés en TEXT dans
// sqflite). Suivent l'idiome projet `fromDbValue`/`toDbValue` (miroir de
// `fromApiValue`/`toApiValue`), valeurs exactes en SCREAMING_SNAKE_CASE.

/// Machine à états de synchro d'un agrégat métier (par dossier, paiement,
/// appel, cas disciplinaire…). Distinct du statut métier (`status`).
///
/// `DRAFT → PENDING_SYNC → SYNCED` ;
/// `PENDING_SYNC → SYNC_ERROR → PENDING_SYNC` (correction/re-push).
///
/// `PROVISIONAL` est un état **à part** (Facturation) : une créance locale d'un
/// nouvel élève, générée depuis la grille tarifaire à la confirmation de
/// l'inscription. Elle n'est **jamais poussée** (aucune entrée outbox) — elle
/// attend d'être **remplacée** par la créance autoritaire du serveur au sync,
/// pas d'être envoyée. À ne pas confondre avec `PENDING_SYNC` (qui, lui,
/// signale « à synchroniser »). Cf. FRONT §5.2.
enum SyncState {
  draft('DRAFT'),
  pendingSync('PENDING_SYNC'),
  synced('SYNCED'),
  syncError('SYNC_ERROR'),
  provisional('PROVISIONAL');

  const SyncState(this.dbValue);

  final String dbValue;

  String toDbValue() => dbValue;

  static SyncState fromDbValue(String? value) => switch (value?.toUpperCase()) {
    'DRAFT' => SyncState.draft,
    'PENDING_SYNC' => SyncState.pendingSync,
    'SYNCED' => SyncState.synced,
    'SYNC_ERROR' => SyncState.syncError,
    'PROVISIONAL' => SyncState.provisional,
    _ => SyncState.pendingSync,
  };

  bool get isPending => this == SyncState.pendingSync;
  bool get isSynced => this == SyncState.synced;
  bool get isError => this == SyncState.syncError;
  bool get isProvisional => this == SyncState.provisional;
}

/// Statut technique d'une entrée d'outbox (file de push).
enum OutboxStatus {
  pending('PENDING'),
  acked('ACKED'),
  syncError('SYNC_ERROR');

  const OutboxStatus(this.dbValue);

  final String dbValue;

  String toDbValue() => dbValue;

  static OutboxStatus fromDbValue(String? value) =>
      switch (value?.toUpperCase()) {
        'PENDING' => OutboxStatus.pending,
        'ACKED' => OutboxStatus.acked,
        'SYNC_ERROR' => OutboxStatus.syncError,
        _ => OutboxStatus.pending,
      };
}

/// Opération portée par une entrée d'outbox.
enum OutboxOperation {
  create('CREATE'),
  update('UPDATE'),
  upsert('UPSERT');

  const OutboxOperation(this.dbValue);

  final String dbValue;

  String toDbValue() => dbValue;

  static OutboxOperation fromDbValue(String? value) =>
      switch (value?.toUpperCase()) {
        'CREATE' => OutboxOperation.create,
        'UPDATE' => OutboxOperation.update,
        'UPSERT' => OutboxOperation.upsert,
        _ => OutboxOperation.create,
      };
}
