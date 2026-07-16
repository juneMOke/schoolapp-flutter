import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

/// Peuple les tables de référence Inscription (`ref_academic_years`,
/// `ref_school_level_groups`, `ref_school_levels`) depuis le pull référentiel
/// (bundle full always-200). Écriture seule, alimentée par
/// `EnrollmentPullRepositoryImpl`. La grille tarifaire du bundle est confiée à
/// `FinanceLocalDao.replaceTariffsForYears` (module Facturation).
class EnrollmentReferentialDao {
  final Database _db;

  const EnrollmentReferentialDao(this._db);

  /// Applique le bundle référentiel : années, cycles, niveaux (D1/D2).
  ///
  /// Le 200 du contrat renvoie **le bundle complet** (snapshot) : les cycles et
  /// niveaux des années couvertes par le bundle qui n'y figurent plus sont
  /// **purgés** (sinon une ligne supprimée côté serveur resterait fantôme pour
  /// toujours, le bundle always-200 étant re-caché en entier à chaque pull). La
  /// purge est
  /// **scopée aux années du bundle** — `ref_academic_years` n'est jamais
  /// purgée : le bundle est restreint à l'année active, or l'année N-1 doit
  /// survivre (références de la cohorte de réinscription). `is_current` est un
  /// snapshot : remis à zéro avant application pour ne jamais garder deux
  /// années « courantes ». Renvoie le nombre de lignes écrites.
  Future<int> upsertReferential(
    ReferentialBundleDto bundle, {
    required int syncedAt,
  }) async {
    final yearIds = <String>{
      for (final y in bundle.academicYears) y.id,
      for (final g in bundle.schoolLevelGroups) g.academicYearId,
    }.toList(growable: false);
    final groupIds = [for (final g in bundle.schoolLevelGroups) g.id];
    final levelIds = [for (final l in bundle.schoolLevels) l.id];

    await _db.transaction((txn) async {
      if (bundle.academicYears.isNotEmpty) {
        await txn.update('ref_academic_years', {'is_current': 0});
      }
      await _purgeScopedReferential(txn, yearIds, groupIds, levelIds);
      final batch = txn.batch();
      for (final y in bundle.academicYears) {
        batch.insert('ref_academic_years', {
          'id': y.id,
          'name': y.name,
          'start_date': y.startDate,
          'end_date': y.endDate,
          'is_current': y.isCurrent ? 1 : 0,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final g in bundle.schoolLevelGroups) {
        batch.insert('ref_school_level_groups', {
          'id': g.id,
          'name': g.name,
          'code': g.code,
          'period_type': g.periodType,
          'academic_year_id': g.academicYearId,
          'display_order': g.displayOrder,
          'synced_at': syncedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final l in bundle.schoolLevels) {
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
      await batch.commit(noResult: true);
    });
    return bundle.academicYears.length +
        bundle.schoolLevelGroups.length +
        bundle.schoolLevels.length;
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
}
