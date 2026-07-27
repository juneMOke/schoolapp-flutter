import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/academic_referential_rows.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

/// Peuple les tables de référence Inscription (`ref_school`,
/// `ref_academic_years`, `ref_school_level_groups`, `ref_school_levels`)
/// depuis le pull référentiel (bundle full always-200). Écriture seule,
/// alimentée par `EnrollmentPullRepositoryImpl`. La grille tarifaire du
/// bundle est confiée à `FinanceLocalDao.replaceTariffsForYears` (module
/// Facturation).
class EnrollmentReferentialDao {
  final Database _db;

  const EnrollmentReferentialDao(this._db);

  /// Applique le bundle référentiel : école, années `current`/`previous`,
  /// cycles, niveaux (D1/D2/D5).
  ///
  /// Le 200 du contrat renvoie **le bundle complet** (snapshot) : les cycles et
  /// niveaux des années couvertes par le bundle qui n'y figurent plus sont
  /// **purgés** (sinon une ligne supprimée côté serveur resterait fantôme pour
  /// toujours, le bundle always-200 étant re-caché en entier à chaque pull). La
  /// purge est
  /// **scopée aux années du bundle** (`current` + `previous` s'il est
  /// présent) — `ref_academic_years` n'est jamais purgée : une année qui
  /// sortirait du bundle (ex. `previous` redevenu `null`) doit survivre
  /// (références de la cohorte de réinscription). `is_current` est un
  /// snapshot : remis à zéro avant application, puis posé **d'après la
  /// position du slot** (`current`→1, `previous`→0), jamais depuis le
  /// booléen wire de `RefAcademicYearDto` (évite toute incohérence si le
  /// wire diverge de la position réelle du slot). [schoolId] est stampé sur
  /// chaque année (jamais attendu du payload serveur, cf.
  /// `CurrentUserContext`) — il scope la résolution courante/précédente sur
  /// un device multi-écoles. Renvoie le nombre de lignes écrites.
  Future<int> upsertReferential(
    ReferentialBundleDto bundle, {
    required int syncedAt,
    required String schoolId,
  }) async {
    final slots = [
      (yearBundle: bundle.current, isCurrent: true),
      if (bundle.previous != null)
        (yearBundle: bundle.previous!, isCurrent: false),
    ];

    final yearIds = <String>{
      for (final s in slots) s.yearBundle.academicYear.id,
      for (final s in slots)
        for (final g in s.yearBundle.schoolLevelGroups) g.academicYearId,
    }.toList(growable: false);
    final groupIds = [
      for (final s in slots)
        for (final g in s.yearBundle.schoolLevelGroups) g.id,
    ];
    final levelIds = [
      for (final s in slots)
        for (final l in s.yearBundle.schoolLevels) l.id,
    ];

    await _db.transaction((txn) async {
      // Scopé à CETTE école : sur un device multi-écoles, un pull pour
      // l'école B ne doit jamais désarmer l'`is_current` de l'école A déjà
      // en cache (revue adversariale — un `UPDATE` sans WHERE romprait la
      // résolution offline de l'année courante pour toutes les autres
      // écoles présentes localement).
      await txn.update(
        'ref_academic_years',
        {'is_current': 0},
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
      await _purgeScopedReferential(txn, yearIds, groupIds, levelIds);

      // `ref_school` : cache mono-ligne, réécrite en entier (delete + insert)
      // pour ne jamais laisser une ligne orpheline si l'`id` école change.
      await txn.delete('ref_school');
      await txn.insert('ref_school', {
        'id': bundle.school.id,
        'name': bundle.school.name,
        'country': bundle.school.country,
        'city': bundle.school.city,
        'district': bundle.school.district,
        'municipality': bundle.school.municipality,
        'address': bundle.school.address,
        'phone': bundle.school.phone,
        'email': bundle.school.email,
        'synced_at': syncedAt,
      });

      final batch = txn.batch();
      for (final s in slots) {
        final y = s.yearBundle.academicYear;
        batch.insert('ref_academic_years', {
          'id': y.id,
          'name': y.name,
          'start_date': y.startDate,
          'end_date': y.endDate,
          'is_current': s.isCurrent ? 1 : 0,
          'school_id': schoolId,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        for (final g in s.yearBundle.schoolLevelGroups) {
          batch.insert(
            'ref_school_level_groups',
            {
              'id': g.id,
              'name': g.name,
              'code': g.code,
              'period_type': g.periodType,
              'academic_year_id': g.academicYearId,
              'display_order': g.displayOrder,
              'synced_at': syncedAt,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        for (final l in s.yearBundle.schoolLevels) {
          batch.insert('ref_school_levels', {
            'id': l.id,
            'name': l.name,
            'code': l.code,
            'level_group_id': l.levelGroupId,
            'display_order': l.displayOrder,
            'split_into_classrooms': l.splitIntoClassrooms ? 1 : 0,
            'synced_at': syncedAt,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      await batch.commit(noResult: true);
    });
    return 1 + // ref_school
        slots.length +
        groupIds.length +
        levelIds.length;
  }

  /// Évacue cycles et niveaux disparus du snapshot, sans sortir du périmètre
  /// des années couvertes par le bundle (un bundle sans année n'autorise
  /// aucune purge — symétrique du garde `is_current`).
  Future<void> _purgeScopedReferential(
    Transaction txn,
    List<String> yearIds,
    List<String> bundleGroupIds,
    List<String> bundleLevelIds,
  ) async {
    if (yearIds.isEmpty) return;
    // Scope des cycles = cycles locaux des années du bundle ∪ cycles du bundle
    // (capturé AVANT la purge : les niveaux d'un cycle supprimé partent aussi).
    final localGroups = await txn.query(
      'ref_school_level_groups',
      columns: ['id'],
      where: 'academic_year_id IN (${sqlMarks(yearIds)})',
      whereArgs: yearIds,
    );
    final scopedGroupIds = <String>{
      for (final r in localGroups) r['id'] as String,
      ...bundleGroupIds,
    }.toList(growable: false);
    if (scopedGroupIds.isNotEmpty) {
      final keepLevels = bundleLevelIds.isEmpty
          ? ''
          : ' AND id NOT IN (${sqlMarks(bundleLevelIds)})';
      await txn.delete(
        'ref_school_levels',
        where: 'level_group_id IN (${sqlMarks(scopedGroupIds)})$keepLevels',
        whereArgs: [...scopedGroupIds, ...bundleLevelIds],
      );
    }
    final keepGroups = bundleGroupIds.isEmpty
        ? ''
        : ' AND id NOT IN (${sqlMarks(bundleGroupIds)})';
    await txn.delete(
      'ref_school_level_groups',
      where: 'academic_year_id IN (${sqlMarks(yearIds)})$keepGroups',
      whereArgs: [...yearIds, ...bundleGroupIds],
    );
  }

  /// Identité de l'école (`ref_school`, cache mono-ligne). `null` = référentiel
  /// non encore synchronisé.
  Future<SchoolRow?> getSchool() async {
    final rows = await _db.query('ref_school', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return SchoolRow(
      id: r['id'] as String,
      name: r['name'] as String,
      country: r['country'] as String?,
      city: r['city'] as String?,
      district: r['district'] as String?,
      municipality: r['municipality'] as String?,
      address: r['address'] as String?,
      phone: r['phone'] as String?,
      email: r['email'] as String?,
    );
  }

  /// `id` de l'année **courante** (`is_current = 1`) de [schoolId]. `null` =
  /// référentiel non encore synchronisé pour cette école (base fraîche, ou
  /// changement d'école sur un device partagé).
  Future<String?> findCurrentAcademicYearId(String schoolId) async {
    final rows = await _db.query(
      'ref_academic_years',
      columns: ['id'],
      where: 'school_id = ? AND is_current = 1',
      whereArgs: [schoolId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  /// `id` de l'année **précédente** de [schoolId] : la plus récente dont
  /// `start_date` précède strictement celui de l'année courante (résolution
  /// par comparaison de dates, PAS par un flag serveur — cf. décision FRONT).
  /// `null` = pas d'année courante résolue, ou aucune année antérieure connue.
  Future<String?> findPreviousAcademicYearId(String schoolId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT id FROM ref_academic_years
      WHERE school_id = ?
        AND is_current = 0
        AND start_date IS NOT NULL
        AND start_date < (
          SELECT start_date FROM ref_academic_years
          WHERE school_id = ? AND is_current = 1
          LIMIT 1
        )
      ORDER BY start_date DESC
      LIMIT 1
      ''',
      [schoolId, schoolId],
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String?;
  }

  /// Année scolaire complète par `id` (nom, dates, `is_current`). `null` = id
  /// inconnu du référentiel local.
  Future<AcademicYearRow?> getAcademicYearById(String id) async {
    final rows = await _db.query(
      'ref_academic_years',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return AcademicYearRow(
      id: r['id'] as String,
      name: r['name'] as String,
      startDate: r['start_date'] as String?,
      endDate: r['end_date'] as String?,
      isCurrent: (r['is_current'] as int) == 1,
    );
  }

  /// Cycles (`ref_school_level_groups`) de [academicYearId], triés par
  /// `display_order`.
  Future<List<SchoolLevelGroupRow>> getSchoolLevelGroups(
    String academicYearId,
  ) async {
    final rows = await _db.query(
      'ref_school_level_groups',
      where: 'academic_year_id = ?',
      whereArgs: [academicYearId],
      orderBy: 'display_order',
    );
    return [
      for (final r in rows)
        SchoolLevelGroupRow(
          id: r['id'] as String,
          name: r['name'] as String,
          code: r['code'] as String,
          periodType: r['period_type'] as String?,
          displayOrder: r['display_order'] as int,
        ),
    ];
  }

  /// Niveaux (`ref_school_levels`) dont `level_group_id` est dans [groupIds],
  /// triés par `display_order`. Liste vide → résultat vide (pas de requête).
  Future<List<SchoolLevelRow>> getSchoolLevelsByGroupIds(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return const [];
    final rows = await _db.query(
      'ref_school_levels',
      where: 'level_group_id IN (${sqlMarks(groupIds)})',
      whereArgs: groupIds,
      orderBy: 'display_order',
    );
    return [
      for (final r in rows)
        SchoolLevelRow(
          id: r['id'] as String,
          name: r['name'] as String,
          code: r['code'] as String,
          levelGroupId: r['level_group_id'] as String,
          displayOrder: r['display_order'] as int,
          splitIntoClassrooms: (r['split_into_classrooms'] as int) == 1,
        ),
    ];
  }

  /// Patch optimiste post-répartition (Classe) : le niveau [schoolLevelId]
  /// vient d'être réparti en classes côté serveur (appel online, pas de corps
  /// de réponse). Écrit directement la colonne déjà portée par le référentiel
  /// (`RefSchoolLevelDto.splitIntoClassrooms`) — reconfirmée sans conflit par
  /// le prochain pull, qui la retrouvera vraie côté serveur.
  Future<void> markSchoolLevelSplit(String schoolLevelId) async {
    await _db.update(
      'ref_school_levels',
      {'split_into_classrooms': 1},
      where: 'id = ?',
      whereArgs: [schoolLevelId],
    );
  }
}
