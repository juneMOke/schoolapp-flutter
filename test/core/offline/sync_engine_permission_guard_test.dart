import 'dart:convert';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'offline_test_db.dart';

class _MockConnectivity extends Mock implements Connectivity {}

/// Répond toujours [status] avec [body], après un passage par l'event loop
/// (comme un vrai socket) : la zone doit survivre à l'asynchronisme.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, [this.body]);

  final int status;
  final Map<String, dynamic>? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(Duration.zero);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, [Map<String, dynamic>? body]) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _StubAdapter(status, body)
      ..interceptors.add(OutboxPermissionProbeInterceptor());

const Map<String, dynamic> _permissionDenial = {
  'code': 'FORBIDDEN',
  'message': 'Accès refusé.',
};

const Map<String, dynamic> _businessDenial = {
  'code': 'FORBIDDEN',
  'detailCode': 'MONTH_CLOSURE_FORBIDDEN',
  'message': 'Mois clos.',
};

/// Handler qui pousse par un vrai Dio et classe tout 4xx en TERMINAL, comme
/// la plupart des handlers du dépôt classent le 403.
class _HttpHandler implements OutboxSyncHandler, OutboxWriteAccess {
  _HttpHandler(this.dio, {this.access = kExpenseDecideAccess});

  final Dio dio;
  final ModuleAccess? access;
  int calls = 0;

  @override
  String get aggregateType => 'EXPENSE_GESTURE';

  @override
  ModuleAccess? writeAccessFor(OutboxEntry entry) => access;

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    calls++;
    try {
      await dio.post<dynamic>('/sync/expenses/x/decision');
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      return status >= 400 && status < 500
          ? OutboxDispatchResult.failed('HTTP_$status')
          : OutboxDispatchResult.retry('HTTP_$status');
    }
  }
}

void main() {
  late Database db;
  late OutboxDao dao;
  late _MockConnectivity connectivity;
  late CurrentPermissions permissions;

  const int fixedNow = 100000;

  OutboxEntry entry(String id) => OutboxEntry(
    id: id,
    aggregateType: 'EXPENSE_GESTURE',
    aggregateId: 'agg-$id',
    operation: OutboxOperation.create,
    payload: '{}',
    createdAt: 1000,
  );

  SyncEngine engine(OutboxSyncHandler handler) => SyncEngine(
    outbox: dao,
    connectivity: ConnectivityService(connectivity),
    permissions: permissions,
    now: () => fixedNow,
  )..registerHandler(handler);

  setUp(() async {
    db = await openInMemoryOfflineDb();
    dao = OutboxDao(db);
    connectivity = _MockConnectivity();
    when(
      () => connectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.wifi]);
    permissions = CurrentPermissions();
  });

  tearDown(() async => db.close());

  group('pré-garde', () {
    test('droits connus sans le droit exigé : retenue SANS appel réseau, '
        'sans tentative consommée', () async {
      permissions.set([Perm.expenseWrite.wire]);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(200));

      final report = await engine(handler).flush();

      expect(handler.calls, 0);
      expect(report.blocked, 1);
      final row = (await dao.byId('e1'))!;
      expect(row.status, OutboxStatus.pending);
      expect(row.attempts, 0);
      expect(row.lastError, kOutboxAwaitingPermissionReason);
      expect(row.nextAttemptAt, fixedNow + 5000);
    });

    test('droit détenu : l\'entrée part', () async {
      permissions.set([Perm.expenseDecide.wire]);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(200));

      final report = await engine(handler).flush();

      expect(handler.calls, 1);
      expect(report.acked, 1);
    });

    test(
      'droits INCONNUS : la synchronisation reste ouverte (ADR-014 §13.2)',
      () async {
        permissions.set(null);
        await dao.enqueue(entry('e1'));
        final handler = _HttpHandler(_dio(200));

        await engine(handler).flush();

        expect(handler.calls, 1);
      },
    );

    test(
      'ensemble VIDE : c\'est une information, l\'entrée est retenue',
      () async {
        permissions.set(const []);
        await dao.enqueue(entry('e1'));
        final handler = _HttpHandler(_dio(200));

        await engine(handler).flush();

        expect(handler.calls, 0);
      },
    );

    test('un handler qui ne déclare rien n\'est pas gardé', () async {
      permissions.set(const []);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(200), access: null);

      await engine(handler).flush();

      expect(handler.calls, 1);
    });
  });

  group('sonde : 403 reçu avant que la tablette ne connaisse le retrait', () {
    test(
      '403 SANS detailCode : retenue 5 min au lieu du SYNC_ERROR terminal',
      () async {
        // La tablette croit encore détenir le droit : la pré-garde laisse
        // partir, le serveur refuse.
        permissions.set([Perm.expenseDecide.wire]);
        await dao.enqueue(entry('e1'));
        final handler = _HttpHandler(_dio(403, _permissionDenial));

        final report = await engine(handler).flush();

        expect(handler.calls, 1);
        expect(report.failed, 0);
        expect(report.blocked, 1);
        final row = (await dao.byId('e1'))!;
        expect(row.status, OutboxStatus.pending);
        expect(row.attempts, 0);
        expect(row.lastError, kOutboxAwaitingPermissionReason);
        expect(row.nextAttemptAt, fixedNow + 300000);
      },
    );

    test('403 AVEC detailCode : refus métier, reste terminal', () async {
      permissions.set([Perm.expenseDecide.wire]);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(403, _businessDenial));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
      expect((await dao.byId('e1'))!.status, OutboxStatus.syncError);
    });

    test('un autre 4xx (422) reste terminal', () async {
      permissions.set([Perm.expenseDecide.wire]);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(422, const {'code': 'UNPROCESSABLE'}));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
    });

    test('la sonde ne déborde pas d\'une entrée sur la suivante', () async {
      permissions.set([Perm.expenseDecide.wire]);
      await dao.enqueue(entry('e1'));
      await dao.enqueue(
        const OutboxEntry(
          id: 'e2',
          aggregateType: 'OTHER',
          aggregateId: 'agg-e2',
          operation: OutboxOperation.create,
          payload: '{}',
          createdAt: 2000,
        ),
      );
      final denied = _HttpHandler(_dio(403, _permissionDenial));
      final refused = _OtherHandler(_dio(422, const {'code': 'UNPROCESSABLE'}));

      final report = await (engine(denied)..registerHandler(refused)).flush();

      expect(report.blocked, 1);
      expect(report.failed, 1);
      expect((await dao.byId('e2'))!.status, OutboxStatus.syncError);
    });
  });

  test('permissionDenied rendu par le handler : retenue 5 min, même sans '
      'sonde', () async {
    permissions.set(null);
    await dao.enqueue(entry('e1'));
    final handler = _DeclaringHandler(_dio(200));

    final report = await engine(handler).flush();

    expect(report.blocked, 1);
    expect(report.retried, 0);
    final row = (await dao.byId('e1'))!;
    expect(row.attempts, 0);
    expect(row.lastError, kOutboxAwaitingPermissionReason);
    expect(row.nextAttemptAt, fixedNow + 300000);
  });

  test('isOutboxPermissionDenial : 403 sans code oui, avec code non', () {
    DioException denial(int status, Map<String, dynamic> body) => DioException(
      requestOptions: RequestOptions(),
      response: Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: body,
      ),
    );
    expect(isOutboxPermissionDenial(denial(403, _permissionDenial)), isTrue);
    expect(isOutboxPermissionDenial(denial(403, _businessDenial)), isFalse);
    expect(isOutboxPermissionDenial(denial(401, _permissionDenial)), isFalse);
  });

  group('OutboxPermissionProbe', () {
    test('hors d\'un dispatch, un 403 ne marque rien et ne lève pas', () async {
      final probe = OutboxPermissionProbe();
      await expectLater(
        _dio(403, _permissionDenial).get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(probe.denied, isFalse);
    });

    test(
      'une requête lancée hors de la zone n\'atteint pas la sonde',
      () async {
        final probe = OutboxPermissionProbe();
        final dio = _dio(403, _permissionDenial);
        // Démarrée AVANT la zone : un pull concurrent, par exemple.
        final outside = dio
            .get<dynamic>('/pull')
            .catchError(
              (Object _) => Response<dynamic>(requestOptions: RequestOptions()),
            );
        await probe.watch(() async {
          await _dio(200).get<dynamic>('/push');
        });
        await outside;
        expect(probe.denied, isFalse);
      },
    );
  });
}

class _OtherHandler extends _HttpHandler {
  _OtherHandler(super.dio) : super(access: null);

  @override
  String get aggregateType => 'OTHER';
}

class _DeclaringHandler extends _HttpHandler {
  _DeclaringHandler(super.dio);

  @override
  Future<OutboxDispatchResult> dispatch(OutboxEntry entry) async {
    calls++;
    return const OutboxDispatchResult.permissionDenied();
  }
}
