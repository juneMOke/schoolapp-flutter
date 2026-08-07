import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';

import '../../offline_full_db.dart';

class MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  late Database db;
  late FinanceOfflineRepositoryImpl repo;

  setUp(() async {
    db = await openFullOfflineDb();
    final syncEngine = MockSyncEngine();
    when(
      () => syncEngine.flush(),
    ).thenAnswer((_) async => const SyncFlushReport());
    repo = FinanceOfflineRepositoryImpl(
      dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
      idGenerator: const IdGenerator(Uuid()),
      syncEngine: syncEngine,
      now: () => 1000,
    );
  });

  tearDown(() async => db.close());

  test('recordPayment : total ≠ Σ allocations → ValidationFailure, rien écrit '
      '(fail-fast, pas de 422 qui immobilise l\'argent)', () async {
    final result = await repo.recordPayment(
      const RecordPaymentDraft(
        studentId: 's1',
        academicYearId: 'ay-1',
        currency: 'USD',
        paidAt: '2026-07-06T10:00:00Z',
        payerFirstName: 'S',
        payerLastName: 'M',
        amountInCents: 50000, // ≠ Σ allocations (30000)
        allocations: [
          AllocationDraft(
            feeCode: 'TUITION',
            studentChargeLabel: 'Scolarité',
            amountInCents: 30000,
            currency: 'USD',
          ),
        ],
      ),
    );

    expect(result.isLeft(), isTrue);
    result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('!'));
    expect(await db.query('payments'), isEmpty, reason: 'aucune écriture');
    expect(await db.query('outbox'), isEmpty);
  });

  test(
    'recordPayment : total cohérent → Right(paymentId) + paiement en file',
    () async {
      final result = await repo.recordPayment(
        const RecordPaymentDraft(
          studentId: 's1',
          academicYearId: 'ay-1',
          currency: 'USD',
          paidAt: '2026-07-06T10:00:00Z',
          payerFirstName: 'S',
          payerLastName: 'M',
          allocations: [
            AllocationDraft(
              feeCode: 'TUITION',
              studentChargeLabel: 'Scolarité',
              amountInCents: 30000,
              currency: 'USD',
            ),
          ],
        ),
      );

      expect(result.isRight(), isTrue);
      expect((await db.query('payments')).single['amount_in_cents'], 30000);
      // RC provisoire toujours émis à l'encaissement (FRONT §7).
      expect((await db.query('generated_documents')).single['doc_type'], 'RC');
      expect((await db.query('outbox')).single['aggregate_type'], 'PAYMENT');
    },
  );
}
