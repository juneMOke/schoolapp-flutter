import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/db_batching.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Scope de résolution d'une créance : une clé métier `fee_code` n'est unique
/// que DANS une année (TUITION existe chaque saison).
class _PaymentScope {
  final String studentId;
  final String? academicYearId;

  const _PaymentScope({required this.studentId, this.academicYearId});
}

/// Clé métier d'une créance : `(élève, année, poste)`. `fee_code` n'est unique
/// que DANS une année.
///
/// Un **record**, pas une chaîne jointe : l'égalité est structurelle, donc
/// aucun délimiteur à choisir (un `studentId` contenant le séparateur ne peut
/// pas provoquer de collision) et `null` reste distinct de `''` — la même
/// sémantique que le `academic_year_id IS ?` du SQL, alors qu'un
/// `'$a|${year ?? ''}|$c'` les confondait.
typedef _ChargeKey = (String studentId, String? academicYearId, String feeCode);

/// DAO local du module Facturation (sqflite). Lectures du grand-livre, geste
/// d'encaissement money-grade (FF3), remap à l'ACK (FF4), génération de
/// créances offline (FF5), upserts autoritaires du pull (FF2).
class FinanceLocalDao {
  final Database _db;
  final IdGenerator _idGenerator;

  const FinanceLocalDao(this._db, this._idGenerator);

  // ── Encaissement local-first (FF3) ─────────────────────────────────────────

  /// Insère un paiement + ses allocations (append-only), émet un RC provisoire
  /// et enfile l'outbox(PAYMENT). N'écrit RIEN dans `student_charges` : le reste
  /// à payer se compose à la lecture (FRONT §6.2/§8). Retour immédiat.
  Future<void> recordPayment({
    required PaymentLocalModel payment,
    required List<PaymentAllocationLocalModel> allocations,
    GeneratedDocumentLocalModel? receipt,
    required String outboxEntryId,
    String? schoolId,
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'payments',
        payment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Re-résolues AVANT tout écrit : le local ET le payload d'outbox doivent
      // porter le même lien — pousser un uuid de créance mort ferait diverger
      // le diagnostic serveur du miroir local.
      final linked = [
        for (final alloc in allocations)
          await _resolveChargeLink(txn, payment, alloc),
      ];

      for (final alloc in linked) {
        await txn.insert(
          'payment_allocations',
          alloc.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // AUCUN UPDATE student_charges (FRONT §6.2/§8) : ni le miroir
        // autoritaire, ni un compteur optimiste. Le reste se COMPOSE à la
        // lecture (getChargesByStudent) depuis les allocations des paiements
        // encore `sync_status <> 'SYNCED'` — auto-cicatrisant, on dérive, on
        // n'incrémente jamais.
      }

      if (receipt != null) {
        await txn.insert(
          'generated_documents',
          receipt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final request = _paymentRequest(payment, linked);
      final entry = OutboxEntry(
        id: outboxEntryId,
        aggregateType: 'PAYMENT',
        aggregateId: payment.id,
        operation: OutboxOperation.create,
        payload: jsonEncode(request.toJson()),
        schoolId: schoolId,
        createdAt: nowMs,
      );
      await OutboxDao(txn).enqueue(entry);
    });
  }

  /// Rattache l'imputation à une créance qui EXISTE encore, au moment de
  /// l'écriture.
  ///
  /// L'UI peut détenir un uuid PROVISIONAL périmé : elle a chargé la liste des
  /// frais, puis un pull a dissous la jumelle au profit de l'id canonique
  /// pendant que le caissier remplissait le formulaire. Écrire cet uuid mort
  /// sortirait l'imputation du `paid_pending` (`pa.student_charge_id = sc.id` ne
  /// matche plus) : le reçu est imprimé mais la créance réaffiche le montant
  /// entier — le parent peut payer deux fois.
  ///
  /// On re-résout donc par la clé MÉTIER `(élève, année, fee_code)`, stable là
  /// où l'uuid ne l'est pas. Sans cible locale, on renvoie `null` plutôt qu'un
  /// id mort : c'est la sémantique du contrat (« créance pas encore
  /// matérialisée ») et le serveur remappera par `studentId + feeCode`.
  Future<PaymentAllocationLocalModel> _resolveChargeLink(
    DatabaseExecutor txn,
    PaymentLocalModel payment,
    PaymentAllocationLocalModel alloc,
  ) async {
    final target = alloc.studentChargeId;
    if (target == null) return alloc;

    final alive = await txn.query(
      'student_charges',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [target],
      limit: 1,
    );
    if (alive.isNotEmpty) return alloc; // l'uuid tient toujours

    final resolved = await txn.query(
      'student_charges',
      columns: ['id'],
      where: 'student_id = ? AND fee_code = ? AND academic_year_id IS ?',
      whereArgs: [payment.studentId, alloc.feeCode, payment.academicYearId],
      limit: 1,
    );
    final relinked = resolved.isEmpty ? null : resolved.first['id'] as String;
    return alloc.withStudentChargeId(relinked);
  }

  // ── ACK / remap (FF4) ──────────────────────────────────────────────────────

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

  // ── Créances offline (FF5) ─────────────────────────────────────────────────

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

  // ── Pull autoritaire (FF2) ─────────────────────────────────────────────────

  /// Remplace la grille tarifaire des années couvertes par le bundle
  /// référentiel (snapshot **scopé**) : purge les lignes de ces années
  /// absentes du nouveau bundle (un tarif supprimé côté serveur ne doit pas
  /// rester fantôme — money-grade), puis upsert. Les tarifs d'autres années
  /// ne sont pas touchés ; sans année fournie, aucune purge (upsert seul).
  /// Taille de lot des purges `id IN (...)` — bornée bien en-deçà de
  /// `SQLITE_MAX_VARIABLE_NUMBER` (999 sur les SQLite anciens d'Android 10).
  static const int _deleteChunkSize = 500;

  Future<void> replaceTariffsForYears(
    List<FeeTariffLocalModel> tariffs, {
    required List<String> academicYearIds,
  }) async {
    await _db.transaction((txn) async {
      if (academicYearIds.isNotEmpty) {
        // Diff calculé en Dart puis purge par lots bornés : on NE lie PAS un `?`
        // par tarif conservé. Un `id NOT IN (…)` non borné dépasse
        // SQLITE_MAX_VARIABLE_NUMBER dès qu'une grille compte >~999 lignes (cf.
        // revue #21) et **fige alors le curseur référentiel** (l'apply lève →
        // curseur non avancé → re-pull en boucle). Les années scopées sont peu
        // nombreuses (bundle année active) → leur `IN (…)` reste petit.
        final years = List.filled(academicYearIds.length, '?').join(', ');
        final existing = await txn.query(
          'ref_fee_tariffs',
          columns: ['id'],
          where: 'academic_year_id IN ($years)',
          whereArgs: academicYearIds,
        );
        final keepIds = {for (final t in tariffs) t.id};
        final staleIds = [
          for (final r in existing)
            if (!keepIds.contains(r['id'] as String)) r['id'] as String,
        ];
        for (var i = 0; i < staleIds.length; i += _deleteChunkSize) {
          final end = i + _deleteChunkSize < staleIds.length
              ? i + _deleteChunkSize
              : staleIds.length;
          final chunk = staleIds.sublist(i, end);
          await txn.delete(
            'ref_fee_tariffs',
            where: 'id IN (${List.filled(chunk.length, '?').join(', ')})',
            whereArgs: chunk,
          );
        }
      }
      final batch = txn.batch();
      for (final t in tariffs) {
        batch.insert(
          'ref_fee_tariffs',
          t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// Applique le miroir autoritaire du pull. Découpage en lots (verrou relâché
  /// entre les lots) — grand-livre potentiellement volumineux ; upserts
  /// idempotents → apply partielle sûre. L'ordre n'est pas porteur : le reste se
  /// compose à la lecture, aucun solde n'est recalculé ici (FRONT §5/§8).
  ///
  /// Deux règles money-grade portées ici :
  ///  - **patch, pas REPLACE**, sur les lignes déjà connues : le pull n'est
  ///    autoritaire que sur les colonnes qu'il porte (cf. `toPullPatch`) — il ne
  ///    doit jamais écraser le payeur ni le libellé saisis au guichet ;
  ///  - **dissolution de la jumelle PROVISIONAL** avant d'insérer une créance
  ///    canonique, sinon l'élève est facturé deux fois (cf.
  ///    [_dissolveProvisionalTwins]).
  Future<void> upsertLedger({
    List<StudentChargeLocalModel> charges = const [],
    List<PaymentLocalModel> payments = const [],
    List<PaymentAllocationLocalModel> allocations = const [],
  }) async {
    await applyInBatches(
      _db,
      payments,
      apply: (txn, chunk) async {
        for (final p in chunk) {
          final patched = await txn.update(
            'payments',
            p.toPullPatch(),
            where: 'id = ?',
            whereArgs: [p.id],
          );
          if (patched == 0) {
            await txn.insert(
              'payments',
              p.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      },
    );
    await applyInBatches(
      _db,
      allocations,
      apply: (txn, chunk) async {
        for (final a in chunk) {
          final patched = await txn.update(
            'payment_allocations',
            a.toPullPatch(),
            where: 'id = ?',
            whereArgs: [a.id],
          );
          if (patched == 0) {
            await txn.insert(
              'payment_allocations',
              a.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      },
    );

    await applyInBatches(
      _db,
      charges,
      apply: (txn, chunk) async {
        // Index des jumelles candidates : une requête PAR LOT, dans la
        // transaction du lot. Pas par créance (le pull en masse en porte des
        // milliers, les jumelles se comptent sur les doigts), mais pas une fois
        // pour tout le pull non plus : `applyInBatches` relâche volontairement
        // le verrou entre les lots, et un élève peut être inscrit hors-ligne
        // pendant ce temps. Un index pris avant la boucle ignorerait ses
        // créances toutes fraîches, qui survivraient à côté de la canonique →
        // frais facturé deux fois. On borne la péremption à un lot.
        final twins = await _pendingChargeIndex(txn);
        for (final c in chunk) {
          await _dissolveProvisionalTwins(txn, c, twins);
          await txn.insert(
            'student_charges',
            c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
  }

  /// (clé métier → **ids**) des créances encore NON remontées : les seules
  /// qu'une créance canonique peut légitimement dissoudre. Une ligne SYNCED est
  /// autoritaire et n'est jamais candidate.
  ///
  /// Une LISTE par clé, pas un id : rien ne garantit l'unicité de
  /// `(student_id, academic_year_id, fee_code)` — la table n'a pas de
  /// contrainte, et `initializeChargesForStudent` peut avoir tourné deux fois
  /// (rejeu après crash, seconde passe de réinscription). Un
  /// `Map<_ChargeKey, String>` écraserait silencieusement toutes les jumelles
  /// sauf la dernière : une seule serait dissoute, l'autre survivrait à côté de
  /// la canonique — le frais serait facturé deux fois.
  Future<Map<_ChargeKey, List<String>>> _pendingChargeIndex(
    DatabaseExecutor txn,
  ) async {
    final rows = await txn.query(
      'student_charges',
      columns: ['id', 'student_id', 'academic_year_id', 'fee_code'],
      where: 'sync_status <> ?',
      whereArgs: [SyncState.synced.dbValue],
    );
    final index = <_ChargeKey, List<String>>{};
    for (final r in rows) {
      final key = (
        r['student_id'] as String,
        r['academic_year_id'] as String?,
        r['fee_code'] as String,
      );
      (index[key] ??= <String>[]).add(r['id'] as String);
    }
    return index;
  }

  /// Dissout la jumelle PROVISIONAL d'une créance canonique : ses imputations
  /// sont repointées vers l'id serveur, puis la ligne locale disparaît.
  ///
  /// Sans cela, l'élève inscrit hors-ligne (créances à uuid local) puis re-tiré
  /// du serveur (ids canoniques) porterait **deux lignes par frais** —
  /// `student_charges` n'a aucune contrainte d'unicité sur
  /// `(student_id, academic_year_id, fee_code)` et `getChargesByStudent` ne
  /// filtre que sur l'élève : le parent semblerait devoir le double, KPI et
  /// soldes compris. C'est le pendant, côté pull de masse, de ce que
  /// `_remapProvisionalCharge` fait à l'ACK.
  Future<void> _dissolveProvisionalTwins(
    DatabaseExecutor txn,
    StudentChargeLocalModel canonical,
    Map<_ChargeKey, List<String>> twins,
  ) async {
    final key = (
      canonical.studentId,
      canonical.academicYearId,
      canonical.feeCode,
    );
    final ids = twins[key];
    if (ids == null) return;
    for (final twinId in ids) {
      if (twinId == canonical.id) continue;
      await txn.update(
        'payment_allocations',
        {'student_charge_id': canonical.id},
        where: 'student_charge_id = ?',
        whereArgs: [twinId],
      );
      await txn.delete('student_charges', where: 'id = ?', whereArgs: [twinId]);
    }
    twins.remove(key); // dissoutes : ne pas les rejouer sur une page suivante
  }

  // ── Lectures ────────────────────────────────────────────────────────────────

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

  Future<List<LocalPaymentAllocation>> getAllocationsByPayment(
    String paymentId,
  ) async {
    final rows = await _db.query(
      'payment_allocations',
      where: 'payment_id = ?',
      whereArgs: [paymentId],
    );
    return rows
        .map((r) => PaymentAllocationLocalModel.fromMap(r).toEntity())
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

  // ── Helper payload ───────────────────────────────────────────────────────────

  PaymentAggregateRequest _paymentRequest(
    PaymentLocalModel payment,
    List<PaymentAllocationLocalModel> allocations,
  ) => PaymentAggregateRequest(
    payment: PaymentInput(
      id: payment.id,
      studentId: payment.studentId,
      academicYearId: payment.academicYearId,
      amountInCents: payment.amountInCents,
      currency: payment.currency,
      method: payment.method,
      paidAt: payment.paidAt,
      payerFirstName: payment.payerFirstName,
      payerLastName: payment.payerLastName,
      payerMiddleName: payment.payerMiddleName,
    ),
    allocations: allocations
        .map(
          (a) => PaymentAllocationInput(
            id: a.id,
            studentChargeId: a.studentChargeId,
            feeCode: a.feeCode,
            studentChargeLabel: a.studentChargeLabel,
            amountInCents: a.amountInCents,
            currency: a.currency,
          ),
        )
        .toList(),
  );
}
