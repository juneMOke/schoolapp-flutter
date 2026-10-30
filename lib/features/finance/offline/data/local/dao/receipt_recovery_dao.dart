import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/data/local/ticket_print_job_writer.dart';

/// Le reçu qu'un accusé n'a pas rapporté (continuité des tickets RC).
///
/// Le scellement serveur peut échouer sans que le versement échoue : le 201
/// revient alors sans `receiptId`. La tablette ne rejoue jamais un push
/// acquitté, et le pull des pièces ne ramènera rien qui n'a pas été scellé —
/// sans rattrapage, ce versement n'aurait jamais de numéro, donc jamais de
/// ticket.
///
/// La marque est une entrée d'outbox : `POST /finance/payments/{id}/receipt`
/// est idempotent, timeout compris (aucun numéro consommé en plus, réponse
/// du back du 2026-10-28). Le moteur porte donc seul la reprise, le hors
/// ligne, la reconnexion et l'école — exactement ce qu'il fait pour tout geste.
class ReceiptRecoveryDao {
  final DatabaseExecutor _db;

  const ReceiptRecoveryDao(this._db);

  /// Type d'agrégat de l'entrée de rattrapage.
  static const String aggregateType = 'PAYMENT_RECEIPT';

  /// Clé de la charge utile : le versement dont le reçu manque.
  static const String paymentIdKey = 'paymentId';

  static String _entryId(String paymentId) => 'receipt-$paymentId';

  /// Marque, dans la transaction de l'accusé, le reçu de [paymentId] comme à
  /// récupérer.
  ///
  /// Sans auteur : la route ne dépend que du droit `editique.write`, et un
  /// collègue connecté doit pouvoir rattraper le reçu à la place de celui qui
  /// a encaissé. L'école est celle de l'écriture qui vient d'être acquittée —
  /// le versement lui-même, ou la correction qui l'a créé.
  ///
  /// Un accusé rejoué ne marque pas deux fois, et ne remet pas à zéro le
  /// backoff d'une marque déjà posée.
  static Future<void> markMissingIn(
    DatabaseExecutor txn, {
    required String paymentId,
    required int nowMs,
  }) async {
    final entry = OutboxEntry(
      id: _entryId(paymentId),
      aggregateType: aggregateType,
      aggregateId: paymentId,
      operation: OutboxOperation.create,
      payload: jsonEncode({paymentIdKey: paymentId}),
      schoolId: await _schoolOf(txn, paymentId),
      createdAt: nowMs,
    );
    await txn.insert(
      OutboxDao.table,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  static Future<String?> _schoolOf(
    DatabaseExecutor txn,
    String paymentId,
  ) async {
    final rows = await txn.rawQuery(
      '''
      SELECT school_id FROM ${OutboxDao.table}
       WHERE school_id IS NOT NULL
         AND (aggregate_id = ?
              OR aggregate_id IN (SELECT id FROM payment_corrections
                                   WHERE replacement_payment_id = ?))
       LIMIT 1
      ''',
      [paymentId, paymentId],
    );
    return rows.isEmpty ? null : rows.first['school_id'] as String?;
  }

  /// L'élève et l'année du versement, qui attribuent la copie locale du reçu ;
  /// `null` quand le versement n'est plus sur ce poste.
  Future<({String? studentId, String? academicYearId})?> scopeOf(
    String paymentId,
  ) async {
    final rows = await _db.query(
      'payments',
      columns: const ['student_id', 'academic_year_id'],
      where: 'id = ?',
      whereArgs: [paymentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return (
      studentId: rows.first['student_id'] as String?,
      academicYearId: rows.first['academic_year_id'] as String?,
    );
  }

  /// Le reçu est revenu : le versement le porte comme si l'accusé l'avait
  /// rapporté — son identifiant d'archive, et le numéro définitif à la place
  /// du `PROV-…` avec son jour d'émission (même écriture que le scellement à
  /// l'accusé).
  Future<void> recordRecovered({
    required String paymentId,
    String? documentId,
    String? documentNumber,
    String? emittedOn,
  }) async {
    if (documentId != null && documentId.isNotEmpty) {
      await _db.update(
        'payments',
        {'receipt_id': documentId},
        where: 'id = ?',
        whereArgs: [paymentId],
      );
    }
    if (documentNumber != null && documentNumber.isNotEmpty) {
      // Même règle qu'au scellement à l'accusé : un autre numéro sans jour
      // n'hérite pas de celui de l'ancien.
      if (emittedOn == null) {
        await _db.update(
          'generated_documents',
          {'emitted_on': null},
          where:
              'payment_id = ? AND doc_domain = ? AND doc_type = ? '
              'AND number <> ?',
          whereArgs: [paymentId, 'PAYMENT', 'RC', documentNumber],
        );
      }
      await _db.update(
        'generated_documents',
        {
          'number': documentNumber,
          'status': 'DEFINITIVE',
          'emitted_on': ?emittedOn,
        },
        where: 'payment_id = ? AND doc_domain = ? AND doc_type = ?',
        whereArgs: [paymentId, 'PAYMENT', 'RC'],
      );
    }
  }

  /// « Relancer » : la marque de [paymentId] repart au prochain flush, sans
  /// attendre son backoff — et même refusée, puisque la route est idempotente.
  /// Rend `false` quand rien n'était marqué.
  Future<bool> retryNow(String paymentId) async {
    final changed = await _db.update(
      OutboxDao.table,
      {
        'status': OutboxStatus.pending.dbValue,
        'attempts': 0,
        'next_attempt_at': 0,
        'last_error': null,
      },
      // Une marque déjà acquittée a abouti : la relancer l'emporterait sur
      // l'accusé en vol.
      where: 'aggregate_type = ? AND aggregate_id = ? AND status <> ?',
      whereArgs: [aggregateType, paymentId, OutboxStatus.acked.dbValue],
    );
    return changed > 0;
  }

  /// Le versement a été annulé sans que son reçu soit jamais scellé : son
  /// ticket d'annulation citerait un numéro qui n'existe pas. Il ne doit plus
  /// rien — sauf si un numéro définitif est connu ici malgré tout.
  Future<void> dropUnnumberedCancellationTicket(String paymentId) =>
      _db.rawDelete(
        '''
        DELETE FROM ${TicketPrintJobWriter.table}
         WHERE payment_id = ?
           AND kind = '${TicketPrintJobWriter.cancellation}'
           AND printed_at IS NULL
           AND NOT EXISTS (
             SELECT 1 FROM generated_documents d
              WHERE d.payment_id = ? AND d.doc_domain = 'PAYMENT'
                AND d.doc_type = 'RC' AND d.status = 'DEFINITIVE'
           )
           AND NOT EXISTS (
             SELECT 1 FROM payments p
              WHERE p.id = ? AND p.receipt_id IS NOT NULL
           )
        ''',
        [paymentId, paymentId, paymentId],
      );
}
