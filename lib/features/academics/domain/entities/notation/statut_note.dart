/// Statut d'une note d'élève pour une évaluation.
///
/// Sémantique (à titre informatif, cf. contrat backend) :
/// - [notee] : note comptée dans la moyenne ;
/// - [absentJustifie] : exclue du calcul ;
/// - [absentNonJustifie] : comptée 0 ;
/// - [enAttente] : rattrapage possible (typiquement `EN_ATTENTE → NOTEE`).
///
/// `unknown` est un repli de résilience pour toute valeur backend absente ou
/// inconnue. Le `null` du wire (`NoteEleveDto.statut` : « aucune saisie encore »)
/// est géré en amont par le modèle (mappé vers un `StatutNote?` nul), et n'est
/// donc pas confondu avec [unknown].
enum StatutNote { notee, absentJustifie, absentNonJustifie, enAttente, unknown }

extension StatutNoteX on StatutNote {
  static StatutNote fromApiValue(String? value) =>
      switch (value?.toUpperCase()) {
        'NOTEE' => StatutNote.notee,
        'ABSENT_JUSTIFIE' => StatutNote.absentJustifie,
        'ABSENT_NON_JUSTIFIE' => StatutNote.absentNonJustifie,
        'EN_ATTENTE' => StatutNote.enAttente,
        _ => StatutNote.unknown,
      };

  String toApiValue() => switch (this) {
    StatutNote.notee => 'NOTEE',
    StatutNote.absentJustifie => 'ABSENT_JUSTIFIE',
    StatutNote.absentNonJustifie => 'ABSENT_NON_JUSTIFIE',
    StatutNote.enAttente => 'EN_ATTENTE',
    StatutNote.unknown => 'UNKNOWN',
  };
}
