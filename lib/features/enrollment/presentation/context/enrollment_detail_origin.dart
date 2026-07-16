enum EnrollmentDetailOrigin {
  preRegistration,
  reRegistration,
  firstRegistration,
  newFirstRegistration,

  /// Reprise d'un **brouillon LOCAL** (sync_status=DRAFT) déjà persisté en base,
  /// ouvert depuis le listing pour être finalisé. Aucun seed, aucun GET serveur :
  /// l'agrégat est chargé depuis sqflite par `enrollmentId`.
  localDraftResume,
}
