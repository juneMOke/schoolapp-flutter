import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_permission_guard.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/auth/data/interceptors/auth_refresh_interceptor.dart';
import 'package:school_app_flutter/features/auth/data/services/token_refresher.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'offline_test_db.dart';

class _MockConnectivity extends Mock implements Connectivity {}

class _MockRefresher extends Mock implements TokenRefresher {}

/// Répond par une file de statuts, après un passage par l'event loop (comme un
/// vrai socket) : la zone doit survivre à l'asynchronisme.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.replies);

  final List<(int, Object?)> replies;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(Duration.zero);
    final (status, body) = replies[calls < replies.length ? calls : 0];
    calls++;
    final isJson = body is Map;
    return ResponseBody.fromString(
      body == null ? '' : (isJson ? jsonEncode(body) : body as String),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[
          isJson ? 'application/json' : 'text/html',
        ],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(int status, [Object? body]) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = _StubAdapter([(status, body)])
      ..interceptors.add(OutboxPermissionProbeInterceptor());

const Map<String, dynamic> _permissionDenial = {
  'code': 'FORBIDDEN',
  'message': 'Accès refusé.',
};

const Map<String, dynamic> _namedPermissionDenial = {
  'code': 'FORBIDDEN',
  'detailCode': 'MONTH_CLOSURE_FORBIDDEN',
  'message': 'Clore le mois du pointage demande hr.attendance.manage.',
};

const Map<String, dynamic> _businessDenial = {
  'code': 'FORBIDDEN',
  'detailCode': 'SOME_BUSINESS_REFUSAL',
  'message': 'Refus métier.',
};

/// Handler qui pousse par un vrai Dio et classe tout 4xx en TERMINAL, comme
/// la plupart des handlers du dépôt classaient le 403.
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
      await dio.post<dynamic>(
        '/sync/expenses/x/decision',
        options: Options(extra: {'requiresAuth': true}),
      );
      return const OutboxDispatchResult.acked();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      return status >= 400 && status < 500
          ? OutboxDispatchResult.failed('HTTP_$status')
          : OutboxDispatchResult.retry('HTTP_$status');
    }
  }
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

void main() {
  late Database db;
  late OutboxDao dao;
  late _MockConnectivity connectivity;
  late CurrentPermissions permissions;
  late CurrentUserContext user;

  const int fixedNow = 100000;

  OutboxEntry entry(
    String id, {
    String type = 'EXPENSE_GESTURE',
    String? author = 'u-1',
    int createdAt = 1000,
  }) => OutboxEntry(
    id: id,
    aggregateType: type,
    aggregateId: 'agg-$id',
    operation: OutboxOperation.create,
    payload: jsonEncode({'authorId': ?author}),
    createdAt: createdAt,
  );

  SyncEngine engine(OutboxSyncHandler handler) => SyncEngine(
    outbox: dao,
    connectivity: ConnectivityService(connectivity),
    permissions: permissions,
    currentUser: user,
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
    user = CurrentUserContext()..set('u-1', schoolId: 's-1');
  });

  tearDown(() async => db.close());

  group('pré-garde', () {
    test('droits connus sans le droit exigé : retenue 5 min SANS appel '
        'réseau, sans tentative consommée', () async {
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
      // Long : un délai court ferait reprendre les mêmes entrées à chaque lot.
      expect(row.nextAttemptAt, fixedNow + 300000);
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

    test('le retour du droit réveille l\'entrée retenue sans attendre son '
        'délai', () async {
      permissions.set([Perm.expenseWrite.wire]);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(200));
      final e = engine(handler);
      await e.flush();
      expect((await dao.byId('e1'))!.nextAttemptAt, fixedNow + 300000);

      permissions.set([Perm.expenseDecide.wire]);
      await Future<void>.delayed(Duration.zero);

      expect((await dao.byId('e1'))!.nextAttemptAt, fixedNow);
      final report = await e.flush();
      expect(report.acked, 1);
    });
  });

  group('sonde : 403 reçu avant que la tablette ne connaisse le retrait', () {
    setUp(() => permissions.set([Perm.expenseDecide.wire]));

    test(
      '403 FORBIDDEN sans detailCode : retenue 5 min au lieu du SYNC_ERROR',
      () async {
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

    test('403 d\'un contrôle de droit nommé (MONTH_CLOSURE_FORBIDDEN) : '
        'retenu aussi', () async {
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(403, _namedPermissionDenial));

      final report = await engine(handler).flush();

      expect(report.blocked, 1);
      expect(report.failed, 0);
    });

    test('403 AVEC un code métier : reste terminal', () async {
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(403, _businessDenial));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
      expect((await dao.byId('e1'))!.status, OutboxStatus.syncError);
    });

    test('403 d\'un proxy (page HTML, pas de corps FORBIDDEN) : pas un refus '
        'de droit', () async {
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(403, '<html>Forbidden</html>'));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
      expect(report.blocked, 0);
    });

    test('entrée SANS auteur : le 403 peut être le refus d\'auteur, elle garde '
        'son sort terminal au lieu d\'être retenue pour toujours', () async {
      await dao.enqueue(entry('e1', author: null));
      final handler = _HttpHandler(_dio(403, _permissionDenial));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
      expect(report.blocked, 0);
    });

    test('porteur sans uid : même règle, pas de retenue', () async {
      user.set(null);
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(403, _permissionDenial));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
    });

    test('un autre 4xx (422) reste terminal', () async {
      await dao.enqueue(entry('e1'));
      final handler = _HttpHandler(_dio(422, const {'code': 'UNPROCESSABLE'}));

      final report = await engine(handler).flush();

      expect(report.failed, 1);
    });

    test('la sonde ne déborde pas d\'une entrée sur la suivante', () async {
      await dao.enqueue(entry('e1'));
      await dao.enqueue(entry('e2', type: 'OTHER', createdAt: 2000));
      final denied = _HttpHandler(_dio(403, _permissionDenial));
      final refused = _OtherHandler(_dio(422, const {'code': 'UNPROCESSABLE'}));

      final report = await (engine(denied)..registerHandler(refused)).flush();

      expect(report.blocked, 1);
      expect(report.failed, 1);
      expect((await dao.byId('e2'))!.status, OutboxStatus.syncError);
    });

    test('vraie chaîne : 401, refresh, rejeu qui prend le 403 — la sonde '
        'posée après AuthRefreshInterceptor le voit', () async {
      final refresher = _MockRefresher();
      when(refresher.refresh).thenAnswer((_) async => 'new-token');
      final retryDio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _StubAdapter([(403, _permissionDenial)]);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = _StubAdapter([
          (401, const {'code': 'X'}),
        ])
        ..interceptors.addAll([
          AuthRefreshInterceptor(refresher: refresher, retryDio: retryDio),
          OutboxPermissionProbeInterceptor(),
        ]);
      await dao.enqueue(entry('e1'));

      final report = await engine(_HttpHandler(dio)).flush();

      verify(refresher.refresh).called(1);
      expect(report.blocked, 1);
      expect(report.failed, 0);
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

  group('isOutboxPermissionDenial', () {
    DioException denial(int status, Object? body) => DioException(
      requestOptions: RequestOptions(),
      response: Response<dynamic>(
        requestOptions: RequestOptions(),
        statusCode: status,
        data: body,
      ),
    );

    test('hors dispatch : la règle ne lit que la réponse', () {
      expect(isOutboxPermissionDenial(denial(403, _permissionDenial)), isTrue);
      expect(
        isOutboxPermissionDenial(denial(403, _namedPermissionDenial)),
        isTrue,
      );
      expect(isOutboxPermissionDenial(denial(403, _businessDenial)), isFalse);
      expect(isOutboxPermissionDenial(denial(403, null)), isFalse);
      expect(isOutboxPermissionDenial(denial(401, _permissionDenial)), isFalse);
    });

    test('dans le dispatch d\'une entrée non attribuée : toujours faux', () {
      final probe = OutboxPermissionProbe(attributed: false);
      return probe.watch(() async {
        expect(
          isOutboxPermissionDenial(denial(403, _permissionDenial)),
          isFalse,
        );
      });
    });
  });

  group('OutboxPermissionProbe', () {
    test('une requête lancée hors de la zone n\'atteint pas la sonde, même '
        'si elle se termine pendant le dispatch', () async {
      final probe = OutboxPermissionProbe();
      // Démarrée AVANT la zone, terminée pendant : un pull concurrent.
      final outside = _dio(
        403,
        _permissionDenial,
      ).get<dynamic>('/pull').then<Object?>((r) => r, onError: (Object e) => e);
      await probe.watch(() async {
        await _dio(200).get<dynamic>('/push');
        await outside;
      });
      expect(probe.denied, isFalse);
    });

    test('une requête de la zone l\'atteint après plusieurs await', () async {
      final probe = OutboxPermissionProbe();
      await probe.watch(() async {
        await Future<void>.delayed(Duration.zero);
        await _dio(403, _permissionDenial)
            .get<dynamic>('/push')
            .then<Object?>((r) => r, onError: (Object e) => e);
      });
      expect(probe.denied, isTrue);
    });
  });

  group('hasOlderPending et entrées retenues faute de droit', () {
    Future<void> holdForPermission(String id) => dao.defer(
      id,
      nextAttemptAt: fixedNow + 300000,
      reason: kOutboxAwaitingPermissionReason,
    );

    Future<bool> mineWaits() => dao.hasOlderPending(
      entryId: 'mine',
      aggregateId: null,
      types: const {'EXPENSE_GESTURE'},
    );

    test('une entrée retenue d\'un AUTRE auteur ne retient pas', () async {
      await dao.enqueue(entry('old', author: 'director'));
      await holdForPermission('old');
      await dao.enqueue(entry('mine', author: 'bursar', createdAt: 2000));

      expect(await mineWaits(), isFalse);
    });

    test('une entrée retenue du MÊME auteur retient toujours', () async {
      await dao.enqueue(entry('old', author: 'director'));
      await holdForPermission('old');
      await dao.enqueue(entry('mine', author: 'director', createdAt: 2000));

      expect(await mineWaits(), isTrue);
    });

    test(
      'une entrée simplement en attente retient, quel que soit l\'auteur',
      () async {
        await dao.enqueue(entry('old', author: 'director'));
        await dao.enqueue(entry('mine', author: 'bursar', createdAt: 2000));

        expect(await mineWaits(), isTrue);
      },
    );

    test('reportée comme écriture d\'un autre compte, une entrée retenue '
        'faute de droit garde sa marque', () async {
      permissions.set([Perm.expenseDecide.wire]);
      await dao.enqueue(entry('old', author: 'director'));
      await holdForPermission('old');
      await db.update(OutboxDao.table, {'next_attempt_at': 0});
      user.set('bursar', schoolId: 's-1');

      await engine(_HttpHandler(_dio(200))).flush();

      expect(
        (await dao.byId('old'))!.lastError,
        kOutboxAwaitingPermissionReason,
      );
    });
  });

  group('câblage', () {
    // La pré-garde et la sonde sont optionnelles et permissives dans le moteur
    // et dans Dio : un câblage oublié se tairait sans faire rougir un test de
    // comportement. On lit donc la DI elle-même.
    test('le moteur reçoit les droits du porteur', () {
      final source = File(
        'lib/core/di/offline_injection.dart',
      ).readAsStringSync();
      final engine = source.substring(source.indexOf('SyncEngine('));
      expect(
        engine.substring(0, engine.indexOf('scope:')),
        contains('permissions: getIt<CurrentPermissions>()'),
      );
    });

    test(
      'la sonde est posée APRÈS le refresh et AVANT le mapping d\'erreurs',
      () {
        final source = File('lib/core/di/injection.dart').readAsStringSync();
        final refresh = source.indexOf('AuthRefreshInterceptor(refresher:');
        final probe = source.indexOf('OutboxPermissionProbeInterceptor()');
        final mapping = source.indexOf('InterceptorsWrapper(', refresh);
        expect(refresh, greaterThan(0));
        expect(probe, greaterThan(refresh));
        expect(probe, lessThan(mapping));
      },
    );
  });
}
