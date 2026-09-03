import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart'
    show GeneratedDocumentLocalModel;
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

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
    List<PaymentTenderLocalModel> tenders = const [],
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

      // Ce qui est entré dans le TIROIR, à côté de ce qui a été imputé. Aucun
      // lien entre les deux listes, et c'est délibéré : un versement de
      // 112 000 FC qui solde 40 $ et 50 $ n'a pas comporté un paquet de billets
      // pour l'un et un paquet pour l'autre. La part en devise reçue de chaque
      // poste se DÉRIVE (`allocation × taux`) — une proration se recalcule,
      // elle ne se conserve pas.
      for (final tender in tenders) {
        await txn.insert(
          'payment_tenders',
          tender.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (receipt != null) {
        await txn.insert(
          'generated_documents',
          receipt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final request = _paymentRequest(payment, linked, tenders, authorId);
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
  /// On re-résout donc par une clé MÉTIER, stable là où l'uuid ne l'est pas —
  /// **le tarif d'abord**, la nature du frais ensuite. Le tarif désigne la ligne
  /// de grille : c'est le seul discriminant depuis qu'un niveau porte plusieurs
  /// créances d'une même nature (un minerval en sept tranches).
  ///
  /// Sans cible locale, on renvoie `null` plutôt qu'un id mort : c'est la
  /// sémantique du contrat (« créance pas encore matérialisée ») et le serveur
  /// remappera lui-même.
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

    final annee = payment.academicYearId;
    final tariffId = alloc.feeTariffId;
    if (tariffId != null && tariffId.isNotEmpty) {
      final byTariff = await _uniqueChargeId(
        txn,
        studentId: payment.studentId,
        academicYearId: annee,
        column: 'fee_tariff_id',
        value: tariffId,
      );
      if (byTariff != null) return alloc.withStudentChargeId(byTariff);
    }

    // Repli : la nature seule. Elle ne départage plus deux tranches, donc on
    // n'en retient une que si elle est SEULE — cf. [_uniqueChargeId].
    return alloc.withStudentChargeId(
      await _uniqueChargeId(
        txn,
        studentId: payment.studentId,
        academicYearId: annee,
        column: 'fee_code',
        value: alloc.feeCode,
      ),
    );
  }

  /// L'id de l'UNIQUE créance de l'élève répondant au critère, ou `null` s'il y
  /// en a zéro… **ou plusieurs**.
  ///
  /// Le `limit: 1` d'avant attrapait la première ligne que SQLite voulait bien
  /// rendre. Avec sept tranches de minerval, il imputait donc de l'argent réel
  /// sur une tranche tirée au sort, en silence, et le reçu imprimé derrière
  /// portait ce mensonge. Ne rien lier a un sens au contrat — « créance pas
  /// encore matérialisée », le serveur tranchera avec le tarif du payload ;
  /// lier au hasard n'en a aucun.
  Future<String?> _uniqueChargeId(
    DatabaseExecutor txn, {
    required String studentId,
    required String? academicYearId,
    required String column,
    required String value,
  }) async {
    // `null` est une valeur d'année à part entière, et sqflite refuse de la
    // LIER (il avertit aujourd'hui, lèvera demain). Le SQL se branche donc, et
    // jamais en `= ?` — qui ne rapprocherait plus aucune créance sans année, en
    // silence.
    final rows = await txn.query(
      'student_charges',
      columns: ['id'],
      where: academicYearId == null
          ? 'student_id = ? AND $column = ? AND academic_year_id IS NULL'
          : 'student_id = ? AND $column = ? AND academic_year_id = ?',
      whereArgs: [studentId, value, ?academicYearId],
      limit: 2, // 2 suffit à savoir qu'il y en a « plusieurs »
    );
    return rows.length == 1 ? rows.first['id'] as String : null;
  }

  PaymentAggregateRequest _paymentRequest(
    PaymentLocalModel payment,
    List<PaymentAllocationLocalModel> allocations,
    List<PaymentTenderLocalModel> tenders,
    String? authorId,
  ) => PaymentAggregateRequest(
    authorId: authorId,
    payment: PaymentInput(
      id: payment.id,
      studentId: payment.studentId,
      academicYearId: payment.academicYearId,
      // Dérivés des imputations, comme côté serveur : le versement n'a plus de
      // montant à lui. Le serveur vérifie l'égalité DEVISE PAR DEVISE
      // (`ALLOCATION_SUM_MISMATCH`), et la dériver ici la rend vraie par
      // construction plutôt que par discipline.
      amounts: MoneyBag.sumBy(
        allocations,
        (a) => Money.parse(a.amountInCents, a.currency),
      ),
      // Ce qui est entré dans le TIROIR, à côté de ce qui a été imputé — et
      // TOUJOURS, y compris quand les deux se confondent. Un versement muet
      // n'est pas refusé par le serveur : il y écrit l'identité, donc des
      // dollars pour un tiroir qui n'a vu que des francs. Les mêmes lignes que
      // celles écrites juste au-dessus, avec les MÊMES identifiants : c'est ce
      // qui fait que le delta de pull les corrige au lieu de les doubler.
      tenders: [
        for (final tender in tenders)
          PaymentTenderInput(
            id: tender.id,
            amountInCents: tender.amountInCents,
            currency: tender.currency,
            rateMicros: tender.rateMicros,
            pivotCurrency: tender.pivotCurrency,
          ),
      ],
      method: payment.method,
      paidAt: payment.paidAt,
      payerFirstName: payment.payerFirstName,
      payerLastName: payment.payerLastName,
      payerMiddleName: payment.payerMiddleName,
      payerPhoneNumber: payment.payerPhoneNumber,
    ),
    allocations: allocations
        .map(
          (a) => PaymentAllocationInput(
            id: a.id,
            studentChargeId: a.studentChargeId,
            // Recopié depuis l'imputation, pas relu dans la grille : le tarif
            // se fige à l'encaissement comme le libellé. Le payload ne doit pas
            // dépendre de ce que la grille sera au moment du push.
            feeTariffId: a.feeTariffId,
            feeCode: a.feeCode,
            studentChargeLabel: a.studentChargeLabel,
            amountInCents: a.amountInCents,
            currency: a.currency,
          ),
        )
        .toList(),
  );
}
