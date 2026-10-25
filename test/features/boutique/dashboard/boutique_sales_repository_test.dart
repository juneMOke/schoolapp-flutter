import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' hide Headers;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/boutique/data/dashboard/boutique_dashboard_api.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_sales_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';

class _MockApi extends Mock implements BoutiqueDashboardApi {}

class _MockConnectivity extends Mock implements ConnectivityService {}

/// La page telle que le back l'a confirmée le 2026-10-23 : `amounts` en
/// `[{amount, currency}]`, `payerName` et `fullName` nullables.
Map<String, dynamic> _page() => {
  'totalElements': 23,
  'page': 1,
  'size': 10,
  'classes': [
    {'id': 'c-6a', 'label': '6e A'},
  ],
  'items': [
    {
      'saleId': 's-1',
      'soldAt': '2026-10-21T09:42:00Z',
      'receiptNumber': 'RV-000472',
      'amounts': [
        {'amount': 1500, 'currency': 'USD'},
        {'amount': 90000, 'currency': 'CDF'},
      ],
      'articleCount': 3,
      'beneficiaries': [
        {
          'studentId': 'st-1',
          'fullName': 'KABONGO Daniel',
          'classId': 'c-6a',
          'classLabel': '6e A',
        },
        // Élève purgé, non placé.
        {'studentId': 'st-9', 'fullName': null},
      ],
      'payerName': 'Ndombo Lelo Willy',
    },
    {
      'saleId': 's-2',
      'soldAt': '2026-10-21T08:00:00Z',
      'receiptNumber': null,
      'amounts': [
        {'amount': 500, 'currency': 'USD'},
      ],
      'articleCount': 1,
      'beneficiaries': <Object>[],
      'payerName': null,
    },
  ],
};

void main() {
  late _MockApi api;
  late _MockConnectivity connectivity;
  late BoutiqueSalesRepositoryImpl repo;
  final window = DashboardWindow(
    from: DateTime(2026, 10, 19),
    to: DateTime(2026, 10, 21),
  );

  setUpAll(() => registerFallbackValue(Options()));

  setUp(() {
    api = _MockApi();
    connectivity = _MockConnectivity();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
    repo = BoutiqueSalesRepositoryImpl(
      api: api,
      connectivity: connectivity,
      requiredAuth: const {'requiresAuth': true},
    );
  });

  void stubSales(Future<Map<String, dynamic>> Function() answer) => when(
    () => api.getSales(any(), any(), any(), any(), any(), any(), any(), any()),
  ).thenAnswer((_) => answer());

  test(
    'la fenêtre en jours inclus, seul le critère actif, 10 par page',
    () async {
      stubSales(() async => _page());
      await repo.sales(
        SalesQuery(
          academicYearId: 'ay-1',
          window: window,
          family: ArticleFamily.uniforme,
          page: 1,
        ),
      );
      verify(
        () => api.getSales(
          any(),
          '2026-10-19',
          '2026-10-21',
          'ay-1',
          'UNIFORME',
          null,
          1,
          10,
        ),
      ).called(1);
    },
  );

  test('la page se lit, champs nullables compris', () async {
    stubSales(() async => _page());
    final page = (await repo.sales(
      SalesQuery(academicYearId: 'ay-1', window: window),
    )).getOrElse(() => throw StateError('échec'));

    expect(page.totalPages, 3);
    expect(page.classes.single.label, '6e A');
    final first = page.items.first;
    expect(first.amounts.entries, hasLength(2));
    expect(first.beneficiaries.last.fullName, isNull);
    expect(first.beneficiaries.last.classLabel, isNull);
    final anonymous = page.items.last;
    expect(anonymous.receiptNumber, isNull);
    expect(anonymous.payerName, isNull);
    expect(anonymous.beneficiaries, isEmpty);
  });

  test('hors ligne : l\'erreur réseau, sans appel ni photo', () async {
    when(() => connectivity.isOnline()).thenAnswer((_) async => false);
    final result = await repo.sales(
      SalesQuery(academicYearId: 'ay-1', window: window),
    );
    expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    verifyNever(
      () =>
          api.getSales(any(), any(), any(), any(), any(), any(), any(), any()),
    );
  });

  test('un 403 classé par l\'intercepteur remonte tel quel', () async {
    stubSales(
      () async => throw DioException(
        requestOptions: RequestOptions(path: '/api/v1/boutique/sales'),
        error: const UnauthorizedFailure(),
      ),
    );
    final result = await repo.sales(
      SalesQuery(academicYearId: 'ay-1', window: window),
    );
    expect(result.fold((f) => f, (_) => null), isA<UnauthorizedFailure>());
  });

  test('une vente illisible fait échouer la page', () async {
    stubSales(
      () async => {
        ..._page(),
        'items': [
          {'saleId': 's-1', 'soldAt': 'hier', 'amounts': <Object>[]},
        ],
      },
    );
    final result = await repo.sales(
      SalesQuery(academicYearId: 'ay-1', window: window),
    );
    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  group('rapport', () {
    HttpResponse<Uint8List> pdf(List<int> bytes, {String? type}) {
      final options = RequestOptions(path: '/api/v1/boutique/sales.pdf');
      return HttpResponse(
        Uint8List.fromList(bytes),
        Response(
          requestOptions: options,
          headers: Headers.fromMap({
            Headers.contentTypeHeader: [type ?? 'application/pdf'],
            'content-disposition': [
              'attachment; filename="ventes-boutique-2026-10-19_2026-10-21.pdf"',
            ],
          }),
        ),
      );
    }

    void stubReport(Future<HttpResponse<Uint8List>> Function() answer) => when(
      () => api.getSalesReport(any(), any(), any(), any(), any(), any(), any()),
    ).thenAnswer((_) => answer());

    test('la même question que la liste, sans page', () async {
      stubReport(() async => pdf([0x25, 0x50, 0x44, 0x46, 0x2d]));
      final useCase = GetBoutiqueSalesReportUseCase(repo);
      final report = (await useCase(
        SalesQuery(
          academicYearId: 'ay-1',
          window: window,
          classId: 'c-6a',
          page: 2,
        ),
      )).getOrElse(() => throw StateError('échec'));

      expect(report.fileName, 'ventes-boutique-2026-10-19_2026-10-21.pdf');
      final options =
          verify(
                () => api.getSalesReport(
                  any(),
                  '2026-10-19',
                  '2026-10-21',
                  'ay-1',
                  // Un `null` littéral prendrait le matcher suivant : mocktail
                  // relit chaque `null` positionnel comme un matcher.
                  any(that: isNull),
                  'c-6a',
                  captureAny(),
                ),
              ).captured.single
              as Options;
      expect(options.receiveTimeout, const Duration(seconds: 60));
    });

    test('un 200 qui n\'est pas un PDF est refusé', () async {
      stubReport(() async => pdf('<html>'.codeUnits, type: 'text/html'));
      final result = await repo.report(
        SalesQuery(academicYearId: 'ay-1', window: window),
      );
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
