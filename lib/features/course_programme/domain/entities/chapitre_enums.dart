/// État d'avancement d'un chapitre, choisi par le professeur. Cocher des
/// objectifs ne le change jamais.
enum ChapitreStatut {
  planifie('PLANIFIE'),
  enCours('EN_COURS'),
  termine('TERMINE');

  const ChapitreStatut(this.wireValue);

  /// Valeur du fil et de la base.
  final String wireValue;

  /// Valeur inconnue ⇒ `planifie`, le défaut de création.
  static ChapitreStatut fromWire(String? value) => values.firstWhere(
    (s) => s.wireValue == value,
    orElse: () => ChapitreStatut.planifie,
  );
}

/// Type d'un bloc du contenu rédigé.
enum ChapitreBlocType {
  titre('titre'),
  paragraphe('paragraphe'),
  liste('liste'),
  encadre('encadre'),
  exemple('exemple');

  const ChapitreBlocType(this.wireValue);

  final String wireValue;

  /// Valeur inconnue ⇒ `paragraphe` : un bloc venu d'un serveur plus récent
  /// reste lisible plutôt que de disparaître.
  static ChapitreBlocType fromWire(String? value) => values.firstWhere(
    (t) => t.wireValue == value,
    orElse: () => ChapitreBlocType.paragraphe,
  );
}

/// Nature d'une ressource : un fichier, une adresse, une référence de manuel.
enum RessourceType {
  document('document'),
  lien('lien'),
  manuel('manuel');

  const RessourceType(this.wireValue);

  final String wireValue;

  static RessourceType fromWire(String? value) => values.firstWhere(
    (t) => t.wireValue == value,
    orElse: () => RessourceType.manuel,
  );
}

/// Où en est l'envoi d'un élément du programme saisi sur la tablette.
enum ProgrammeSyncState {
  /// Le serveur a la dernière version.
  synced,

  /// Une écriture locale attend son envoi.
  pending,

  /// Le serveur a refusé la dernière écriture : à corriger.
  rejected,
}
