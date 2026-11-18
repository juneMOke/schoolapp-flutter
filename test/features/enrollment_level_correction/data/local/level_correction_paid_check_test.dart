import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_read_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

/// Le contrôle du payé, une fois que le serveur corrige un élève qui a payé
/// (lot F3 du back) : par nature, le payé vivant contre la grille du niveau
/// cible (`lvl-p2`, cycle `grp-primaire`, dans les fixtures).
void main() {
  late Database db;
  late LevelCorrectionWriteDao writer;

  setUp(() async {
    db = await openFullOfflineDb();
    writer = LevelCorrectionWriteDao(db, acceptsPaidStudents: true);
  });
  tearDown(() => db.close());

  Future<LevelCorrectionRecordOutcome> record() =>
      writer.record(correctionGesture('g-1'), schoolId: kSchool, nowMs: 10);

  var seq = 0;

  /// Une créance actuelle de l'élève, payée de [paid] au miroir serveur.
  Future<void> charge(
    String feeCode, {
    required int paid,
    String currency = 'USD',
    String id = '',
  }) => db.insert('student_charges', {
    'id': id.isEmpty ? 'c-${seq++}' : id,
    'student_id': kStudent,
    'academic_year_id': kYear,
    'school_level_id': 'lvl-m2',
    'fee_code': feeCode,
    'label': feeCode,
    'expected_amount_in_cents': 100000,
    'amount_paid_in_cents': paid,
    'currency': currency,
  });

  /// Un tarif du niveau cible ; [cycle] le pose au niveau du cycle.
  Future<void> tariff(
    String feeCode,
    int cents, {
    String currency = 'USD',
    bool cycle = false,
    String level = 'lvl-p2',
  }) => db.insert('ref_fee_tariffs', {
    'id': 't-${seq++}',
    'academic_year_id': kYear,
    'school_level_id': cycle ? null : level,
    'school_level_group_id': 'grp-primaire',
    'fee_code': feeCode,
    'label': feeCode,
    'amount_in_cents': cents,
    'currency': currency,
  });

  Future<bool> written() async =>
      await LevelCorrectionReadDao(db).latestFor(kEnrollment) != null ||
      await OutboxDao(db).byId(LevelCorrectionWriteDao.entryId('g-1')) != null;

  test('un versement sans rien de payé ne bloque pas', () async {
    await insertPayment(db, id: 'pay-1', cancelledAt: 5);
    await charge('MINERVAL', paid: 0);
    await tariff('MINERVAL', 30000);
    expect(await record(), LevelCorrectionRecordOutcome.recorded);
  });

  test('payé égal au total cible : la correction passe', () async {
    await charge('MINERVAL', paid: 50000);
    await tariff('MINERVAL', 50000);
    expect(await record(), LevelCorrectionRecordOutcome.recorded);
  });

  test('payé au-delà du total cible : trop payé, rien n\'est écrit', () async {
    await charge('MINERVAL', paid: 50001);
    await tariff('MINERVAL', 50000);
    expect(await record(), LevelCorrectionRecordOutcome.overpaid);
    expect(await written(), isFalse);
  });

  test(
    'le total cible additionne les tranches et les tarifs du cycle',
    () async {
      await charge('MINERVAL', paid: 30000, id: 'c-a');
      await charge('MINERVAL', paid: 40000, id: 'c-b');
      await tariff('MINERVAL', 50000);
      await tariff('MINERVAL', 20000, cycle: true);
      // Un tarif d'un autre niveau n'entre pas dans le total.
      await tariff('MINERVAL', 90000, level: 'lvl-p3');
      expect(await record(), LevelCorrectionRecordOutcome.recorded);
    },
  );

  test('une nature payée absente de la grille cible : refus', () async {
    await charge('UNIFORME', paid: 1000);
    await tariff('MINERVAL', 50000);
    expect(await record(), LevelCorrectionRecordOutcome.feeCodeAbsent);
  });

  test(
    'une nature non payée absente de la grille cible ne bloque pas',
    () async {
      await charge('UNIFORME', paid: 0);
      await tariff('MINERVAL', 50000);
      expect(await record(), LevelCorrectionRecordOutcome.recorded);
    },
  );

  test('une nature payée qui change de devise : refus', () async {
    await charge('MINERVAL', paid: 1000);
    await tariff('MINERVAL', 5000000, currency: 'CDF');
    expect(await record(), LevelCorrectionRecordOutcome.currencyChanged);
  });

  test('un versement local pas encore accusé compte dans le payé', () async {
    await charge('MINERVAL', paid: 40000, id: 'c-1');
    await tariff('MINERVAL', 50000);
    await db.insert('payments', {
      'id': 'pay-local',
      'client_uuid': 'pay-local',
      'student_id': kStudent,
      'academic_year_id': kYear,
      'paid_at': '2026-11-06T09:00:00.000Z',
    });
    await db.insert('payment_allocations', {
      'id': 'a-local',
      'client_uuid': 'a-local',
      'payment_id': 'pay-local',
      'student_charge_id': 'c-1',
      'fee_code': 'MINERVAL',
      'student_charge_label': 'Minerval',
      'amount_in_cents': 20000,
      'currency': 'USD',
    });
    expect(await record(), LevelCorrectionRecordOutcome.overpaid);
  });

  test('premier temps (par défaut) : tout versement retient encore', () async {
    await insertPayment(db, id: 'pay-1', cancelledAt: 5);
    await charge('MINERVAL', paid: 0);
    await tariff('MINERVAL', 30000);
    expect(
      await LevelCorrectionWriteDao(
        db,
      ).record(correctionGesture('g-1'), schoolId: kSchool, nowMs: 10),
      LevelCorrectionRecordOutcome.hasPayments,
    );
  });

  test('chaque refus porte le code que le serveur renverrait', () {
    expect(
      {
        for (final o in LevelCorrectionRecordOutcome.values)
          if (o.refusal != null) o: o.refusal!.wire,
      },
      {
        LevelCorrectionRecordOutcome.hasPayments:
            'LEVEL_CORRECTION_HAS_PAYMENTS',
        LevelCorrectionRecordOutcome.overpaid: 'LEVEL_CORRECTION_OVERPAID',
        LevelCorrectionRecordOutcome.feeCodeAbsent:
            'LEVEL_CORRECTION_FEE_CODE_ABSENT',
        LevelCorrectionRecordOutcome.currencyChanged:
            'LEVEL_CORRECTION_CURRENCY_CHANGED',
      },
    );
  });
}
