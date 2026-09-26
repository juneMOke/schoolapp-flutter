import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/finance_payment_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_correction_write_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/payment_composer.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/payment_correction_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_status.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';

import '../../../../offline_full_db.dart';

class _MockSyncEngine extends Mock implements SyncEngine {}

/// Le geste de correction (lot T2), exercé sur une vraie base : ce sont les
/// SOLDES qu'il déplace qui comptent, pas les lignes qu'il écrit.
void main() {
  late Database db;
  late FinanceLocalDao ledger;
  late FinanceOfflineRepositoryImpl cashier;
  late PaymentCorrectionRepositoryImpl corrections;

  setUp(() async {
    db = await openFullOfflineDb();
    final sync = _MockSyncEngine();
    when(() => sync.flush()).thenAnswer((_) async => const SyncFlushReport());
    const ids = IdGenerator(Uuid());
    final user = CurrentUserContext()..set('u-1', schoolId: 'school-1');
    ledger = FinanceLocalDao(db, ids);
    cashier = FinanceOfflineRepositoryImpl(
      dao: ledger,
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 1000,
    );
    corrections = PaymentCorrectionRepositoryImpl(
      dao: PaymentCorrectionWriteDao(db, FinancePaymentWriteDao(db)),
      composer: PaymentComposer(idGenerator: ids, currentUser: user),
      idGenerator: ids,
      syncEngine: sync,
      currentUser: user,
      now: () => 2000,
    );

    await db.insert('student_charges', {
      'id': 'c-1',
      'student_id': 's-1',
      'academic_year_id': 'ay-1',
      'fee_code': 'MINERVAL',
      'label': 'Minerval',
      'expected_amount_in_cents': 15000,
      'currency': 'USD',
    });
  });

  tearDown(() async => db.close());

  RecordPaymentDraft draftOf(int cents, {String studentId = 's-1'}) =>
      RecordPaymentDraft(
        studentId: studentId,
        academicYearId: 'ay-1',
        paidAt: '2026-09-25T13:11:41Z',
        payerFirstName: 'Marie',
        payerLastName: 'Tshiala',
        allocations: [
          AllocationDraft(
            studentChargeId: 'c-1',
            feeCode: 'MINERVAL',
            studentChargeLabel: 'Minerval',
            amountInCents: cents,
            currency: 'USD',
          ),
        ],
      );

  Future<String> collect(int cents) async => (await cashier.recordPayment(
    draftOf(cents),
  )).getOrElse(() => throw StateError('encaissement refusé'));

  /// Ce que l'écran lit : le reste à payer de la créance.
  Future<int> remaining() async {
    final charge = (await ledger.getChargesByStudent('s-1')).single;
    return charge.expectedAmountInCents - charge.optimisticPaidInCents;
  }

  /// Simule l'ACK de l'encaissement : versement synchronisé, créance
  /// recalculée par le serveur.
  Future<void> syncOrigin(String paymentId, int paid) async {
    await db.update(
      'payments',
      {'sync_status': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [paymentId],
    );
    await db.update(
      'student_charges',
      {'amount_paid_in_cents': paid},
      where: 'id = ?',
      whereArgs: ['c-1'],
    );
    await db.delete('outbox');
  }

  Future<List<Map<String, Object?>>> outbox(String type) =>
      db.query('outbox', where: 'aggregate_type = ?', whereArgs: [type]);

  PaymentCorrectionDraft cancelOf(String id) => PaymentCorrectionDraft(
    paymentId: id,
    reason: PaymentCorrectionReason.duplicate,
  );

  group('annuler', () {
    test('un versement pas encore remonté sort des soldes', () async {
      final origin = await collect(15000);
      expect(await remaining(), 0);

      final result = await corrections.correctPayment(cancelOf(origin));

      expect(result.isRight(), isTrue);
      expect(await remaining(), 15000);
      final row = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [origin],
      )).single;
      // R1 : l'annulation locale ne touche JAMAIS cette colonne.
      expect(row['cancelled_at'], isNull);
    });

    // Le cas Gloredi : versement déjà synchronisé, le serveur le compte dans la
    // créance. La tablette doit le retrancher elle-même, puis s'arrêter de le
    // faire dès que l'annulation serveur redescend.
    test('un versement synchronisé est retranché, une seule fois', () async {
      final origin = await collect(15000);
      await syncOrigin(origin, 15000);
      expect(await remaining(), 0);

      await corrections.correctPayment(cancelOf(origin));
      expect(await remaining(), 15000);

      // Le pull ramène l'annulation et la créance recalculée, avant l'ACK.
      await db.update(
        'payments',
        {'cancelled_at': 3000},
        where: 'id = ?',
        whereArgs: [origin],
      );
      await db.update(
        'student_charges',
        {'amount_paid_in_cents': 0},
        where: 'id = ?',
        whereArgs: ['c-1'],
      );
      expect(await remaining(), 15000);
    });

    test('la correction part dans UNE entrée d outbox', () async {
      final origin = await collect(15000);
      await syncOrigin(origin, 15000);

      final outcome = (await corrections.correctPayment(
        cancelOf(origin),
      )).getOrElse(() => throw StateError('refusé'));

      final entry = (await outbox(kPaymentCorrectionAggregate)).single;
      expect(entry['aggregate_id'], outcome.correctionId);
      expect(entry['school_id'], 'school-1');
      final payload = jsonDecode(entry['payload'] as String) as Map;
      expect(payload['paymentId'], origin);
      expect(payload['reasonCode'], 'DUPLICATE');
      expect(payload.containsKey('replacement'), isFalse);
      expect(await outbox('PAYMENT'), isEmpty);
    });

    test('ne compte plus parmi les encaissements en attente', () async {
      final origin = await collect(15000);
      expect(await ledger.countPendingPayments(), 1);

      await corrections.correctPayment(cancelOf(origin));

      expect(await ledger.countPendingPayments(), 0);
    });
  });

  group('corriger', () {
    PaymentCorrectionDraft replaceOf(String id, int cents) =>
        PaymentCorrectionDraft(
          paymentId: id,
          reason: PaymentCorrectionReason.wrongAmount,
          reasonDetail: 'Saisi 150 \$ au lieu de 50 \$',
          replacement: draftOf(cents),
        );

    test('le solde ne retient que le remplaçant', () async {
      final origin = await collect(15000);
      await syncOrigin(origin, 15000);

      final outcome = (await corrections.correctPayment(
        replaceOf(origin, 5000),
      )).getOrElse(() => throw StateError('refusé'));

      expect(await remaining(), 10000);
      final replacement = (await db.query(
        'payments',
        where: 'id = ?',
        whereArgs: [outcome.replacementPaymentId],
      )).single;
      expect(replacement['replaces_payment_id'], origin);
      final receipt = (await db.query(
        'generated_documents',
        where: 'payment_id = ?',
        whereArgs: [outcome.replacementPaymentId],
      )).single;
      expect(receipt['number'] as String, startsWith('PROV-'));
    });

    // Le remplaçant voyage DANS la correction : une entrée `PAYMENT` à lui le
    // pousserait une seconde fois.
    test('le remplaçant voyage dans la correction, jamais seul', () async {
      final origin = await collect(15000);
      await syncOrigin(origin, 15000);

      final outcome = (await corrections.correctPayment(
        replaceOf(origin, 5000),
      )).getOrElse(() => throw StateError('refusé'));

      expect(await outbox('PAYMENT'), isEmpty);
      final payload =
          jsonDecode(
                (await outbox(kPaymentCorrectionAggregate)).single['payload']
                    as String,
              )
              as Map;
      final replacement = payload['replacement'] as Map;
      expect(
        (replacement['payment'] as Map)['id'],
        outcome.replacementPaymentId,
      );
      expect(replacement['allocations'], hasLength(1));
      expect(payload['reason'], 'Saisi 150 \$ au lieu de 50 \$');
    });
  });

  // Ce que la liste des versements lit : la dernière correction de chacun.
  group('liste des versements', () {
    test('l origine porte sa correction, le remplaçant son origine', () async {
      final origin = await collect(15000);
      final outcome = (await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: PaymentCorrectionReason.wrongAmount,
          replacement: draftOf(5000),
        ),
      )).getOrElse(() => throw StateError('refusé'));

      final payments = await ledger.getPaymentsByStudent('s-1');
      final first = payments.singleWhere((p) => p.id == origin);
      final second = payments.singleWhere(
        (p) => p.id == outcome.replacementPaymentId,
      );
      expect(first.correction?.status, PaymentCorrectionStatus.pending);
      expect(first.correction?.replacementPaymentId, second.id);
      expect(second.replacesPaymentId, origin);
      expect(second.correction, isNull);
    });
  });

  // D1 : vers qui déplacer un versement.
  group('élèves cibles', () {
    Future<void> enrolled(
      String id,
      String last,
      String first, {
      String status = 'COMPLETED',
      String year = 'ay-1',
    }) async {
      await db.insert('students', {
        'id': id,
        'first_name': first,
        'last_name': last,
        'gender': 'F',
        'date_of_birth': '2015-01-01',
      });
      await db.insert('enrollments', {
        'id': 'e-$id-$year',
        'student_id': id,
        'enrollment_type': 'NEW',
        'status': status,
        'academic_year_id': year,
        'enrollment_date': '2026-09-01',
      });
    }

    Future<List<String>> found(String query) async => [
      for (final t in (await corrections.searchTargets(
        query: query,
        academicYearId: 'ay-1',
        excludeStudentId: 's-1',
      )).getOrElse(() => const []))
        t.studentId,
    ];

    test('les inscrits de l année, accents pliés', () async {
      await enrolled('s-2', 'Tshiala', 'Grâce');
      await enrolled('s-3', 'Mbuyi', 'Joël');

      expect(await found('grace'), ['s-2']);
      expect(await found('JOEL'), ['s-3']);
    });

    test(
      'ni l élève d origine, ni un dossier annulé, ni une autre année',
      () async {
        await enrolled('s-1', 'Tshiala', 'Gloredi');
        await enrolled('s-4', 'Tshiala', 'Annulé', status: 'CANCELLED');
        await enrolled('s-5', 'Tshiala', 'Ancien', year: 'ay-0');

        expect(await found('tshiala'), isEmpty);
      },
    );

    test('cinq au plus', () async {
      for (var i = 0; i < 7; i++) {
        await enrolled('x-$i', 'Kabongo', 'Enfant $i');
      }

      expect(await found('kabongo'), hasLength(5));
    });
  });

  // R2 : une origine refusée pour de bon ne sera jamais synchronisée.
  group('origine refusée par le serveur', () {
    test('la correction reste locale, le remplaçant part seul', () async {
      final origin = await collect(15000);
      await db.update(
        'outbox',
        {'status': 'SYNC_ERROR'},
        where: 'aggregate_id = ?',
        whereArgs: [origin],
      );

      final outcome = (await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: PaymentCorrectionReason.wrongAmount,
          replacement: draftOf(5000),
        ),
      )).getOrElse(() => throw StateError('refusé'));

      expect(outcome.localOnly, isTrue);
      expect(await outbox(kPaymentCorrectionAggregate), isEmpty);
      // L'entrée de l'origine est sortie : « Réessayer » ne peut plus la
      // remettre en file.
      final payments = await outbox('PAYMENT');
      expect(payments.single['aggregate_id'], outcome.replacementPaymentId);
      expect(await remaining(), 10000);
    });
  });

  group('refus', () {
    test('un motif sans rapport avec le geste', () async {
      final origin = await collect(15000);

      final result = await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: PaymentCorrectionReason.duplicate,
          replacement: draftOf(5000),
        ),
      );

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('« Autre » sans précision', () async {
      final origin = await collect(15000);

      final result = await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: PaymentCorrectionReason.other,
          reasonDetail: '   ',
        ),
      );

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    });

    test('un second geste sur un versement déjà corrigé', () async {
      final origin = await collect(15000);
      await corrections.correctPayment(cancelOf(origin));

      final result = await corrections.correctPayment(cancelOf(origin));

      expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
      expect(await outbox(kPaymentCorrectionAggregate), hasLength(1));
    });

    test('une correction refusée rend le geste de nouveau possible', () async {
      final origin = await collect(15000);
      await corrections.correctPayment(cancelOf(origin));
      await db.update('payment_corrections', {'status': 'REJECTED'});
      expect(await remaining(), 0);

      final result = await corrections.correctPayment(cancelOf(origin));

      expect(result.isRight(), isTrue);
      expect(await remaining(), 15000);
    });

    test('un remplaçant invalide n écrit rien', () async {
      final origin = await collect(15000);

      final result = await corrections.correctPayment(
        PaymentCorrectionDraft(
          paymentId: origin,
          reason: PaymentCorrectionReason.wrongAmount,
          replacement: draftOf(0),
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(await db.query('payment_corrections'), isEmpty);
      expect(await remaining(), 0);
    });
  });
}
