import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/fee_tariff_scope.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Génération offline des créances d'un élève (FF5) : réplique le
/// `initialize-charges` serveur à partir de la grille tarifaire locale, en
/// PROVISIONAL (jamais poussée — le serveur la régénère à l'ACK de
/// l'inscription).
class FinanceChargeSeedDao {
  final Database _db;
  final IdGenerator _idGenerator;

  const FinanceChargeSeedDao(this._db, this._idGenerator);

  /// Réplique `initialize-charges` : pour chaque tarif de `ref_fee_tariffs`
  /// du niveau visé (tarifs de CYCLE inclus : `school_level_id` NULL +
  /// `school_level_group_id` renseigné), scopé sur l'année (`academic_year_id`
  /// = année du wizard OU NULL — la grille conserve plusieurs saisons), crée
  /// une créance provisoire DUE. `dueFallback` = academicYear.endDate ; s'il
  /// n'est pas fourni, il est résolu depuis `ref_academic_years` (pré-caché).
  ///
  /// **Idempotent par (élève, année), à granularité `fee_code`** — rappelable
  /// à chaque entrée sur l'étape Frais du wizard :
  ///  - une créance NON provisoire existe (pull/ACK, y compris à année NULL,
  ///    rattachable à la lecture par année) → no-op : le grand-livre
  ///    autoritaire a la main ;
  ///  - les provisoires d'un AUTRE niveau, sans allocation de paiement, sont
  ///    purgées (changement de niveau cible) ; celles déjà imputées sont
  ///    conservées (money-grade : on ne supprime jamais une créance payée) ;
  ///  - un tarif n'est inséré que si aucun `fee_code` identique ne subsiste
  ///    (ni doublon de frais dans l'année, ni régénération d'une ligne du
  ///    même niveau → ids stables entre deux visites, top-up des frais
  ///    ajoutés à la grille).
  ///
  /// Renvoie les créances de l'élève pour l'année (conservées + générées).
  Future<List<LocalStudentCharge>> initializeChargesForStudent({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
    required int nowMs,
  }) async {
    final result = <StudentChargeLocalModel>[];
    await _db.transaction((txn) async {
      // Année cible OU NULL : les lectures par année (ledger) rattachent les
      // créances à année NULL — le garde-fou doit voir le même périmètre.
      final existingRows = await txn.query(
        'student_charges',
        where:
            'student_id = ? AND (academic_year_id = ? OR academic_year_id IS NULL)',
        whereArgs: [studentId, academicYearId],
      );
      final existing = existingRows
          .map(StudentChargeLocalModel.fromMap)
          .toList();

      final hasAuthoritative = existing.any(
        (c) => c.syncStatus != SyncState.provisional.dbValue,
      );
      if (hasAuthoritative) {
        result.addAll(existing);
        return;
      }

      // Purge des provisoires d'un AUTRE niveau et sans allocation ; tout le
      // reste est conservé (mêmes ids entre deux visites → aucune allocation
      // orpheline, aucune régénération d'une ligne déjà en place).
      final kept = <StudentChargeLocalModel>[];
      for (final charge in existing) {
        if (charge.schoolLevelId == schoolLevelId) {
          kept.add(charge);
          continue;
        }
        final allocations = await txn.query(
          'payment_allocations',
          columns: ['id'],
          where: 'student_charge_id = ?',
          whereArgs: [charge.id],
          limit: 1,
        );
        if (allocations.isEmpty) {
          await txn.delete(
            'student_charges',
            where: 'id = ?',
            whereArgs: [charge.id],
          );
        } else {
          kept.add(charge);
        }
      }

      final fallback =
          dueFallback ?? await _findAcademicYearEndDate(txn, academicYearId);
      final tariffs = await _queryTariffs(
        txn,
        academicYearId: academicYearId,
        schoolLevelId: schoolLevelId,
        schoolLevelGroupId: schoolLevelGroupId,
      );
      // Granularité fee_code : jamais deux créances du même frais dans
      // l'année (invariant « fee_code unique DANS une année »).
      final coveredFeeCodes = kept.map((c) => c.feeCode).toSet();
      for (final row in tariffs) {
        final tariff = FeeTariffLocalModel.fromMap(row);
        if (!coveredFeeCodes.add(tariff.feeCode)) continue;
        final charge = StudentChargeLocalModel(
          id: _idGenerator.newId(),
          studentId: studentId,
          academicYearId: academicYearId,
          schoolLevelId: schoolLevelId,
          schoolLevelGroupId: schoolLevelGroupId,
          feeTariffId: tariff.id,
          feeCode: tariff.feeCode,
          label: tariff.label,
          expectedAmountInCents: tariff.amountInCents,
          currency: tariff.currency,
          status: 'DUE',
          dueAt: tariff.dueAt ?? fallback,
          // PROVISIONAL (≠ PENDING_SYNC) : jamais poussée, aucune entrée outbox
          // (FRONT §5.2). Le serveur la régénère à l'ACK de l'inscription.
          syncStatus: SyncState.provisional.dbValue,
          updatedAt: nowMs,
        );
        await txn.insert(
          'student_charges',
          charge.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        result.add(charge);
      }
      result.addAll(kept);
    });
    return result.map((m) => m.toEntity()).toList();
  }

  /// Tarifs applicables : ceux du niveau visé + ceux définis au CYCLE seul
  /// (`school_level_id` NULL), scopés année-du-wizard-ou-NULL (la grille peut
  /// conserver plusieurs saisons — purge du pull scopée par année).
  /// La grille tarifaire est-elle présente **sur cet appareil** pour cette
  /// année ? Distingue les deux causes d'une liste de créances vide, qui se
  /// ressemblent à l'écran et pas au guichet :
  ///  - table vide pour l'année → le référentiel n'a pas été hydraté (le
  ///    serveur caviarde `feeTariffs` pour qui n'a pas `finance.grid.read`,
  ///    et le pull laisse alors `ref_academic_years` peuplée mais la grille
  ///    absente) → il n'y a rien à annoncer, il faut synchroniser ;
  ///  - table peuplée mais aucun tarif pour ce niveau → information réelle,
  ///    ce niveau n'a pas de frais.
  ///
  /// Même clause d'année que [_queryTariffs] : la grille conserve plusieurs
  /// saisons, et un tarif à année NULL vaut pour toutes.
  Future<bool> hasAnyTariffForYear(String academicYearId) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      columns: ['id'],
      where: 'academic_year_id = ? OR academic_year_id IS NULL',
      whereArgs: [academicYearId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Map<String, Object?>>> _queryTariffs(
    DatabaseExecutor txn, {
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) {
    // Périmètre partagé avec la lecture du Contrôle des frais : ce que l'élève
    // DOIT et ce que l'on peut CONTRÔLER se lisent sur la même clause.
    return txn.query(
      'ref_fee_tariffs',
      where: FeeTariffScope.whereClause(schoolLevelGroupId: schoolLevelGroupId),
      whereArgs: FeeTariffScope.whereArgs(
        schoolLevelId: schoolLevelId,
        academicYearId: academicYearId,
        schoolLevelGroupId: schoolLevelGroupId,
      ),
    );
  }

  Future<String?> _findAcademicYearEndDate(
    DatabaseExecutor txn,
    String academicYearId,
  ) async {
    final rows = await txn.query(
      'ref_academic_years',
      columns: ['end_date'],
      where: 'id = ?',
      whereArgs: [academicYearId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['end_date'] as String?;
  }
}
