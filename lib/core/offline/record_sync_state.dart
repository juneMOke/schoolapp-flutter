/// Où en est une ligne métier, vue de la tablette : écrite ici seulement,
/// refusée par le serveur, ou au serveur. C'est ce que dit une pastille de
/// synchro ; la machine complète d'un agrégat reste `SyncState`.
enum RecordSyncState {
  synced('SYNCED'),
  pending('PENDING_SYNC'),
  failed('SYNC_ERROR');

  const RecordSyncState(this.dbValue);
  final String dbValue;

  /// Une valeur inconnue se lit comme « sur la tablette » : c'est l'état qui
  /// n'affirme rien de faux sur le serveur.
  static RecordSyncState fromDb(String? value) {
    for (final state in values) {
      if (state.dbValue == value) return state;
    }
    return RecordSyncState.pending;
  }
}
