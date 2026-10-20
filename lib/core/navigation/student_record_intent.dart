/// L'intention d'ouverture d'une fiche d'élève : son adresse porte ces deux
/// identifiants (`…/:studentId/:academicYearId`).
abstract interface class StudentRecordIntent {
  String get studentId;
  String get academicYearId;
}

/// L'`extra` de la navigation, s'il est bien l'intention de CETTE adresse ;
/// `null` sinon — la fiche se reconstruit alors depuis l'adresse.
///
/// Rendu tel quel, non recopié : un encaissement marqué « consommé » le reste
/// quand l'historique le rejoue. Et refusé s'il nomme un autre élève : après
/// un F5, l'historique du navigateur peut rendre l'`extra` d'une autre fiche,
/// et une fiche ne s'affiche jamais sous une identité qui n'est pas la sienne.
T? extraForRecord<T extends StudentRecordIntent>(
  Object? extra, {
  required String studentId,
  required String academicYearId,
}) =>
    extra is T &&
        extra.studentId == studentId &&
        extra.academicYearId == academicYearId
    ? extra
    : null;
