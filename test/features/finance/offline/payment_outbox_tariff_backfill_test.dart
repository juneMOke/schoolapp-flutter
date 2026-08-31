import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_outbox_tariff_backfill.dart';

import '../../offline_full_db.dart';

/// Reprise des versements enfilés avant que l'imputation ne désigne sa ligne de
/// grille. Sans elle, ils repartent en 422 `AMBIGUOUS_FEE_CODE` à chaque cycle,
/// indéfiniment — de l'argent réellement encaissé, avec un reçu déjà remis.
void main() {
  late Database db;
  late PaymentOutboxTariffBackfill backfill;

  setUp(() async {
    db = await openFullOfflineDb();
    backfill = PaymentOutboxTariffBackfill(db);
  });

  tearDown(() async => db.close());

  /// Payload d'AVANT : l'allocation ne nomme que la nature du frais.
  Map<String, dynamic> legacyPayload({String allocationId = 'alloc-1'}) => {
    'payment': {'id': 'pay-1', 'studentId': 's1'},
    'allocations': [
      {
        'id': allocationId,
        'studentChargeId': 'prov-2',
        'feeCode': 'EXAMINATION',
        'studentChargeLabel': 'Organisation matériel examens — 2/3',
        'amountInCents': 500000,
        'currency': 'CDF',
      },
    ],
  };

  Future<void> enqueue({
    String id = 'ob-1',
    required Map<String, dynamic> payload,
    String status = 'SYNC_ERROR',
    String? lastError = 'AMBIGUOUS_FEE_CODE',
  }) => db.insert('outbox', {
    'id': id,
    'aggregate_type': 'PAYMENT',
    'aggregate_id': 'pay-1',
    'operation': 'CREATE',
    'payload': jsonEncode(payload),
    'status': status,
    'attempts': 3,
    'next_attempt_at': 0,
    'last_error': lastError,
    'created_at': 1000,
  });

  Future<void> insertAllocation({
    String id = 'alloc-1',
    String? feeTariffId,
    String? studentChargeId = 'prov-2',
  }) => db.insert('payment_allocations', {
    'id': id,
    'client_uuid': id,
    'payment_id': 'pay-1',
    'student_charge_id': studentChargeId,
    'fee_tariff_id': feeTariffId,
    'fee_code': 'EXAMINATION',
    'student_charge_label': 'Organisation matériel examens — 2/3',
    'amount_in_cents': 500000,
    'currency': 'CDF',
  });

  Future<Map<String, dynamic>> readPayload([String id = 'ob-1']) async {
    final row = (await db.query(
      'outbox',
      where: 'id = ?',
      whereArgs: [id],
    )).single;
    return jsonDecode(row['payload'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, Object?>> readEntry([String id = 'ob-1']) async =>
      (await db.query('outbox', where: 'id = ?', whereArgs: [id])).single;

  test('la ligne de grille se lit sur l\'imputation locale, et l\'entrée '
      'bloquée repart', () async {
    await insertAllocation(feeTariffId: 'tarif-2');
    await enqueue(payload: legacyPayload());

    final report = await backfill.run();

    final alloc = (await readPayload())['allocations'] as List<dynamic>;
    expect((alloc.single as Map)['feeTariffId'], 'tarif-2');
    expect(report.payloadsEnriched, 1);
    expect(report.entriesRequeued, 1);

    // Remise en file COMPLÈTE : le backoff et le compteur de tentatives sont
    // remis à zéro, sinon l'entrée corrigée attendrait encore son tour.
    final entry = await readEntry();
    expect(entry['status'], OutboxStatus.pending.dbValue);
    expect(entry['attempts'], 0);
    expect(entry['last_error'], isNull);
  });

  /// L'imputation n'a pas de tarif (elle est d'avant la colonne), mais elle
  /// pointe une créance qui, elle, en a un — et ce lien-là est À JOUR : le pull
  /// et l'accusé le repointent, alors que le payload reste figé.
  test('à défaut, le tarif se lit sur la créance que l\'imputation pointe '
      'AUJOURD\'HUI', () async {
    await insertAllocation(studentChargeId: 'canon-2');
    await db.insert('student_charges', {
      'id': 'canon-2',
      'student_id': 's1',
      'academic_year_id': 'ay-1',
      'fee_tariff_id': 'tarif-2',
      'fee_code': 'EXAMINATION',
      'label': 'Organisation matériel examens — 2/3',
      'expected_amount_in_cents': 500000,
      'amount_paid_in_cents': 500000,
      'optimistic_paid_in_cents': 500000,
      'currency': 'CDF',
      'status': 'PAID',
      'sync_status': SyncState.synced.dbValue,
    });
    await enqueue(payload: legacyPayload());

    await backfill.run();

    final alloc = (await readPayload())['allocations'] as List<dynamic>;
    expect((alloc.single as Map)['feeTariffId'], 'tarif-2');
  });

  /// Rien ne désigne cette imputation : ni colonne de tarif, ni créance. Le
  /// payload reste INTACT et l'entrée garde son diagnostic — c'est le chiffre
  /// de l'arbitrage A, pas un cas à deviner.
  test(
    'imputation non appariable : payload intact, aucune remise en file',
    () async {
      await enqueue(payload: legacyPayload());

      final report = await backfill.run();

      final alloc = (await readPayload())['allocations'] as List<dynamic>;
      expect((alloc.single as Map).containsKey('feeTariffId'), isFalse);
      expect(report.payloadsEnriched, 0);
      expect(report.entriesRequeued, 0);
      expect(report.allocationsUnmatched, 1);

      final entry = await readEntry();
      expect(entry['status'], OutboxStatus.syncError.dbValue);
      expect(entry['last_error'], 'AMBIGUOUS_FEE_CODE');
    },
  );

  /// Une entrée figée pour une AUTRE cause n'est pas relancée en bloc : sans
  /// rien à corriger dans son payload, elle garde son diagnostic.
  test(
    'entrée bloquée pour une autre cause, sans tarif à poser : intouchée',
    () async {
      await insertAllocation(id: 'alloc-9', feeTariffId: 'tarif-9');
      await enqueue(
        payload: {
          'payment': {'id': 'pay-1', 'studentId': 's1'},
          'allocations': [
            {
              'id': 'alloc-1',
              'feeTariffId': 'tarif-2', // déjà désignée
              'feeCode': 'EXAMINATION',
              'studentChargeLabel': 'Organisation matériel examens — 2/3',
              'amountInCents': 500000,
              'currency': 'CDF',
            },
          ],
        },
        lastError: 'CHARGE_CURRENCY_MISMATCH',
      );

      final report = await backfill.run();

      expect(report.payloadsEnriched, 0);
      final entry = await readEntry();
      expect(entry['status'], OutboxStatus.syncError.dbValue);
      expect(entry['last_error'], 'CHARGE_CURRENCY_MISMATCH');
    },
  );

  /// Un versement PENDING n'a pas encore échoué — il échouera. Le corriger
  /// maintenant lui épargne l'aller-retour ET la ligne rouge ; mais on ne
  /// touche pas à son compteur, il partira de lui-même au prochain flush.
  test(
    'un versement encore en attente est corrigé sans être requeué',
    () async {
      await insertAllocation(feeTariffId: 'tarif-2');
      await enqueue(
        payload: legacyPayload(),
        status: 'PENDING',
        lastError: null,
      );

      final report = await backfill.run();

      final alloc = (await readPayload())['allocations'] as List<dynamic>;
      expect((alloc.single as Map)['feeTariffId'], 'tarif-2');
      expect(report.payloadsEnriched, 1);
      expect(report.entriesRequeued, 0);
      expect((await readEntry())['attempts'], 3);
    },
  );

  /// Elle tourne à CHAQUE démarrage : un parc mis à jour par vagues n'a pas de
  /// premier lancement commun. Le second passage ne doit donc rien écrire — ni
  /// relancer une entrée que le guichet a laissée en erreur exprès.
  test('rejouable : le deuxième passage n\'écrit rien', () async {
    await insertAllocation(feeTariffId: 'tarif-2');
    await enqueue(payload: legacyPayload());

    await backfill.run();
    final afterFirst = await readEntry();

    final second = await backfill.run();

    expect(second.payloadsEnriched, 0);
    expect(second.entriesRequeued, 0);
    expect(await readEntry(), afterFirst);
  });

  /// Le payload à plat des versions les plus anciennes n'a pas de nœud
  /// `payment`. Le patcher EN PLACE le laisse tel quel : le reconstruire depuis
  /// les modèles du jour le normaliserait, et perdrait au passage ce qu'ils ne
  /// savent plus lire.
  test('payload à plat : la forme d\'origine est préservée', () async {
    await insertAllocation(feeTariffId: 'tarif-2');
    await enqueue(
      payload: {
        'id': 'pay-1',
        'studentId': 's1',
        'champInconnuDuModele': 'à préserver',
        'allocations': [
          {
            'id': 'alloc-1',
            'feeCode': 'EXAMINATION',
            'studentChargeLabel': 'Organisation matériel examens — 2/3',
            'amountInCents': 500000,
            'currency': 'CDF',
          },
        ],
      },
    );

    await backfill.run();

    final payload = await readPayload();
    expect(payload.containsKey('payment'), isFalse);
    expect(payload['champInconnuDuModele'], 'à préserver');
    expect(
      ((payload['allocations'] as List).single as Map)['feeTariffId'],
      'tarif-2',
    );
  });
}
