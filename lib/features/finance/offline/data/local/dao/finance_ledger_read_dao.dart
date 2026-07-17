import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Lectures du grand-livre Facturation (sqflite). Aucune écriture, aucune
/// transaction : le reste à payer se COMPOSE à la lecture, aucun solde stocké
/// n'est incrémenté (FRONT §5/§8).
class FinanceLedgerReadDao {
  final Database _db;

  const FinanceLedgerReadDao(this._db);

  /// Créances d'un élève avec le VRAI reste à payer, composé à la lecture
  /// (FRONT §5) : miroir serveur (`amount_paid`) + Σ des allocations des
  /// paiements de CE poste non encore remontés — `sync_status <> 'SYNCED'`, ce
  /// qui couvre PENDING_SYNC **ET** SYNC_ERROR (le cash d'un paiement en échec
  /// technique reste déduit → il ne réapparaît jamais « à payer »). Aucune
  /// colonne de solde stockée n'est lue : on dérive, on n'incrémente pas (§8).
  Future<List<LocalStudentCharge>> getChargesByStudent(String studentId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT sc.*,
             COALESCE((
               SELECT SUM(pa.amount_in_cents)
               FROM payment_allocations pa
               JOIN payments p ON p.id = pa.payment_id
               WHERE pa.student_charge_id = sc.id
                 AND p.sync_status <> ?
             ), 0) AS paid_pending
      FROM student_charges sc
      WHERE sc.student_id = ?
      ORDER BY sc.fee_code ASC
      ''',
      [SyncState.synced.dbValue, studentId],
    );
    return rows
        .map(
          (r) => StudentChargeLocalModel.fromMap(
            r,
          ).toEntity(paidPending: (r['paid_pending'] as int?) ?? 0),
        )
        .toList();
  }

  Future<List<LocalPayment>> getPaymentsByStudent(String studentId) async {
    final rows = await _db.query(
      'payments',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'paid_at DESC',
    );
    return rows.map((r) => PaymentLocalModel.fromMap(r).toEntity()).toList();
  }

  /// Imputations d'un paiement. Joint le paiement porteur pour replier **payeur**
  /// et **date** sur chaque ligne, exactement comme [getAllocationsByCharge] :
  /// les deux vues des imputations restent cohérentes (sinon cette voie
  /// afficherait « payeur inconnu / pas de date »). `payment_id` NOT NULL → le
  /// JOIN n'écarte aucune ligne ; colonnes du paiement préfixées `p_` pour ne
  /// pas masquer celles de `pa.*` lues par `fromMap`.
  Future<List<LocalPaymentAllocation>> getAllocationsByPayment(
    String paymentId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.*,
             p.paid_at           AS p_paid_at,
             p.payer_first_name  AS p_payer_first_name,
             p.payer_last_name   AS p_payer_last_name,
             p.payer_middle_name AS p_payer_middle_name
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      WHERE pa.payment_id = ?
      ORDER BY pa.fee_code ASC
      ''',
      [paymentId],
    );
    return rows
        .map(
          (r) => PaymentAllocationLocalModel.fromMap(r).toEntity(
            payerFirstName: (r['p_payer_first_name'] as String?) ?? '',
            payerLastName: (r['p_payer_last_name'] as String?) ?? '',
            payerMiddleName: r['p_payer_middle_name'] as String?,
            paidAt: r['p_paid_at'] as String?,
          ),
        )
        .toList();
  }

  /// Imputations portant sur une créance (détail d'un frais, FRONT §4).
  ///
  /// Joint le paiement porteur pour replier le **payeur** et la **date** sur
  /// chaque ligne (détail d'un frais §16 : montant + payeur + date). Une
  /// imputation référence toujours un paiement (`payment_id` NOT NULL) → le JOIN
  /// n'écarte aucune ligne. Colonnes du paiement préfixées `p_` pour ne pas
  /// masquer celles de `pa.*` lues par `fromMap`.
  Future<List<LocalPaymentAllocation>> getAllocationsByCharge(
    String chargeId,
  ) async {
    final rows = await _db.rawQuery(
      '''
      SELECT pa.*,
             p.paid_at           AS p_paid_at,
             p.payer_first_name  AS p_payer_first_name,
             p.payer_last_name   AS p_payer_last_name,
             p.payer_middle_name AS p_payer_middle_name
      FROM payment_allocations pa
      JOIN payments p ON p.id = pa.payment_id
      WHERE pa.student_charge_id = ?
      ORDER BY p.paid_at DESC, pa.fee_code ASC
      ''',
      [chargeId],
    );
    return rows
        .map(
          (r) => PaymentAllocationLocalModel.fromMap(r).toEntity(
            payerFirstName: (r['p_payer_first_name'] as String?) ?? '',
            payerLastName: (r['p_payer_last_name'] as String?) ?? '',
            payerMiddleName: r['p_payer_middle_name'] as String?,
            paidAt: r['p_paid_at'] as String?,
          ),
        )
        .toList();
  }

  Future<List<LocalFeeTariff>> getTariffsByLevel(String schoolLevelId) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      where: 'school_level_id = ?',
      whereArgs: [schoolLevelId],
    );
    return rows.map((r) => FeeTariffLocalModel.fromMap(r).toEntity()).toList();
  }
}
