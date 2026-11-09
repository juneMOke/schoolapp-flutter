import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/data/local/level_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../level_correction_fixtures.dart';

/// Le rempart de D7 dans l'écriture du versement : la page d'encaissement
/// atteinte sans passer par le bouton (lien profond, rechargement) ne doit pas
/// pouvoir prendre l'argent d'un élève dont la correction de niveau attend.
void main() {
  late Database db;
  late FinancePaymentWriteDao payments;

  setUp(() async {
    db = await openFullOfflineDb();
    payments = FinancePaymentWriteDao(db);
    await insertEnrollment(db);
  });
  tearDown(() => db.close());

  Future<void> collect() => payments.recordPayment(
    payment: const PaymentLocalModel(
      id: 'pay-1',
      clientUuid: 'pay-1',
      studentId: kStudent,
      academicYearId: kYear,
      paidAt: '2026-11-06T11:00:00Z',
      payerFirstName: 'S',
      payerLastName: 'M',
    ),
    allocations: const [],
    outboxEntryId: 'ob-pay',
    nowMs: 1000,
  );

  test('sans correction en cours, le versement s\'écrit', () async {
    await collect();
    expect(await db.query('payments'), hasLength(1));
  });

  test("correction en attente : rien n'est écrit, ni versement ni entrée "
      "d'outbox", () async {
    await LevelCorrectionWriteDao(
      db,
    ).record(correctionGesture('g-1'), schoolId: kSchool, nowMs: 1);

    await expectLater(collect(), throwsA(isA<LevelCorrectionHoldException>()));
    expect(await db.query('payments'), isEmpty);
    expect(await OutboxDao(db).byId('ob-pay'), isNull);
  });
}
