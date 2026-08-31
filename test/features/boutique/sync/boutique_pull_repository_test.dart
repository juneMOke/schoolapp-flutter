import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_pull_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_pull_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';
import 'package:sqflite_common/sqlite_api.dart';

import '../../offline_full_db.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';

class _MockApi extends Mock implements BoutiqueSyncApi {}

BoutiqueSaleDeltaDto _sale(String id) => BoutiqueSaleDeltaDto(
  id: id,
  academicYearId: 'ay-1',
  payerLastName: 'Ndombo',
  amounts: MoneyBag.of(const [Money(1000, 'USD')]),
  soldAt: '2026-08-29T11:42:00Z',
  serverUpdatedAt: '2026-08-29T11:45:00Z',
);

HttpResponse<BoutiqueSalePageDto> _page({
  List<String> ids = const ['v1'],
  String? nextCursor,
  String? nextWatermark = 'WM-1',
  bool hasMore = false,
}) => HttpResponse(
  BoutiqueSalePageDto(
    items: [for (final id in ids) _sale(id)],
    page: KeysetPageEnvelope(
      nextCursor: nextCursor,
      nextWatermark: nextWatermark,
      hasMore: hasMore,
      serverTime: '2026-08-29T11:46:00Z',
    ),
  ),
  Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
);

DioException _http(int status) => DioException(
  requestOptions: RequestOptions(path: '/'),
  response: Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
  ),
);

void main() {
  late Database db;
  late _MockApi api;
  late SyncMetaDao syncMeta;

  const auth = <String, dynamic>{'requiresAuth': true};

  BoutiquePullRepositoryImpl repoWith({
    String? schoolId = 'E1',
    String? yearId = 'ay-1',
  }) => BoutiquePullRepositoryImpl(
    api: api,
    dao: BoutiqueSalePullDao(db),
    syncMetaDao: syncMeta,
    currentUser: CurrentUserContext()..set('u1', schoolId: schoolId),
    requiredAuth: auth,
    currentAcademicYearId: () async => yearId,
    now: () => 1000,
  );

  setUpAll(() => registerFallbackValue(<String, dynamic>{}));

  setUp(() async {
    db = await openFullOfflineDb();
    api = _MockApi();
    syncMeta = SyncMetaDao(db);
  });
  tearDown(() async => db.close());

  group('💀 le curseur est scopé ÉCOLE', () {
    test('la clé porte l\'école courante', () async {
      // Un curseur nu sur une tablette réaffectée ferait reprendre le second
      // établissement au point où le premier s'était arrêté : le serveur
      // répondrait « rien de neuf », et ses ventes ne descendraient JAMAIS.
      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page());

      await repoWith(schoolId: 'E1').syncSales();

      expect(await syncMeta.getCursor('boutique_sales@E1'), 'WM-1');
      expect(await syncMeta.getCursor('boutique_sales'), isNull);
    });

    test('deux écoles avancent INDÉPENDAMMENT', () async {
      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page(nextWatermark: 'WM-A'));
      await repoWith(schoolId: 'E1').syncSales();

      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page(ids: ['v2'], nextWatermark: 'WM-B'));
      await repoWith(schoolId: 'E2').syncSales();

      expect(await syncMeta.getCursor('boutique_sales@E1'), 'WM-A');
      expect(await syncMeta.getCursor('boutique_sales@E2'), 'WM-B');
    });
  });

  group('gardes du cycle', () {
    test('304 : rien de neuf, le jeton est CONSERVÉ', () async {
      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page(nextWatermark: 'WM-1'));
      await repoWith().syncSales();

      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenThrow(_http(304));
      final result = await repoWith().syncSales();

      expect(
        result.getOrElse(() => throw StateError('left')).notModified,
        isTrue,
      );
      // Le jeton ne rembobine pas : le rembobiner ferait re-tirer et
      // ré-appliquer les mêmes lignes à chaque cycle.
      expect(await syncMeta.getCursor('boutique_sales@E1'), 'WM-1');
    });

    test('400 : le curseur fautif est DISSOUS, un bootstrap suit', () async {
      // Sans ce repli, le jeton illisible serait rejoué à chaque cycle et la
      // tablette ne syncherait plus jamais — en silence.
      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page(nextWatermark: 'WM-POURRI'));
      await repoWith().syncSales();

      var call = 0;
      when(() => api.pullSales(any(), any(), any(), any())).thenAnswer((
        invocation,
      ) async {
        call++;
        if (call == 1) throw _http(400);
        // Le bootstrap part SANS curseur.
        expect(invocation.positionalArguments[1], isNull);
        return _page(ids: ['v9'], nextWatermark: 'WM-NEUF');
      });

      final result = await repoWith().syncSales();

      expect(result.isRight(), isTrue);
      expect(await syncMeta.getCursor('boutique_sales@E1'), 'WM-NEUF');
    });

    test('💀 un serveur qui n\'avance pas ne boucle PAS en silence', () async {
      // `hasMore` avec un curseur identique = serveur défaillant. Sortir en
      // silence rendrait un « updated » sur un curseur figé : chaque cycle
      // rejouerait la même page, et la tablette serait bloquée pour toujours,
      // comptée comme synchronisée.
      when(
        () => api.pullSales(any(), any(), any(), any()),
      ).thenAnswer((_) async => _page(nextCursor: null, hasMore: true));

      final result = await repoWith().syncSales();

      expect(result.isLeft(), isTrue);
    });

    test(
      'le jeton est mémorisé à CHAQUE page — reprise après coupure',
      () async {
        var call = 0;
        when(() => api.pullSales(any(), any(), any(), any())).thenAnswer((
          _,
        ) async {
          call++;
          if (call == 1) {
            return _page(ids: ['v1'], nextCursor: 'C1', hasMore: true);
          }
          throw _http(500); // coupure au milieu du cycle
        });

        final result = await repoWith().syncSales();

        expect(result.isLeft(), isTrue);
        // La première page a été appliquée ET son jeton mémorisé : le cycle
        // suivant reprend là, sans re-tirer ce qui est déjà en base.
        expect(await syncMeta.getCursor('boutique_sales@E1'), 'C1');
        expect(await db.query('boutique_sales'), hasLength(1));
      },
    );
  });

  group('préconditions', () {
    test('sans école : refus explicite, pas de curseur nu', () async {
      final result = await repoWith(schoolId: null).syncSales();

      expect(result.isLeft(), isTrue);
      verifyNever(() => api.pullSales(any(), any(), any(), any()));
    });

    test('sans année : on ne tente pas un appel voué au 400', () async {
      final result = await repoWith(yearId: null).syncSales();

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      verifyNever(() => api.pullSales(any(), any(), any(), any()));
    });
  });
}
