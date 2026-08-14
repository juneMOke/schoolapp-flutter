import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/generated_document_local_model.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/fee_tariff_scope.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
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

  /// Reçu (RC) d'un paiement, tel qu'il est connu **localement**.
  ///
  /// Le numéro vaut `PROV-…` tant que l'encaissement n'est pas synchronisé,
  /// puis le scellement à l'ACK le remplace par le `ETL-RC-…` définitif — d'où
  /// [LocalGeneratedDocument.isProvisional], qui dit à l'UI si le numéro
  /// affichable fait foi.
  ///
  /// `null` est un cas NORMAL et non une erreur : le scellement serveur est
  /// best-effort et hors transaction, et un paiement arrivé par pull depuis
  /// l'autre poste n'a jamais eu de ligne locale.
  Future<LocalGeneratedDocument?> getPaymentReceipt(String paymentId) async {
    final rows = await _db.query(
      'generated_documents',
      where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
      whereArgs: [paymentId, 'PAYMENT', 'RC'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return GeneratedDocumentLocalModel.fromMap(rows.first).toEntity();
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

  /// Grille applicable à un niveau **sur une année** (Contrôle des frais).
  ///
  /// Contrairement à [getTariffsByLevel], qui ne connaît que le niveau exact,
  /// cette lecture applique le périmètre complet ([FeeTariffScope]) : tarifs de
  /// cycle inclus, année-ou-NULL. C'est le MÊME périmètre que celui qui a généré
  /// les créances — sans quoi l'écran offrirait un frais que personne ne doit.
  Future<List<LocalFeeTariff>> getTariffsForLevel({
    required String academicYearId,
    required String schoolLevelId,
    String? schoolLevelGroupId,
  }) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      where: FeeTariffScope.whereClause(schoolLevelGroupId: schoolLevelGroupId),
      whereArgs: FeeTariffScope.whereArgs(
        schoolLevelId: schoolLevelId,
        academicYearId: academicYearId,
        schoolLevelGroupId: schoolLevelGroupId,
      ),
      orderBy: 'fee_code ASC',
    );
    return rows.map((r) => FeeTariffLocalModel.fromMap(r).toEntity()).toList();
  }

  /// Position des élèves [studentIds] sur le frais [feeCode] (Contrôle des
  /// frais) : attendu, miroir serveur et **payé en attente composé à la
  /// lecture** — mêmes règles que [getChargesByStudent], une seule requête.
  ///
  /// Le frais est joint par `fee_code` et non par `fee_tariff_id` : ce dernier
  /// est nullable au pull, alors que `fee_code` est l'invariant « unique dans
  /// une année » sur lequel repose déjà la génération des créances.
  ///
  /// `academic_year_id IS NULL` est inclus : une créance sans année appartient à
  /// toutes les années (cf. `LocalStudentCharge.belongsToYear`).
  ///
  /// Bornée par `student_id IN (…)` — l'index `idx_student_charges_student_fee`
  /// travaille, et aucun bump de schéma n'est nécessaire. Les identifiants sont
  /// envoyés par lots pour rester sous la limite de variables liées de SQLite.
  Future<List<LocalFeeChargeAggregate>> getFeeChargeAggregates({
    required String academicYearId,
    required String feeCode,
    required List<String> studentIds,
  }) async {
    if (studentIds.isEmpty) return const <LocalFeeChargeAggregate>[];

    final aggregates = <LocalFeeChargeAggregate>[];
    for (var start = 0; start < studentIds.length; start += _idBatchSize) {
      final end = start + _idBatchSize < studentIds.length
          ? start + _idBatchSize
          : studentIds.length;
      final batch = studentIds.sublist(start, end);
      final placeholders = List.filled(batch.length, '?').join(', ');

      final rows = await _db.rawQuery(
        '''
        SELECT sc.student_id                    AS student_id,
               SUM(sc.expected_amount_in_cents) AS expected,
               SUM(sc.amount_paid_in_cents)     AS paid_mirror,
               SUM(COALESCE((
                 SELECT SUM(pa.amount_in_cents)
                 FROM payment_allocations pa
                 JOIN payments p ON p.id = pa.payment_id
                 WHERE pa.student_charge_id = sc.id
                   AND p.sync_status <> ?
               ), 0))                           AS paid_pending,
               MIN(sc.currency)                 AS currency
        FROM student_charges sc
        WHERE sc.fee_code = ?
          AND (sc.academic_year_id = ? OR sc.academic_year_id IS NULL)
          AND sc.student_id IN ($placeholders)
        GROUP BY sc.student_id
        ''',
        [SyncState.synced.dbValue, feeCode, academicYearId, ...batch],
      );

      aggregates.addAll(
        rows.map(
          (r) => LocalFeeChargeAggregate(
            studentId: r['student_id'] as String,
            expectedInCents: (r['expected'] as int?) ?? 0,
            paidMirrorInCents: (r['paid_mirror'] as int?) ?? 0,
            paidPendingInCents: (r['paid_pending'] as int?) ?? 0,
            currency: (r['currency'] as String?) ?? '',
          ),
        ),
      );
    }
    return aggregates;
  }

  /// Taille des lots d'identifiants. SQLite plafonne les variables liées d'une
  /// requête (999 par défaut) : on garde de la marge pour les 3 autres.
  static const int _idBatchSize = 500;
}
