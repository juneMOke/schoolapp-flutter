/// Périmètre tarifaire d'un niveau, **source unique**.
///
/// Deux lectures interrogent `ref_fee_tariffs` sur le même critère et doivent le
/// faire à l'identique :
///  - la génération des créances (`FinanceChargeSeedDao`), qui décide de ce que
///    l'élève DOIT ;
///  - la liste des frais proposée au Contrôle des frais
///    (`FinanceLedgerReadDao.getTariffsForLevel`), qui décide de ce que l'on
///    peut CONTRÔLER.
///
/// Si les deux divergeaient, l'écran de contrôle offrirait un frais qu'aucune
/// créance ne porte (liste vide inexplicable) ou tairait un frais réellement dû.
/// D'où cette clause unique, partagée plutôt que recopiée.
///
/// Deux règles y sont encapsulées :
///  - **les tarifs de CYCLE comptent** : `school_level_id` NULL +
///    `school_level_group_id` renseigné vaut pour tous les niveaux du cycle ;
///  - **un tarif sans année vaut pour toutes les années** : la grille conserve
///    plusieurs saisons, et la purge du pull est scopée par année.
class FeeTariffScope {
  const FeeTariffScope._();

  /// Clause `WHERE` (sans le mot-clé) pour les tarifs applicables à un niveau.
  static String whereClause({String? schoolLevelGroupId}) {
    final levelClause = schoolLevelGroupId == null
        ? 'school_level_id = ?'
        : '(school_level_id = ? OR '
              '(school_level_id IS NULL AND school_level_group_id = ?))';
    return '$levelClause AND '
        '(academic_year_id = ? OR academic_year_id IS NULL)';
  }

  /// Arguments de [whereClause], dans l'ordre.
  static List<Object?> whereArgs({
    required String schoolLevelId,
    required String academicYearId,
    String? schoolLevelGroupId,
  }) => [schoolLevelId, ?schoolLevelGroupId, academicYearId];
}
