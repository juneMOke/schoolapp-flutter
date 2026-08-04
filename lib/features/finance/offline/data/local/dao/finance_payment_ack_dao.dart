import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_anomaly_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

/// Scope de résolution d'une créance : une clé métier `fee_code` n'est unique
/// que DANS une année (TUITION existe chaque saison).
class _PaymentScope {
  final String studentId;
  final String? academicYearId;

  const _PaymentScope({required this.studentId, this.academicYearId});
}

/// Application de l'ACK serveur d'un paiement (FF4) : remap des ids
/// provisoires→canoniques, UPSERT des créances autoritaires, scellement du reçu,
/// puis passage SYNCED — le tout dans une seule transaction (passage de témoin
/// atomique, ni trou ni double comptage).
class FinancePaymentAckDao {
  final Database _db;

  const FinancePaymentAckDao(this._db);

  /// Applique l'ACK (`openapi_billing_sync` §PaymentAggregateResponse) :
  /// paiement SYNCED, remap des ids provisoires→canoniques (allocations ET
  /// créances, par `studentId + feeCode`), UPSERT des créances autoritaires,
  /// puis scellement du reçu définitif. `201` (création) et `200` (rejeu
  /// idempotent) portent les mêmes valeurs canoniques → même traitement.
  Future<void> applyPaymentAck(
    PaymentAggregateResponse ack, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await _applyAllocationRemaps(txn, ack);
      await _applyAuthoritativeCharges(txn, ack, nowMs);
      await _sealDocuments(txn, ack);
      await _captureReceiptId(txn, ack);
      await _recordOverpaymentAnomaly(txn, ack, nowMs);

      // SYNCED **seulement si** le miroir autoritaire a été intégré. C'est le
      // sens exact du drapeau : `paid_pending` (FRONT §5) déduit les allocations
      // des paiements `sync_status <> 'SYNCED'`, donc passer SYNCED signifie
      // « mon `student_charges.amount_paid` porte déjà ce montant ». Sur un ACK
      // sans créance (violation du contrat — `charges` est `required`), le
      // stamp ferait sortir le montant du pending SANS que rien ne l'ait
      // intégré : la créance s'afficherait impayée et le caissier
      // **réencaisserait**. On laisse alors le paiement pending — le montant
      // reste déduit, sens de panne conservateur — et l'appelant réessaiera.
      //
      // Le passage de témoin est atomique : le stamp est dans la MÊME
      // transaction que l'intégration → ni trou, ni double comptage (§5/§8).
      if (ack.charges.isEmpty) return;
      await txn.update(
        'payments',
        {
          'sync_status': SyncState.synced.dbValue,
          'synced_at': nowMs,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [ack.paymentId],
      );
    });
  }

  /// Remap des allocations : le `feeCode` est porté par la réponse (plus besoin
  /// de le relire en local), et la créance canonique est garantie non nulle.
  /// L'année de scope vient du paiement (une allocation n'en porte pas).
  ///
  /// Seul `student_charge_id` est réécrit : l'uuid d'allocation est honoré par
  /// le serveur (spec §PaymentAllocationInput), et réécrire une clé primaire
  /// lèverait une violation UNIQUE — donc un rollback de TOUT l'ACK — si la
  /// ligne canonique a déjà été insérée par le pull des paiements (ACK perdu,
  /// puis rejeu). Un `canonicalId` divergent est donc ignoré, jamais appliqué.
  Future<void> _applyAllocationRemaps(
    DatabaseExecutor txn,
    PaymentAggregateResponse ack,
  ) async {
    final scope = await _paymentScope(txn, ack.paymentId);
    for (final remap in ack.allocations) {
      // Créance canonique absente (le serveur n'a pas su lier l'allocation) :
      // on saute CE remap sans toucher au lien local, et sans compromettre les
      // autres — l'ACK doit aller au bout.
      final canonicalChargeId = remap.canonicalStudentChargeId;
      if (canonicalChargeId == null) continue;
      if (scope != null) {
        await _remapProvisionalCharge(
          txn,
          studentId: scope.studentId,
          academicYearId: scope.academicYearId,
          feeCode: remap.feeCode,
          realChargeId: canonicalChargeId,
        );
      }
      await txn.update(
        'payment_allocations',
        {'student_charge_id': canonicalChargeId},
        where: 'id = ?',
        whereArgs: [remap.providedId],
      );
    }
  }

  /// Créances **recalculées, autoritaires** (même schéma que le pull) : on
  /// remplace le snapshot local (ADR-002).
  ///
  /// UPSERT et non UPDATE : le serveur peut renvoyer une créance que ce poste
  /// n'a jamais vue. D'où le garde-fou money-grade — avant d'insérer, on dissout
  /// l'éventuelle jumelle PROVISIONAL (même `student_id + fee_code`, uuid local
  /// différent, générée offline à l'inscription). Sans lui, l'insert créerait un
  /// doublon et l'élève semblerait devoir deux fois le même frais.
  Future<void> _applyAuthoritativeCharges(
    DatabaseExecutor txn,
    PaymentAggregateResponse ack,
    int nowMs,
  ) async {
    for (final ch in ack.charges) {
      await _remapProvisionalCharge(
        txn,
        studentId: ch.studentId,
        academicYearId: ch.academicYearId,
        feeCode: ch.feeCode,
        realChargeId: ch.id,
      );
      await txn.insert(
        'student_charges',
        ch.toLocalModel(nowMs).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Scellement du reçu définitif : le `documentNumber` serveur remplace le
  /// `PROV-…` local. `documents` **vide** est un cas NORMAL (scellement
  /// best-effort hors transaction serveur, décision G) : le reçu provisoire est
  /// alors conservé tel quel — l'encaissement reste acquis.
  ///
  /// `provisional_number` n'est **jamais** touché ici (v19) : il garde la trace
  /// du numéro imprimé sur le ticket déjà remis au parent. Sans lui, le
  /// scellement rendrait ce papier orphelin — or RG-012-12 fait de sa
  /// conservation par le parent le levier de rapprochement de l'établissement.
  Future<void> _sealDocuments(
    DatabaseExecutor txn,
    PaymentAggregateResponse ack,
  ) async {
    for (final doc in ack.documents) {
      await txn.update(
        'generated_documents',
        {'number': doc.documentNumber, 'status': doc.status},
        where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
        whereArgs: [ack.paymentId, 'PAYMENT', doc.localDocType],
      );
    }
  }

  /// Capte l'UUID de la pièce scellée (v19).
  ///
  /// Le serveur le renvoie depuis toujours — il était parsé puis jeté. C'est le
  /// SEUL identifiant permettant de re-télécharger un reçu définitif par
  /// `GET /editique/documents/{id}` : sans lui, la seule voie est de rejouer le
  /// POST d'émission. `null` est un cas normal, pour la même raison que
  /// `documents` vide : le scellement serveur est hors transaction.
  Future<void> _captureReceiptId(
    DatabaseExecutor txn,
    PaymentAggregateResponse ack,
  ) async {
    final receiptId = ack.receiptId;
    if (receiptId == null || receiptId.isEmpty) return;

    await txn.update(
      'payments',
      {'receipt_id': receiptId},
      where: 'id = ?',
      whereArgs: [ack.paymentId],
    );
  }

  /// Ouvre une anomalie de trop-perçu (ADR-012 D-5, amendé).
  ///
  /// Le signal existait depuis toujours et n'était consommé par personne. Il
  /// n'annule RIEN : le paiement est enregistré, le reçu scellé, le ticket du
  /// parent reste valide. Il ouvre une anomalie à arbitrer — et c'est pour cela
  /// qu'elle est écrite DANS la transaction d'ACK : l'entrée d'outbox
  /// correspondante sera supprimée à la fin du même flush, emportant avec elle
  /// la seule autre trace du signal.
  ///
  /// L'élève, le caissier et l'appareil sont recopiés depuis le paiement :
  /// l'alerte doit pouvoir nommer QUI a encaissé et sur QUELLE tablette, des
  /// jours plus tard, sans dépendre d'une jointure.
  Future<void> _recordOverpaymentAnomaly(
    DatabaseExecutor txn,
    PaymentAggregateResponse ack,
    int nowMs,
  ) async {
    final signal = ack.overpayment;
    if (signal == null || !signal.detected) return;

    final rows = await txn.query(
      'payments',
      columns: const [
        'student_id',
        'cashier_first_name',
        'cashier_last_name',
        'device_id',
      ],
      where: 'id = ?',
      whereArgs: [ack.paymentId],
      limit: 1,
    );
    final source = rows.isEmpty ? const <String, Object?>{} : rows.first;

    await PaymentAnomalyDao(txn).record(
      PaymentAnomaly(
        // Déterministe : un rejeu de l'ACK retombe sur la même clé, que l'index
        // unique (payment_id, kind) neutralise — sans jamais rouvrir une
        // anomalie déjà accusée.
        id: 'anomaly-${ack.paymentId}-${PaymentAnomalyKind.overpayment.dbValue}',
        paymentId: ack.paymentId,
        studentId: source['student_id'] as String?,
        kind: PaymentAnomalyKind.overpayment,
        excessInCents: signal.excessInCents,
        currency: signal.currency,
        feeCode: signal.feeCode,
        reason: signal.reason,
        cashierFirstName: source['cashier_first_name'] as String?,
        cashierLastName: source['cashier_last_name'] as String?,
        deviceId: source['device_id'] as String?,
        detectedAt: nowMs,
      ),
    );
  }

  /// (élève, année) du paiement — le scope de résolution des créances.
  Future<_PaymentScope?> _paymentScope(
    DatabaseExecutor txn,
    String paymentId,
  ) async {
    final rows = await txn.query(
      'payments',
      columns: ['student_id', 'academic_year_id'],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final studentId = rows.first['student_id'] as String?;
    if (studentId == null) return null;
    return _PaymentScope(
      studentId: studentId,
      academicYearId: rows.first['academic_year_id'] as String?,
    );
  }

  /// Remap d'une créance provisoire (uuid local) vers l'id réel serveur, résolu
  /// par (student_id, academic_year_id, fee_code) — clé stable (back FB-4).
  ///
  /// Deux garde-fous money-grade sur la résolution de la jumelle :
  ///  - **scopée à l'année** : `fee_code` seul n'est PAS unique dans le temps
  ///    (TUITION existe chaque année). La base offline survit au rollover : sans
  ///    ce scope, l'ACK d'une créance 2025-26 renommerait la créance 2024-25 et
  ///    ré-imputerait ses paiements sur la nouvelle année.
  ///  - **jamais une créance SYNCED** : seule une jumelle non encore remontée
  ///    (PROVISIONAL / PENDING_SYNC) peut être dissoute. Une ligne autoritaire
  ///    ne doit jamais être détruite par une résolution approximative — au pire
  ///    on laisse un doublon visible, jamais une perte de données.
  ///
  /// `academic_year_id` est comparé avec `IS` (null-safe). Une créance
  /// canonique sans année ne dissout donc aucune jumelle *datée* : on préfère
  /// un doublon à une destruction.
  ///
  /// Pendant du [FinanceLedgerSyncDao] `_dissolveProvisionalTwins` côté pull de
  /// masse : même invariant, contexte d'accès différent (ici par créance dans
  /// la transaction de l'ACK, là un index pré-calculé par lot).
  Future<void> _remapProvisionalCharge(
    DatabaseExecutor txn, {
    required String studentId,
    String? academicYearId,
    required String feeCode,
    required String realChargeId,
  }) async {
    // **Toutes** les jumelles, pas la première : `(student_id, année, fee_code)`
    // n'a aucune contrainte d'unicité et `initializeChargesForStudent` peut
    // avoir rejoué (crash, seconde passe de réinscription). Un `limit: 1` en
    // dissoudrait une et laisserait l'autre vivre à côté de la canonique — le
    // frais serait facturé deux fois. Même règle que `_pendingChargeIndex` côté
    // pull de masse.
    final twins = await txn.query(
      'student_charges',
      columns: ['id'],
      where:
          'student_id = ? AND fee_code = ? AND id != ? '
          'AND academic_year_id IS ? AND sync_status <> ?',
      whereArgs: [
        studentId,
        feeCode,
        realChargeId,
        academicYearId,
        SyncState.synced.dbValue,
      ],
    );
    if (twins.isEmpty) return;

    var realExists = (await txn.query(
      'student_charges',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [realChargeId],
      limit: 1,
    )).isNotEmpty;

    for (final row in twins) {
      final provId = row['id'] as String;
      // Les imputations suivent l'id serveur dans tous les cas.
      await txn.update(
        'payment_allocations',
        {'student_charge_id': realChargeId},
        where: 'student_charge_id = ?',
        whereArgs: [provId],
      );
      if (realExists) {
        await txn.delete(
          'student_charges',
          where: 'id = ?',
          whereArgs: [provId],
        );
      } else {
        // La canonique n'existe pas encore : on renomme la PREMIÈRE jumelle
        // pour préserver la ligne, les suivantes sont alors des doublons purs.
        // On ne la marque PAS SYNCED — un remap déplace un id, il ne constate
        // pas une autorité ; c'est l'UPSERT autoritaire qui apporte soldes ET
        // état.
        await txn.update(
          'student_charges',
          {'id': realChargeId},
          where: 'id = ?',
          whereArgs: [provId],
        );
        realExists = true;
      }
    }
  }
}
