import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:uuid/uuid.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';

import '../../offline_full_db.dart';

class MockFinancePullApi extends Mock implements FinancePullApi {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockCredentialsProbe extends Mock implements SessionCredentialsProbe {}

void main() {
  late Database db;
  late MockFinancePullApi api;
  late MockConnectivityService connectivity;
  late MockCredentialsProbe credentialsProbe;
  late SyncMetaDao syncMeta;
  late FinanceLedgerRefresher refresher;

  const auth = <String, dynamic>{'requiresAuth': true};
  const studentId = 'stu-1';
  const yearId = 'ay-1';
  const resource = 'finance_ledger:$studentId';
  var clock = 10000;
  late int paymentsSyncCalls;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockFinancePullApi();
    connectivity = MockConnectivityService();
    credentialsProbe = MockCredentialsProbe();
    when(
      () => credentialsProbe.canAuthenticate(),
    ).thenAnswer((_) async => true);
    syncMeta = SyncMetaDao(db);
    clock = 10000;
    paymentsSyncCalls = 0;
    refresher = FinanceLedgerRefresher(
      api: api,
      dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
      syncMetaDao: syncMeta,
      connectivity: connectivity,
      credentialsProbe: credentialsProbe,
      extras: auth,
      syncPayments: () async {
        paymentsSyncCalls++;
        return true;
      },
      now: () => clock,
    );
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  });

  tearDown(() async {
    await refresher.dispose();
    await db.close();
  });

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  KeysetPageEnvelope env({String? nextCursor, bool hasMore = false}) =>
      KeysetPageEnvelope(
        nextCursor: nextCursor,
        hasMore: hasMore,
        serverTime: '2026-07-16T10:00:01Z',
      );

  StudentChargeDto charge(String id) => StudentChargeDto(
    id: id,
    studentId: studentId,
    academicYearId: yearId,
    feeCode: 'SCOLARITE',
    label: 'Scolarité',
    expectedAmountInCents: 50000,
    amountPaidInCents: 0,
    currency: 'CDF',
    status: 'UNPAID',
  );

  test(
    'en ligne : pull scopé à l\'élève (studentId + année), créances upsertées '
    'SYNCED et fraîcheur bumpée — sans jeton de cycle (point read)',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await refresher.refresh(studentId, yearId);

      verify(
        () => api.pullStudentCharges(auth, null, 100, yearId, studentId),
      ).called(1);
      final rows = await db.query('student_charges');
      expect(rows.single['sync_status'], 'SYNCED');
      expect(rows.single['status'], 'DUE');
      // Fraîcheur affichée (ADR-002) ; aucun curseur mémorisé : le point read ne
      // doit pas interférer avec le cycle du pull de masse.
      expect(await syncMeta.getSyncedAt(resource), clock);
      expect(await syncMeta.getCursor(resource), isNull);
      expect(await refresher.lastSyncedAt(studentId), clock);
    },
  );

  test(
    'hors-ligne : aucun appel réseau, cache et fraîcheur inchangés',
    () async {
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);

      await refresher.refresh(studentId, yearId);

      verifyNever(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      );
      expect(await syncMeta.getSyncedAt(resource), isNull);
      expect(paymentsSyncCalls, 0, reason: 'aucun des deux pulls ne part');
    },
  );

  test(
    'échec réseau : best-effort — ne lève pas, fraîcheur NON bumpée (l\'UI lit '
    'le cache tel quel)',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(refresher.refresh(studentId, yearId), completes);
      expect(await syncMeta.getSyncedAt(resource), isNull);
      expect(await db.query('student_charges'), isEmpty);
    },
  );

  test(
    'en ligne : le cycle GLOBAL des paiements est avancé — sans lui l\'historique '
    '(replié en « total payé » à l\'écran) ignorerait l\'autre poste',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await refresher.refresh(studentId, yearId);

      expect(paymentsSyncCalls, 1);
    },
  );

  test(
    'le point read des créances a ÉCHOUÉ → le cycle des paiements NE part PAS : '
    'avancer les paiements sur des créances périmées fait réencaisser',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
      );

      await refresher.refresh(studentId, yearId);

      expect(paymentsSyncCalls, 0);
    },
  );

  test(
    'un cycle paiements en échec ne fait pas échouer la lecture, mais la '
    'fraîcheur n\'est PAS estampillée : « à jour à HHhMM » couvre les DEUX faces '
    'du grand-livre (l\'écran replie l\'historique en « total payé »)',
    () async {
      final failing = FinanceLedgerRefresher(
        api: api,
        dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
        syncMetaDao: syncMeta,
        connectivity: connectivity,
        credentialsProbe: credentialsProbe,
        extras: auth,
        syncPayments: () async => throw Exception('boom'),
        now: () => clock,
      );
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await expectLater(failing.refresh(studentId, yearId), completes);
      // Les créances SONT appliquées (rien n'est perdu)…
      expect(await db.query('student_charges'), hasLength(1));
      // …mais on ne prétend PAS que le grand-livre est à jour.
      expect(await syncMeta.getSyncedAt(resource), isNull);
    },
  );

  test(
    'cycle paiements en échec « propre » (false du seam) : même règle, aucune '
    'fraîcheur estampillée',
    () async {
      final failing = FinanceLedgerRefresher(
        api: api,
        dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
        syncMetaDao: syncMeta,
        connectivity: connectivity,
        credentialsProbe: credentialsProbe,
        extras: auth,
        syncPayments: () async => false,
        now: () => clock,
      );
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await failing.refresh(studentId, yearId);

      expect(await syncMeta.getSyncedAt(resource), isNull);
    },
  );

  test(
    'cycle des paiements trop long (bootstrap sur lien lent) : la LECTURE rend '
    'la main au bout du délai — offline-first — sans prétendre être à jour',
    () async {
      final slow = Completer<bool>(); // ne se terminera jamais dans ce test
      final bounded = FinanceLedgerRefresher(
        api: api,
        dao: FinanceLocalDao(db, const IdGenerator(Uuid())),
        syncMetaDao: syncMeta,
        connectivity: connectivity,
        credentialsProbe: credentialsProbe,
        extras: auth,
        syncPayments: () => slow.future,
        paymentsDeadline: const Duration(milliseconds: 30),
        now: () => clock,
      );
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      // La lecture n'attend pas le cycle global : elle rend la main.
      await bounded
          .refresh(studentId, yearId)
          .timeout(const Duration(seconds: 5));

      // Les créances de l'élève sont bien là (le point read, lui, est borné)…
      expect(await db.query('student_charges'), hasLength(1));
      // …mais l'historique n'est pas garanti → aucune fraîcheur affichée.
      expect(await syncMeta.getSyncedAt(resource), isNull);
    },
  );

  test(
    '304 sur le point read (« rien n\'a changé ») = miroir À JOUR : le cycle des '
    'paiements part quand même, et la fraîcheur est estampillée',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          response: Response(
            requestOptions: RequestOptions(path: '/'),
            statusCode: 304,
          ),
        ),
      );

      await refresher.refresh(studentId, yearId);

      expect(paymentsSyncCalls, 1);
      expect(await syncMeta.getSyncedAt(resource), clock);
    },
  );

  test('pagination : suit nextCursor tant que hasMore', () async {
    var call = 0;
    when(
      () => api.pullStudentCharges(any(), any(), any(), any(), any()),
    ).thenAnswer(
      (_) async => call++ == 0
          ? httpOk(
              StudentChargePageDto(
                items: [charge('ch-1')],
                page: env(nextCursor: 'C1', hasMore: true),
              ),
            )
          : httpOk(StudentChargePageDto(items: [charge('ch-2')], page: env())),
    );

    await refresher.refresh(studentId, yearId);

    verify(
      () => api.pullStudentCharges(auth, 'C1', 100, yearId, studentId),
    ).called(1);
    expect((await db.query('student_charges')).length, 2);
  });

  test(
    'garde anti-boucle : hasMore avec un nextCursor identique → on arrête',
    () async {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          StudentChargePageDto(
            items: [charge('ch-1')],
            // hasMore sans nextCursor : serveur défaillant → arrêt immédiat.
            page: env(hasMore: true),
          ),
        ),
      );

      await refresher.refresh(studentId, yearId);

      verify(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).called(1);
    },
  );

  test('dédup in-flight : deux refresh concurrents (Créances + Paiements) → un '
      'seul appel réseau ; un refresh ultérieur repart bien', () async {
    final gate = Completer<void>();
    when(
      () => api.pullStudentCharges(any(), any(), any(), any(), any()),
    ).thenAnswer((_) async {
      await gate.future;
      return httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env()));
    });

    final first = refresher.refresh(studentId, yearId);
    final second = refresher.refresh(studentId, yearId);
    gate.complete();
    await Future.wait([first, second]);

    verify(
      () => api.pullStudentCharges(any(), any(), any(), any(), any()),
    ).called(1);

    // Le guard est relâché en fin de course : le prochain refresh réappelle —
    // une fois le TTL passé, qui est l'AUTRE barrage (groupe dédié plus bas).
    clock += const Duration(seconds: 121).inMilliseconds;
    await refresher.refresh(studentId, yearId);
    verify(
      () => api.pullStudentCharges(any(), any(), any(), any(), any()),
    ).called(1);
  });

  // ── M-8 : amortissement (TTL), borne d'attente, signal de revalidation ────
  group('régime stale-while-revalidate', () {
    void chargesRespond() {
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );
    }

    test(
      'TTL : un cycle abouti n\'est pas rejoué — la réouverture de la fiche ne '
      'repaie pas l\'aller-retour',
      () async {
        chargesRespond();

        await refresher.refresh(studentId, yearId);
        await refresher.refresh(studentId, yearId);
        await refresher.refresh(studentId, yearId);

        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1);
        expect(paymentsSyncCalls, 1);

        clock += const Duration(seconds: 121).inMilliseconds;
        await refresher.refresh(studentId, yearId);
        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1);
      },
    );

    test(
      'TTL : l\'encaissement exige une fraîcheur plus courte et rejoue le cycle',
      () async {
        chargesRespond();
        await refresher.refresh(studentId, yearId);
        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1);

        // Le régime de LECTURE se tairait (120 s) ; celui de l'encaissement, non.
        clock += const Duration(seconds: 16).inMilliseconds;
        await refresher.refresh(studentId, yearId);
        verifyNever(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        );

        await refresher.refresh(
          studentId,
          yearId,
          maxAge: const Duration(seconds: 15),
        );
        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(1);
      },
    );

    test(
      'TTL : un cycle EN ÉCHEC ne s\'amortit pas — la lecture suivante retente',
      () async {
        when(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).thenThrow(Exception('serveur muet'));

        await refresher.refresh(studentId, yearId);
        await refresher.refresh(studentId, yearId);

        verify(
          () => api.pullStudentCharges(any(), any(), any(), any(), any()),
        ).called(2);
        expect(paymentsSyncCalls, 0, reason: 'créances KO ⇒ paiements écartés');
        expect(await syncMeta.getSyncedAt(resource), isNull);
      },
    );

    test('deadline : l\'appelant reprend la main sans annuler le cycle ni le '
        'dupliquer', () async {
      final gate = Completer<void>();
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer((_) async {
        await gate.future;
        return httpOk(
          StudentChargePageDto(items: [charge('ch-1')], page: env()),
        );
      });

      // Rend la main alors que le réseau n'a rien rendu : c'est tout l'objet
      // de la borne — un encaissement ne reste pas suspendu à un serveur lent.
      await refresher
          .refresh(
            studentId,
            yearId,
            deadline: const Duration(milliseconds: 30),
          )
          .timeout(const Duration(seconds: 5));
      expect(await syncMeta.getSyncedAt(resource), isNull);

      // Le cycle n'a pas été annulé : il tient toujours son entrée in-flight,
      // donc un second appel le REJOINT au lieu d'ouvrir un doublon réseau.
      final joined = refresher.refresh(
        studentId,
        yearId,
        maxAge: Duration.zero,
      );
      gate.complete();
      await joined;

      verify(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).called(1);
      expect(await syncMeta.getSyncedAt(resource), clock);
    });

    test('signal : un cycle abouti annonce l\'élève relu', () async {
      chargesRespond();
      final seen = <String>[];
      final sub = refresher.revalidated.listen(seen.add);
      addTearDown(sub.cancel);

      await refresher.refresh(studentId, yearId);
      await Future<void>.delayed(Duration.zero);

      expect(seen, [studentId]);
    });

    test(
      'signal : hors ligne, rien n\'est annoncé (rien n\'a été relu)',
      () async {
        when(() => connectivity.isOnline()).thenAnswer((_) async => false);
        final seen = <String>[];
        final sub = refresher.revalidated.listen(seen.add);
        addTearDown(sub.cancel);

        await refresher.refresh(studentId, yearId);
        await Future<void>.delayed(Duration.zero);

        expect(seen, isEmpty);
      },
    );
  });

  test(
    'gate crédentiels : sans session authentifiable, aucun des deux pulls ne '
    'part et la fraîcheur n\'est pas bumpée',
    () async {
      when(
        () => credentialsProbe.canAuthenticate(),
      ).thenAnswer((_) async => false);
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await refresher.refresh(studentId, yearId);

      verifyNever(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      );
      expect(paymentsSyncCalls, 0);
      expect(await syncMeta.getSyncedAt(resource), isNull);
    },
  );

  test(
    'gate crédentiels : une sonde en échec ne bloque pas la lecture (fail-open, '
    'même politique que SyncStatusCubit)',
    () async {
      when(
        () => credentialsProbe.canAuthenticate(),
      ).thenThrow(Exception('storage indisponible'));
      when(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(StudentChargePageDto(items: [charge('ch-1')], page: env())),
      );

      await refresher.refresh(studentId, yearId);

      verify(
        () => api.pullStudentCharges(any(), any(), any(), any(), any()),
      ).called(1);
      expect(await syncMeta.getSyncedAt(resource), clock);
    },
  );
}
