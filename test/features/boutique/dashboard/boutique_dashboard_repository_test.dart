import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_api.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_cache_dao.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_beneficiaries_page_model.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/models/boutique_stats_model.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_dashboard_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';

class _MockApi extends Mock implements BoutiqueDashboardApi {}

class _MockConnectivity extends Mock implements ConnectivityService {}

BoutiqueStatsModel _stats({int saleCount = 4}) => BoutiqueStatsModel.fromJson({
  'from': '2026-10-15',
  'to': '2026-10-21',
  'granularity': 'DAY',
  'saleCount': saleCount,
  'articleCount': 6,
});

BoutiqueBeneficiariesPageModel _page() =>
    BoutiqueBeneficiariesPageModel.fromJson({
      'totalElements': 1,
      'page': 0,
      'size': 50,
      'items': [
        {
          'studentId': 's-1',
          'fullName': 'KABONGO Daniel',
          'classId': 'c-6a',
          'classLabel': '6e A',
          'lastPurchaseAt': '2026-10-21T09:42:00Z',
        },
      ],
    });

DioException _dio(Failure failure) => DioException(
  requestOptions: RequestOptions(path: '/api/v1/boutique/stats'),
  error: failure,
);

/// Le serveur d'abord ; la photo datée quand — et seulement quand — le réseau
/// manque.
void main() {
  late Database db;
  late _MockApi api;
  late _MockConnectivity connectivity;
  late BoutiqueDashboardRepositoryImpl repo;
  final window = DashboardWindow(
    from: DateTime(2026, 10, 15),
    to: DateTime(2026, 10, 21),
  );
  final fetchedAt = DateTime(2026, 10, 21, 14, 30);

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    repo = BoutiqueDashboardRepositoryImpl(
      api: api,
      cache: BoutiqueDashboardCacheDao(db),
      currentUser: CurrentUserContext()..set('u-1', schoolId: 'E1'),
      connectivity: connectivity,
      requiredAuth: const {'requiresAuth': true},
      now: () => fetchedAt,
    );
  });
  tearDown(() async => db.close());

  void stubStats(Future<BoutiqueStatsModel> Function() answer) => when(
    () => api.getStats(any(), any(), any(), any()),
  ).thenAnswer((_) => answer());

  test('la fenêtre part en jours `YYYY-MM-DD`, bornes incluses', () async {
    stubStats(() async => _stats());
    await repo.stats(academicYearId: 'ay-1', window: window);
    verify(
      () => api.getStats(any(), '2026-10-15', '2026-10-21', 'ay-1'),
    ).called(1);
  });

  test('en ligne : la réponse est fraîche, et photographiée', () async {
    stubStats(() async => _stats(saleCount: 9));
    final fresh = (await repo.stats(
      academicYearId: 'ay-1',
      window: window,
    )).getOrElse(() => throw StateError('échec'));
    expect(fresh.isFromCache, isFalse);

    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final cached = (await repo.stats(
      academicYearId: 'ay-1',
      window: window,
    )).getOrElse(() => throw StateError('échec'));
    expect(cached.stats.saleCount, 9);
    expect(cached.cachedAt, fetchedAt);
  });

  test('hors ligne sans photo : l\'erreur réseau, honnête', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final result = await repo.stats(academicYearId: 'ay-1', window: window);
    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    verifyNever(() => api.getStats(any(), any(), any(), any()));
  });

  test('une coupure en vol se replie sur la photo', () async {
    stubStats(() async => _stats(saleCount: 3));
    await repo.stats(academicYearId: 'ay-1', window: window);
    stubStats(() async => throw _dio(const NetworkFailure('coupure')));

    final result = await repo.stats(academicYearId: 'ay-1', window: window);
    expect(
      result.getOrElse(() => throw StateError('échec')).isFromCache,
      isTrue,
    );
  });

  test('un 403 ne se masque JAMAIS derrière la photo', () async {
    stubStats(() async => _stats());
    await repo.stats(academicYearId: 'ay-1', window: window);
    stubStats(() async => throw _dio(const UnauthorizedFailure()));

    final result = await repo.stats(academicYearId: 'ay-1', window: window);
    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });

  test('la photo est scopée école : la voisine ne la voit pas', () async {
    stubStats(() async => _stats());
    await repo.stats(academicYearId: 'ay-1', window: window);

    final other = BoutiqueDashboardRepositoryImpl(
      api: api,
      cache: BoutiqueDashboardCacheDao(db),
      currentUser: CurrentUserContext()..set('u-2', schoolId: 'E2'),
      connectivity: connectivity,
      requiredAuth: const {},
    );
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final result = await other.stats(academicYearId: 'ay-1', window: window);
    expect(result.isLeft(), isTrue);
  });

  test(
    'une réponse illisible est une erreur serveur, pas un écran vide',
    () async {
      stubStats(() async => throw const FormatException('x'));
      final result = await repo.stats(academicYearId: 'ay-1', window: window);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    },
  );

  group('bénéficiaires', () {
    BeneficiariesQuery query({String? articleId, String? search}) =>
        BeneficiariesQuery(
          academicYearId: 'ay-1',
          window: window,
          articleId: articleId,
          search: search,
        );

    void stubPage() => when(
      () => api.getBeneficiaries(
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async => _page());

    test('une recherche vide ne part pas en `q=`', () async {
      stubPage();
      await repo.beneficiaries(query(search: '   '));
      verify(
        () => api.getBeneficiaries(
          any(),
          any(),
          any(),
          any(),
          null,
          null,
          null,
          0,
          50,
        ),
      ).called(1);
    });

    test(
      'hors ligne : la recherche par nom se rejoue sur la page gardée',
      () async {
        stubPage();
        await repo.beneficiaries(query());
        when(() => connectivity.isOnline()).thenAnswer((_) async => false);

        final page = (await repo.beneficiaries(
          query(search: 'kabongo'),
        )).getOrElse(() => throw StateError('échec'));
        expect(page.items.single.studentId, 's-1');
        expect(page.cachedAt, fetchedAt);
      },
    );

    test('une page filtrée ne remplace pas la photo sans filtre', () async {
      stubPage();
      await repo.beneficiaries(query(articleId: 'a-1'));
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      expect((await repo.beneficiaries(query())).isLeft(), isTrue);
    });

    test('hors ligne, le filtre par article reste une erreur réseau', () async {
      stubPage();
      await repo.beneficiaries(query());
      when(() => connectivity.isOnline()).thenAnswer((_) async => false);
      final result = await repo.beneficiaries(query(articleId: 'a-1'));
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });
  });
}
