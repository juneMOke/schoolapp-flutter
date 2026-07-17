import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';

import '../../offline_full_db.dart';

class MockFinancePullApi extends Mock implements FinancePullApi {}

void main() {
  late Database db;
  late MockFinancePullApi api;
  late SyncMetaDao syncMeta;
  late FinanceLocalDao dao;
  late FinancePullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const limit = FinancePullRepositoryImpl.pageLimit;
  const chargesResource = FinancePullRepositoryImpl.chargesResource;
  const paymentsResource = FinancePullRepositoryImpl.paymentsResource;
  var clock = 10000;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockFinancePullApi();
    syncMeta = SyncMetaDao(db);
    // Le pull n'engendre aucun id (les modèles arrivent identifiés du serveur) :
    // le générateur réel suffit, aucun besoin de le rendre déterministe ici.
    dao = FinanceLocalDao(db, const IdGenerator(Uuid()));
    clock = 10000;
    repo = FinancePullRepositoryImpl(
      api: api,
      dao: dao,
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      now: () => clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  /// Déplie un Right attendu (échoue le test sur un Left, sans unwrap direct).
  FinancePullOutcome right(Either<Failure, FinancePullOutcome> either) =>
      either.fold((f) => fail('Attendu Right, reçu Left($f)'), (o) => o);

  /// Déplie un Left attendu.
  Failure left(Either<Failure, FinancePullOutcome> either) =>
      either.fold((f) => f, (o) => fail('Attendu Left, reçu Right'));

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException notModified304() => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 304,
    ),
  );

  DioException network() => DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.connectionError,
  );

  DioException invalidCursor400() => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 400,
    ),
  );

  KeysetPageEnvelope env({
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
  }) => KeysetPageEnvelope(
    nextCursor: nextCursor,
    nextWatermark: nextWatermark,
    hasMore: hasMore,
    serverTime: '2026-07-16T10:00:01Z',
  );

  StudentChargeDto charge(
    String id, {
    String studentId = 'stu-1',
    String status = 'UNPAID',
    int expected = 50000,
    int paid = 0,
  }) => StudentChargeDto(
    id: id,
    studentId: studentId,
    academicYearId: 'ay-1',
    feeCode: 'SCOLARITE',
    label: 'Scolarité',
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'CDF',
    status: status,
  );

  PaymentDeltaDto paymentDelta(
    String id, {
    String studentId = 'stu-1',
    int amount = 20000,
    List<PaymentPullAllocationDto> allocations = const [],
  }) => PaymentDeltaDto(
    payment: PaymentDto(
      id: id,
      studentId: studentId,
      academicYearId: 'ay-1',
      amountInCents: amount,
      currency: 'CDF',
      method: 'CASH',
      paidAt: '2026-07-16T09:00:00Z',
      payerFirstName: 'Ada',
      payerLastName: 'Lovelace',
    ),
    allocations: allocations,
  );

  void stubCharges(List<HttpResponse<StudentChargePageDto>> pages) {
    var call = 0;
    when(
      () => api.pullStudentCharges(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async => pages[call++]);
  }

  group('syncStudentCharges — pull keyset §2.1', () {
    test(
      'bootstrap : aucun jeton mémorisé → cursor absent ; créances upsertées '
      'SYNCED, UNPAID normalisé en DUE, watermark mémorisé',
      () async {
        stubCharges([
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-1'), charge('ch-2')],
              page: env(nextWatermark: 'WM1'),
            ),
          ),
        ]);

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.notModified, isFalse);
        expect(outcome.upserted, 2);
        expect(outcome.syncedAt, clock);
        expect(outcome.cursor, 'WM1'); // jeton rendu = jeton mémorisé
        final sent = verify(
          () => api.pullStudentCharges(auth, captureAny(), limit, null, null),
        ).captured;
        expect(sent, [null]); // bootstrap : aucun jeton

        final rows = await db.query('student_charges', orderBy: 'id');
        expect(rows.length, 2);
        expect(rows.first['sync_status'], 'SYNCED');
        expect(rows.first['status'], 'DUE'); // UNPAID (contrat) → DUE (local)
        expect(rows.first['synced_at'], clock);

        // Fin de cycle → le watermark devient le départ du prochain cycle.
        expect(await syncMeta.getCursor(chargesResource), 'WM1');
        expect(await syncMeta.getSyncedAt(chargesResource), clock);
      },
    );

    test(
      'pagination : chaque page mémorise son nextCursor (reprise), la dernière '
      'bascule sur le watermark ; la page 2 part du curseur',
      () async {
        stubCharges([
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextCursor: 'C1', hasMore: true),
            ),
          ),
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-2')],
              page: env(nextWatermark: 'WM2'),
            ),
          ),
        ]);

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.upserted, 2);
        final sent = verify(
          () => api.pullStudentCharges(auth, captureAny(), limit, null, null),
        ).captured;
        expect(sent, [null, 'C1']); // page 1 : bootstrap — page 2 : nextCursor
        expect(await syncMeta.getCursor(chargesResource), 'WM2');
        expect((await db.query('student_charges')).length, 2);
      },
    );

    test(
      'reprise après coupure : le curseur mémorisé repart en `cursor`',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'C9', syncedAt: 1);
        stubCharges([
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextWatermark: 'WM3'),
            ),
          ),
        ]);

        await repo.syncStudentCharges();

        final sent = verify(
          () => api.pullStudentCharges(auth, captureAny(), limit, null, null),
        ).captured;
        expect(sent, ['C9']);
      },
    );

    test(
      'jeton unique : un watermark de fin de cycle repart sur le MÊME paramètre '
      '`cursor` (contrat 1.1.0 — pas de paramètre watermark séparé)',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'WM0', syncedAt: 1);
        stubCharges([
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextWatermark: 'WM4'),
            ),
          ),
        ]);

        await repo.syncStudentCharges();

        final sent = verify(
          () => api.pullStudentCharges(auth, captureAny(), limit, null, null),
        ).captured;
        expect(sent, ['WM0']); // renvoyé verbatim, sans discrimination
        expect(await syncMeta.getCursor(chargesResource), 'WM4');
      },
    );

    test(
      'garde anti-boucle : hasMore avec un nextCursor identique à celui envoyé '
      '→ on arrête ET on remonte un échec (un blocage doit se VOIR, pas passer '
      'pour une synchro réussie)',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'C1', syncedAt: 1);
        stubCharges([
          httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextCursor: 'C1', hasMore: true),
            ),
          ),
        ]);

        final failure = left(await repo.syncStudentCharges());

        expect(failure, isA<ServerFailure>());
        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1); // la page n'est pas rejouée
      },
    );

    test(
      '304 : rien de neuf → notModified, jeton conservé, fraîcheur bumpée',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'WM0', syncedAt: 1);
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenThrow(notModified304());

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.notModified, isTrue);
        expect(outcome.cursor, 'WM0'); // jeton conservé
        expect(await syncMeta.getCursor(chargesResource), 'WM0');
        expect(await syncMeta.getSyncedAt(chargesResource), clock);
      },
    );

    test(
      'échec réseau : error, jeton ET fraîcheur inchangés (ne lève pas)',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'WM0', syncedAt: 1);
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenThrow(network());

        final failure = left(await repo.syncStudentCharges());

        expect(failure, isA<ServerFailure>());
        expect(await syncMeta.getCursor(chargesResource), 'WM0');
        expect(await syncMeta.getSyncedAt(chargesResource), 1);
      },
    );

    test(
      '400 (curseur forgé / émis pour une autre ressource) → le jeton fautif '
      'est purgé et le cycle repart du bootstrap, sans wedge permanent',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'BAD', syncedAt: 1);
        var call = 0;
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async {
          if (call++ == 0) throw invalidCursor400();
          return httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextWatermark: 'WM-NEW'),
            ),
          );
        });

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.upserted, 1);
        final sent = verify(
          () => api.pullStudentCharges(auth, captureAny(), limit, null, null),
        ).captured;
        expect(sent, ['BAD', null]); // rejeté, puis bootstrap
        expect(await syncMeta.getCursor(chargesResource), 'WM-NEW');
        expect((await db.query('student_charges')).length, 1);
      },
    );

    test(
      'migration du contrat 1.0 : un jeton préfixé `w…` resté en base est rejeté '
      'en 400 puis dissous par le bootstrap (la tablette se resynchronise)',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'wWM0', syncedAt: 1);
        var call = 0;
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenAnswer((_) async {
          if (call++ == 0) throw invalidCursor400();
          return httpOk(
            StudentChargePageDto(
              items: [charge('ch-1')],
              page: env(nextWatermark: 'WM-CLEAN'),
            ),
          );
        });

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.notModified, isFalse);
        expect(await syncMeta.getCursor(chargesResource), 'WM-CLEAN');
      },
    );

    test(
      '400 dès le bootstrap (jeton déjà absent) → error, pas de boucle',
      () async {
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenThrow(invalidCursor400());

        final failure = left(await repo.syncStudentCharges());

        expect(failure, isA<ServerFailure>());
        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1); // aucun retry : le jeton n'est pas en cause
      },
    );

    test(
      'page vide en fin de cycle sans watermark → jeton conservé, notModified',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'WM0', syncedAt: 1);
        stubCharges([
          httpOk(StudentChargePageDto(items: const [], page: env())),
        ]);

        final outcome = right(await repo.syncStudentCharges());

        expect(outcome.notModified, isTrue);
        expect(await syncMeta.getCursor(chargesResource), 'WM0');
        expect(await syncMeta.getSyncedAt(chargesResource), clock);
      },
    );
  });

  group('syncPayments — pull global §2.2', () {
    test(
      'paiements de l\'autre poste : upsert SYNCED + allocations rattachées au '
      'paiement parent (devise héritée, libellé replié sur le fee_code)',
      () async {
        when(() => api.pullPayments(any(), any(), any(), any())).thenAnswer(
          (_) async => httpOk(
            PaymentPageDto(
              items: [
                paymentDelta(
                  'pay-1',
                  allocations: const [
                    PaymentPullAllocationDto(
                      id: 'alloc-1',
                      studentChargeId: 'ch-1',
                      feeCode: 'SCOLARITE',
                      amountInCents: 20000,
                    ),
                  ],
                ),
              ],
              page: env(nextWatermark: 'WMP1'),
            ),
          ),
        );

        final outcome = right(await repo.syncPayments());

        expect(outcome.notModified, isFalse);
        expect(outcome.upserted, 1);

        final payments = await db.query('payments');
        expect(payments.single['sync_status'], 'SYNCED');
        expect(payments.single['synced_at'], clock);

        final allocs = await db.query('payment_allocations');
        expect(allocs.single['payment_id'], 'pay-1'); // parent, absent du DTO
        expect(allocs.single['currency'], 'CDF'); // héritée du paiement
        expect(allocs.single['student_charge_label'], 'SCOLARITE'); // repli
        expect(allocs.single['amount_in_cents'], 20000);

        expect(await syncMeta.getCursor(paymentsResource), 'WMP1');
      },
    );

    test(
      'cycles sérialisés par CHAÎNAGE : un appelant arrivé pendant un cycle en '
      'vol obtient un cycle qui démarre APRÈS lui (jamais un delta antérieur à '
      'son besoin de fraîcheur), et jamais deux cycles en parallèle',
      () async {
        final gate = Completer<void>();
        var started = 0, running = 0, maxParallel = 0;
        when(() => api.pullPayments(any(), any(), any(), any())).thenAnswer((
          _,
        ) async {
          started++;
          running++;
          maxParallel = running > maxParallel ? running : maxParallel;
          if (started == 1) await gate.future; // le 1er cycle est retenu
          running--;
          return httpOk(
            PaymentPageDto(
              items: [paymentDelta('pay-$started')],
              page: env(nextWatermark: 'WM-$started'),
            ),
          );
        });

        final first = repo.syncPayments(); // montage du scope
        final second = repo.syncPayments(); // lecture, pendant le 1er
        gate.complete();
        await Future.wait([first, second]);

        expect(started, 2, reason: 'le 2e appelant a eu SON cycle');
        expect(
          maxParallel,
          1,
          reason: 'jamais concurrents : pas de rembobinage',
        );
        expect(await syncMeta.getCursor(paymentsResource), 'WM-2');
      },
    );

    test(
      'chaîne bornée à deux : les appelants qui arrivent pendant qu\'un cycle '
      'attend déjà se coalescent sur lui (il démarrera après eux)',
      () async {
        final gate = Completer<void>();
        var started = 0;
        when(() => api.pullPayments(any(), any(), any(), any())).thenAnswer((
          _,
        ) async {
          started++;
          if (started == 1) await gate.future;
          return httpOk(
            PaymentPageDto(
              items: const [],
              page: env(nextWatermark: 'WM'),
            ),
          );
        });

        final calls = [
          repo.syncPayments(), // démarre
          repo.syncPayments(), // chaîné
          repo.syncPayments(), // se coalesce sur le chaîné
          repo.syncPayments(), // idem
        ];
        gate.complete();
        await Future.wait(calls);

        expect(started, 2, reason: '1 qui tourne + 1 qui attend, pas 4');
      },
    );

    test(
      'guard relâché en fin de course : le cycle suivant repart bien',
      () async {
        var calls = 0;
        when(() => api.pullPayments(any(), any(), any(), any())).thenAnswer((
          _,
        ) async {
          calls++;
          return httpOk(
            PaymentPageDto(
              items: const [],
              page: env(nextWatermark: 'WM'),
            ),
          );
        });

        await repo.syncPayments();
        await repo.syncPayments();

        expect(calls, 2);
      },
    );

    test(
      'les deux ressources ont des cycles indépendants (jetons distincts)',
      () async {
        await syncMeta.setCursor(chargesResource, cursor: 'CH', syncedAt: 1);
        when(() => api.pullPayments(any(), any(), any(), any())).thenAnswer(
          (_) async => httpOk(
            PaymentPageDto(
              items: [paymentDelta('pay-1')],
              page: env(nextWatermark: 'WMP2'),
            ),
          ),
        );

        await repo.syncPayments();

        expect(await syncMeta.getCursor(paymentsResource), 'WMP2');
        expect(await syncMeta.getCursor(chargesResource), 'CH'); // intact
      },
    );
  });
}
