/// Les valeurs fermées du fichier du personnel, avec leur forme sur le fil.
///
/// **Toute lecture tolère l'inconnu** (`fromWire` rend `null`) : le serveur peut
/// ajouter une valeur sans release du poste, et une fiche ne doit pas devenir
/// illisible pour autant.
library;

/// Sexe, tel que la pièce d'identité le porte.
enum StaffSex implements _Wired {
  male('M'),
  female('F');

  const StaffSex(this.wire);
  @override
  final String wire;

  static StaffSex? fromWire(String? value) => _byWire(values, value);
}

/// Catégorie d'agent : elle décide des fonctions proposées, et le Pointage la
/// lit pour savoir qui il pointe.
enum StaffCategory implements _Wired {
  teacher('ENSEIGNANT'),
  administrative('ADMINISTRATIF'),
  support('APPUI');

  const StaffCategory(this.wire);
  @override
  final String wire;

  static StaffCategory? fromWire(String? value) => _byWire(values, value);
}

/// Statut du contrat : il décide des champs de rémunération exigés et des
/// pièces du dossier.
enum StaffContractKind implements _Wired {
  permanent('PERMANENT'),
  vacataire('VACATAIRE'),
  conventionne('CONVENTIONNE');

  const StaffContractKind(this.wire);
  @override
  final String wire;

  static StaffContractKind? fromWire(String? value) => _byWire(values, value);
}

/// Mode de paie d'un vacataire, et de lui seul. [hourly] dit au Pointage
/// d'afficher la saisie d'heures.
enum StaffPayMode implements _Wired {
  hourly('HEURES_PRESTEES'),
  monthlyFlat('FORFAIT_MENSUEL');

  const StaffPayMode(this.wire);
  @override
  final String wire;

  static StaffPayMode? fromWire(String? value) => _byWire(values, value);
}

/// Pièce du dossier d'un agent.
enum StaffDocumentCode implements _Wired {
  identity('ID'),
  diploma('DP'),
  appointmentLetter('LD'),
  decree('AN'),
  employmentContract('CT'),
  serviceContract('CP');

  const StaffDocumentCode(this.wire);
  @override
  final String wire;

  static StaffDocumentCode? fromWire(String? value) => _byWire(values, value);
}

/// Origine d'une pièce : numérisée par la tablette, ou importée.
enum StaffDocumentSource implements _Wired {
  scan('SCAN'),
  import('IMPORT');

  const StaffDocumentSource(this.wire);
  @override
  final String wire;

  static StaffDocumentSource? fromWire(String? value) => _byWire(values, value);
}

/// Où en est une ligne : sur la tablette seulement, refusée, ou au serveur.
enum StaffSyncState {
  synced('SYNCED'),
  pending('PENDING_SYNC'),
  failed('SYNC_ERROR');

  const StaffSyncState(this.dbValue);
  final String dbValue;

  /// Une valeur inconnue se lit comme « sur la tablette » : c'est l'état qui
  /// n'affirme rien de faux sur le serveur.
  static StaffSyncState fromDb(String? value) {
    for (final state in values) {
      if (state.dbValue == value) return state;
    }
    return StaffSyncState.pending;
  }
}

/// Une valeur fermée et sa forme sur le fil.
abstract interface class _Wired {
  String get wire;
}

T? _byWire<T extends _Wired>(List<T> values, String? wire) {
  if (wire == null) return null;
  for (final value in values) {
    if (value.wire == wire) return value;
  }
  return null;
}
