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

/// DAO local du module Facturation (sqflite). Lectures du grand-livre, geste
/// d'encaissement money-grade (FF3), remap à l'ACK (FF4), génération de
/// créances offline (FF5), upserts autoritaires du pull (FF2).
class FinanceLocalDao {
  final Database _db;
  final IdGenerator _idGenerator;

  const FinanceLocalDao(this._db, this._idGenerator);

  // ── Encaissement local-first (FF3) ─────────────────────────────────────────

  /// Insère un paiement + ses allocations, met à jour le solde OPTIMISTE
  /// d'affichage (jamais l'autoritaire), émet un RC provisoire et enfile
  /// l'outbox(PAYMENT). Retour immédiat.
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

      for (final alloc in allocations) {
        await txn.insert(
          'payment_allocations',
          alloc.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        // Solde OPTIMISTE (affichage) : jamais l'autoritaire.
        if (alloc.studentChargeId != null) {
          await txn.rawUpdate(
            'UPDATE student_charges '
            'SET optimistic_paid_in_cents = optimistic_paid_in_cents + ? '
            'WHERE id = ?',
            [alloc.amountInCents, alloc.studentChargeId],
          );
        }
      }

      if (receipt != null) {
        await txn.insert(
          'generated_documents',
          receipt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final request = _paymentRequest(payment, allocations);
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

  // ── ACK / remap (FF4) ──────────────────────────────────────────────────────

  /// Applique l'ACK : paiement SYNCED, remap studentChargeId provisoire→réel des
  /// allocations, remap des créances provisoires par (student_id, fee_code),
  /// puis ÉCRASE amount_paid/status locaux par la valeur autoritaire serveur.
  Future<void> applyPaymentAck(
    PaymentCommitAck ack, {
    required int nowMs,
  }) async {
    await _db.transaction((txn) async {
      await txn.update(
        'payments',
        {
          if (ack.payment.status != null) 'status': ack.payment.status,
          'sync_status': SyncState.synced.dbValue,
          'synced_at': nowMs,
          'sync_error': null,
        },
        where: 'id = ?',
        whereArgs: [ack.paymentId],
      );

      final payRows = await txn.query(
        'payments',
        columns: ['student_id'],
        where: 'id = ?',
        whereArgs: [ack.paymentId],
        limit: 1,
      );
      final studentId = payRows.isNotEmpty
          ? payRows.first['student_id'] as String?
          : null;

      // Remap des allocations + des créances provisoires par (student, feeCode).
      for (final alloc in ack.allocations) {
        final realChargeId = alloc.studentChargeId;
        final localRows = await txn.query(
          'payment_allocations',
          columns: ['fee_code'],
          where: 'id = ?',
          whereArgs: [alloc.id],
          limit: 1,
        );
        if (localRows.isEmpty) continue;
        final feeCode = localRows.first['fee_code'] as String;

        if (realChargeId != null && studentId != null) {
          await _remapProvisionalCharge(
            txn,
            studentId: studentId,
            feeCode: feeCode,
            realChargeId: realChargeId,
          );
          await txn.update(
            'payment_allocations',
            {'student_charge_id': realChargeId},
            where: 'id = ?',
            whereArgs: [alloc.id],
          );
        }
      }

      // Soldes AUTORITAIRES : on écrase amount_paid + status, on réaligne
      // l'optimiste sur l'autoritaire + les allocations encore PENDING.
      for (final ch in ack.updatedCharges) {
        await txn.update(
          'student_charges',
          {
            'amount_paid_in_cents': ch.amountPaidInCents,
            'status': ch.status,
            'sync_status': SyncState.synced.dbValue,
            'synced_at': nowMs,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [ch.id],
        );
        await _recomputeOptimistic(txn, ch.id);
      }
    });
  }

  /// Remap d'une créance provisoire (uuid local) vers l'id réel serveur, résolu
  /// par (student_id, fee_code) — clé stable (back FB-4).
  Future<void> _remapProvisionalCharge(
    DatabaseExecutor txn, {
    required String studentId,
    required String feeCode,
    required String realChargeId,
  }) async {
    final prov = await txn.query(
      'student_charges',
      columns: ['id'],
      where: 'student_id = ? AND fee_code = ? AND id != ?',
      whereArgs: [studentId, feeCode, realChargeId],
      limit: 1,
    );
    if (prov.isEmpty) return;
    final provId = prov.first['id'] as String;

    final realExists = await txn.query(
      'student_charges',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [realChargeId],
      limit: 1,
    );
    if (realExists.isNotEmpty) {
      // Le réel existe déjà (pull antérieur) : on repointe puis on drop le prov.
      await txn.update(
        'payment_allocations',
        {'student_charge_id': realChargeId},
        where: 'student_charge_id = ?',
        whereArgs: [provId],
      );
      await txn.delete('student_charges', where: 'id = ?', whereArgs: [provId]);
    } else {
      await txn.update(
        'student_charges',
        {'id': realChargeId, 'sync_status': SyncState.synced.dbValue},
        where: 'id = ?',
        whereArgs: [provId],
      );
      await txn.update(
        'payment_allocations',
        {'student_charge_id': realChargeId},
        where: 'student_charge_id = ?',
        whereArgs: [provId],
      );
    }
  }

  /// Optimiste = autoritaire + Σ(allocations des paiements ENCORE PENDING_SYNC).
  Future<void> _recomputeOptimistic(
    DatabaseExecutor txn,
    String chargeId,
  ) async {
    final rows = await txn.rawQuery(
      'SELECT sc.amount_paid_in_cents AS paid, '
      'COALESCE(('
      '  SELECT SUM(pa.amount_in_cents) FROM payment_allocations pa '
      '  JOIN payments p ON p.id = pa.payment_id '
      '  WHERE pa.student_charge_id = sc.id AND p.sync_status = ?'
      '), 0) AS pending '
      'FROM student_charges sc WHERE sc.id = ?',
      [SyncState.pendingSync.dbValue, chargeId],
    );
    if (rows.isEmpty) return;
    final paid = (rows.first['paid'] as int?) ?? 0;
    final pending = (rows.first['pending'] as int?) ?? 0;
    await txn.update(
      'student_charges',
      {'optimistic_paid_in_cents': paid + pending},
      where: 'id = ?',
      whereArgs: [chargeId],
    );
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
          syncStatus: SyncState.pendingSync.dbValue,
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

  Future<void> upsertLedger({
    List<StudentChargeLocalModel> charges = const [],
    List<PaymentLocalModel> payments = const [],
    List<PaymentAllocationLocalModel> allocations = const [],
  }) async {
    // Découpage en lots (verrou relâché entre les lots) — grand-livre
    // potentiellement volumineux. Ordre PORTEUR : paiements + allocations
    // D'ABORD, créances EN DERNIER, car `_recomputeOptimistic` somme les
    // allocations des paiements PENDING (déjà committées par les lots
    // précédents). Upserts REPLACE idempotents → apply partielle sûre.
    await applyInBatches(
      _db,
      payments,
      apply: (txn, chunk) async {
        for (final p in chunk) {
          await txn.insert(
            'payments',
            p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
    await applyInBatches(
      _db,
      allocations,
      apply: (txn, chunk) async {
        for (final a in chunk) {
          await txn.insert(
            'payment_allocations',
            a.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      },
    );
    await applyInBatches(
      _db,
      charges,
      apply: (txn, chunk) async {
        for (final c in chunk) {
          await txn.insert(
            'student_charges',
            c.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _recomputeOptimistic(txn, c.id);
        }
      },
    );
  }

  // ── Lectures ────────────────────────────────────────────────────────────────

  Future<List<LocalStudentCharge>> getChargesByStudent(String studentId) async {
    final rows = await _db.query(
      'student_charges',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'fee_code ASC',
    );
    return rows
        .map((r) => StudentChargeLocalModel.fromMap(r).toEntity())
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

  Future<List<LocalFeeTariff>> getTariffsByLevel(String schoolLevelId) async {
    final rows = await _db.query(
      'ref_fee_tariffs',
      where: 'school_level_id = ?',
      whereArgs: [schoolLevelId],
    );
    return rows.map((r) => FeeTariffLocalModel.fromMap(r).toEntity()).toList();
  }

  // ── Helper payload ───────────────────────────────────────────────────────────

  CreatePaymentRequest _paymentRequest(
    PaymentLocalModel payment,
    List<PaymentAllocationLocalModel> allocations,
  ) => CreatePaymentRequest(
    id: payment.id,
    studentId: payment.studentId,
    academicYearId: payment.academicYearId ?? '',
    amountInCents: payment.amountInCents,
    currency: payment.currency,
    method: payment.method,
    paidAt: payment.paidAt,
    payerFirstName: payment.payerFirstName,
    payerLastName: payment.payerLastName,
    payerMiddleName: payment.payerMiddleName,
    allocations: allocations
        .map(
          (a) => PaymentAllocationRequest(
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
