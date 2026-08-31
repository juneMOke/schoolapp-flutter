enum EnrollmentDetailOrigin {
  preRegistration,
  reRegistration,
  firstRegistration,
  newFirstRegistration,

  /// Reprise d'un **brouillon LOCAL** (sync_status=DRAFT) déjà persisté en base,
  /// ouvert depuis le listing pour être finalisé. Aucun seed, aucun GET serveur :
  /// l'agrégat est chargé depuis sqflite par `enrollmentId`.
  localDraftResume,

  /// Correction d'un dossier **déjà complété**, ouvert en lecture seule puis
  /// passé en édition. Même chargement local que [localDraftResume] — l'agrégat
  /// est en base — mais le dossier y est finalisé : sa ré-ouverture en brouillon
  /// n'a lieu qu'à la première sauvegarde d'étape, et le niveau y reste
  /// verrouillé (les créances sont déjà projetées sur sa grille).
  completedReedition,
}
