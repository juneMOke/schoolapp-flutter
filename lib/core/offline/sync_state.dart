// États et énumérations transverses du socle offline (persistés en TEXT dans
// sqflite). Suivent l'idiome projet `fromDbValue`/`toDbValue` (miroir de
// `fromApiValue`/`toApiValue`), valeurs exactes en SCREAMING_SNAKE_CASE.

/// Machine à états de synchro d'un agrégat métier (par dossier, paiement,
/// appel, cas disciplinaire…). Distinct du statut métier (`status`).
///
/// `DRAFT → PENDING_SYNC → SYNCED` ;
/// `PENDING_SYNC → SYNC_ERROR → PENDING_SYNC` (correction/re-push).
enum SyncState {
  draft('DRAFT'),
  pendingSync('PENDING_SYNC'),
  synced('SYNCED'),
  syncError('SYNC_ERROR');

  const SyncState(this.dbValue);

  final String dbValue;

  String toDbValue() => dbValue;

  static SyncState fromDbValue(String? value) => switch (value?.toUpperCase()) {
    'DRAFT' => SyncState.draft,
    'PENDING_SYNC' => SyncState.pendingSync,
    'SYNCED' => SyncState.synced,
    'SYNC_ERROR' => SyncState.syncError,
    _ => SyncState.pendingSync,
  };

  bool get isPending => this == SyncState.pendingSync;
  bool get isSynced => this == SyncState.synced;
  bool get isError => this == SyncState.syncError;
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
