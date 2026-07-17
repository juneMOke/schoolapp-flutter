import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
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
  /// filtré par `school_level_id`, crée une créance provisoire DUE. `dueFallback`
  /// = academicYear.endDate (pré-caché). Renvoie les créances créées.
  Future<List<LocalStudentCharge>> initializeChargesForStudent({
    required String studentId,
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
    String? dueFallback,
    required int nowMs,
  }) async {
    final created = <StudentChargeLocalModel>[];
    await _db.transaction((txn) async {
      final tariffs = await txn.query(
        'ref_fee_tariffs',
        where: 'school_level_id = ?',
        whereArgs: [schoolLevelId],
      );
      for (final row in tariffs) {
        final tariff = FeeTariffLocalModel.fromMap(row);
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
          dueAt: tariff.dueAt ?? dueFallback,
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
        created.add(charge);
      }
    });
    return created.map((m) => m.toEntity()).toList();
  }
}
