import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

/// Geste d'encaissement money-grade local-first (FF3) : insère le paiement + ses
/// allocations (append-only), émet un reçu provisoire et enfile l'outbox —
/// sans jamais toucher `student_charges` (le reste se compose à la lecture).
class FinancePaymentWriteDao {
  final Database _db;

  const FinancePaymentWriteDao(this._db);

  /// Insère un paiement + ses allocations (append-only), émet un RC provisoire
  /// et enfile l'outbox(PAYMENT). N'écrit RIEN dans `student_charges` : le reste
  /// à payer se compose à la lecture (FRONT §6.2/§8). Retour immédiat.
  Future<void> recordPayment({
    required PaymentLocalModel payment,
    required List<PaymentAllocationLocalModel> allocations,
    GeneratedDocumentLocalModel? receipt,
    required String outboxEntryId,
    String? schoolId,
    String? authorId,
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

      final request = _paymentRequest(payment, linked, authorId);
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

  PaymentAggregateRequest _paymentRequest(
    PaymentLocalModel payment,
    List<PaymentAllocationLocalModel> allocations,
    String? authorId,
  ) => PaymentAggregateRequest(
    authorId: authorId,
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
