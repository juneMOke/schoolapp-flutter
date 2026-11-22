import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_api.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_cache_dao.dart';
import 'package:school_app_flutter/features/recouvrement/data/dashboard/recovery_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/rules/recovery_rule.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../../offline_full_db.dart';
import '../../fixtures/recovery_fixtures.dart';

class _MockApi extends Mock implements RecoveryDashboardApi {}

class _MockConnectivity extends Mock implements ConnectivityService {}

DioException _dio(Failure failure) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/finance-stats/recovery'),
  error: failure,
);

/// Le serveur d'abord ; la photo datée quand — et seulement quand — le réseau
/// manque ET qu'elle répond à la même question.
void main() {
  late Database db;
  late _MockApi api;
  late _MockConnectivity connectivity;
  late RecoveryDashboardRepositoryImpl repo;
  final fetchedAt = DateTime(2026, 9, 5, 14, 30);
  const question = RecoveryQuestion(feeCodes: ['TUITION']);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    repo = RecoveryDashboardRepositoryImpl(
      api: api,
      cache: RecoveryDashboardCacheDao(db),
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'E1'),
      connectivity: connectivity,
      now: () => fetchedAt,
    );
  });
  tearDown(() async => db.close());

  test(
    'les paramètres de la question partent tels que le contrat les nomme',
    () async {
      when(
        () => api.dashboard(any()),
      ).thenAnswer((_) async => recoveryDashboardJson());
      await repo.dashboard(
        'ay-1',
        const RecoveryQuestion(
          feeCodes: ['TUITION', 'BOOKS'],
          scope: RecoveryScopeKind.cycle,
          scopeId: 'g-1',
          rule: RecoveryRuleKind.atLeast,
          thresholdInCents: 15000,
        ),
        pendingWrites: 3,
      );
      verify(
        () => api.dashboard({
          'feeCodes': 'TUITION,BOOKS',
          'scope': 'SCHOOL_LEVEL_GROUP',
          'scopeId': 'g-1',
          'rule': 'AT_LEAST',
          'thresholdInCents': 15000,
          'pendingWrites': 3,
        }),
      ).called(1);
    },
  );

  test(
    '« au moins » sans montant part en règle par défaut (pas de 400)',
    () async {
      when(
        () => api.dashboard(any()),
      ).thenAnswer((_) async => recoveryDashboardJson());
      await repo.dashboard(
        'ay-1',
        const RecoveryQuestion(
          feeCodes: ['TUITION'],
          rule: RecoveryRuleKind.atLeast,
        ),
      );
      final sent =
          verify(() => api.dashboard(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(sent['rule'], 'SOME_PAYMENT');
      expect(sent.containsKey('thresholdInCents'), isFalse);
    },
  );

  test('en ligne : chiffres décodés (A2), puis photographiés', () async {
    when(
      () => api.dashboard(any()),
    ).thenAnswer((_) async => recoveryDashboardJson());
    final fresh = (await repo.dashboard(
      'ay-1',
      question,
    )).getOrElse(() => throw StateError('échec'));
    expect(fresh.cachedAt, isNull);
    expect(fresh.keyFigures.single.dueInCents, 13092000);
    expect(fresh.situations.of(StudentChargeStatus.due), 315);

    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final cached = (await repo.dashboard(
      'ay-1',
      question,
    )).getOrElse(() => throw StateError('échec'));
    expect(cached.cachedAt, fetchedAt);
    expect(cached.keyFigures, fresh.keyFigures);
    expect(await repo.lastCachedQuestion('ay-1'), question);
  });

  test('hors ligne, une AUTRE question ne se sert pas de la photo', () async {
    when(
      () => api.dashboard(any()),
    ).thenAnswer((_) async => recoveryDashboardJson());
    await repo.dashboard('ay-1', question);
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final other = await repo.dashboard(
      'ay-1',
      const RecoveryQuestion(feeCodes: ['BOOKS']),
    );
    expect(other.fold((f) => f, (_) => null), isA<NetworkFailure>());
  });

  test('la photo est scopée école : une autre école ne la voit pas', () async {
    when(
      () => api.dashboard(any()),
    ).thenAnswer((_) async => recoveryDashboardJson());
    await repo.dashboard('ay-1', question);
    final neighbour = RecoveryDashboardRepositoryImpl(
      api: api,
      cache: RecoveryDashboardCacheDao(db),
      currentUser: CurrentUserContext()..set('u-2', schoolId: 'E2'),
      connectivity: connectivity,
    );
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final result = await neighbour.dashboard('ay-1', question);
    expect(result.isLeft(), isTrue);
  });

  test('un 403 ne se replie jamais sur la photo', () async {
    when(
      () => api.dashboard(any()),
    ).thenAnswer((_) async => recoveryDashboardJson());
    await repo.dashboard('ay-1', question);
    when(
      () => api.dashboard(any()),
    ).thenThrow(_dio(const UnauthorizedFailure('403')));
    final result = await repo.dashboard('ay-1', question);
    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });

  test(
    'une coupure en vol se replie sur la photo de la même question',
    () async {
      when(
        () => api.dashboard(any()),
      ).thenAnswer((_) async => recoveryDashboardJson());
      await repo.dashboard('ay-1', question);
      when(
        () => api.dashboard(any()),
      ).thenThrow(_dio(const NetworkFailure('coupure')));
      final result = await repo.dashboard('ay-1', question);
      expect(result.getOrElse(() => throw StateError('')).cachedAt, fetchedAt);
    },
  );

  test(
    'une réponse illisible est une erreur, pas un tableau de bord à zéro',
    () async {
      when(() => api.dashboard(any())).thenAnswer((_) async => {'oops': 1});
      final result = await repo.dashboard('ay-1', question);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    },
  );

  test('liste : seule la première page sans recherche se garde', () async {
    when(
      () => api.students(any()),
    ).thenAnswer((_) async => recoveryStudentsJson());
    const first = RecoveryStudentsQuery(question: question);
    await repo.students('ay-1', first);
    await repo.students('ay-1', first.copyWith(page: 1, search: 'kab'));
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final cached = await repo.students('ay-1', first);
    expect(cached.getOrElse(() => throw StateError('')).counts.toChase, 315);
    final searched = await repo.students('ay-1', first.copyWith(search: 'kab'));
    expect(searched.isLeft(), isTrue);
    final otherTab = await repo.students(
      'ay-1',
      first.copyWith(tab: RecoveryTab.all),
    );
    expect(otherTab.isLeft(), isTrue);
  });

  test("l'export ne porte ni recherche ni page (Q5)", () async {
    when(
      () => api.students(any()),
    ).thenAnswer((_) async => recoveryStudentsJson());
    final q = const RecoveryStudentsQuery(
      question: question,
      search: 'kab',
      page: 3,
    ).toExportParameters();
    expect(q.containsKey('q'), isFalse);
    expect(q.containsKey('page'), isFalse);
    expect(q['tab'], 'TO_CHASE');
  });
}
