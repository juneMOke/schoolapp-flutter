/// Les valeurs fermées du fichier du personnel, avec leur forme sur le fil.
///
/// **Toute lecture tolère l'inconnu** (`fromWire` rend `null`) : le serveur peut
/// ajouter une valeur sans release du poste, et une fiche ne doit pas devenir
/// illisible pour autant.
library;

/// Sexe, tel que la pièce d'identité le porte.
enum StaffSex implements StaffWired {
  male('M'),
  female('F');

  const StaffSex(this.wire);
  @override
  final String wire;

  static StaffSex? fromWire(String? value) => staffByWire(values, value);
}

/// Catégorie d'agent : elle décide des fonctions proposées, et le Pointage la
/// lit pour savoir qui il pointe.
enum StaffCategory implements StaffWired {
  teacher('ENSEIGNANT'),
  administrative('ADMINISTRATIF'),
  support('APPUI');

  const StaffCategory(this.wire);
  @override
  final String wire;

  static StaffCategory? fromWire(String? value) => staffByWire(values, value);
}

/// Statut du contrat : il décide des champs de rémunération exigés et des
/// pièces du dossier.
enum StaffContractKind implements StaffWired {
  permanent('PERMANENT'),
  vacataire('VACATAIRE'),
  conventionne('CONVENTIONNE');

  const StaffContractKind(this.wire);
  @override
  final String wire;

  static StaffContractKind? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Mode de paie d'un vacataire, et de lui seul. [hourly] dit au Pointage
/// d'afficher la saisie d'heures.
enum StaffPayMode implements StaffWired {
  hourly('HEURES_PRESTEES'),
  monthlyFlat('FORFAIT_MENSUEL');

  const StaffPayMode(this.wire);
  @override
  final String wire;

  static StaffPayMode? fromWire(String? value) => staffByWire(values, value);
}

/// Pièce du dossier d'un agent.
enum StaffDocumentCode implements StaffWired {
  identity('ID'),
  diploma('DP'),
  appointmentLetter('LD'),
  decree('AN'),
  employmentContract('CT'),
  serviceContract('CP');

  const StaffDocumentCode(this.wire);
  @override
  final String wire;

  static StaffDocumentCode? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Origine d'une pièce : numérisée par la tablette, ou importée.
enum StaffDocumentSource implements StaffWired {
  scan('SCAN'),
  import('IMPORT');

  const StaffDocumentSource(this.wire);
  @override
  final String wire;

  static StaffDocumentSource? fromWire(String? value) =>
      staffByWire(values, value);
}

/// Une valeur fermée et sa forme sur le fil. Publique pour que les autres
/// valeurs fermées du module RH (le Pointage) se lisent de la même façon.
abstract interface class StaffWired {
  String get wire;
}

/// La valeur de [values] portant [wire], ou `null` (inconnue ou absente).
T? staffByWire<T extends StaffWired>(List<T> values, String? wire) {
  if (wire == null) return null;
  for (final value in values) {
    if (value.wire == wire) return value;
  }
  return null;
}
