import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/data/datasources/finance_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/models/fee_tariff_model.dart';
import 'package:school_app_flutter/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/finance_till_response_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';

class MockFinanceRemoteDataSource extends Mock
    implements FinanceRemoteDataSource {}

const tRequiredAuth = <String, dynamic>{'requiresAuth': true};

const tTariffModel = FeeTariffModel(
  id: 'tariff-1',
  label: 'Tuition',
  amount: 150000,
  currency: 'XOF',
  levelId: 'level-1',
);

void main() {
  late MockFinanceRemoteDataSource mockRemoteDataSource;
  late FinanceRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockFinanceRemoteDataSource();
    repository = FinanceRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      requiredAuth: tRequiredAuth,
    );
  });

  group('getFeeTariffsByLevel', () {
    test('returns Right(List<FeeTariff>) when datasource succeeds', () async {
      when(
        () => mockRemoteDataSource.listTariffsByLevel(tRequiredAuth, 'level-1'),
      ).thenAnswer((_) async => const [tTariffModel]);

      final result = await repository.getFeeTariffsByLevel(levelId: 'level-1');

      result.fold(
        (_) => fail('Expected Right but got Left'),
        (tariffs) => expect(tariffs.first.id, 'tariff-1'),
      );
    });
  });

  group('getTillReceiptsReport', () {
    setUpAll(() => registerFallbackValue(Options()));

    HttpResponse<Uint8List> pdfResponse() {
      final bytes = Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46, 0x2D]);
      return HttpResponse<Uint8List>(
        bytes,
        Response<Uint8List>(
          requestOptions: RequestOptions(path: '/receipts.pdf'),
          statusCode: 200,
          headers: Headers.fromMap(<String, List<String>>{
            Headers.contentTypeHeader: <String>['application/pdf'],
            'content-disposition': <String>[
              'attachment; filename="encaissements-USD-2026-05-15_2026-05-15.pdf"',
            ],
          }),
          data: bytes,
        ),
      );
    }

    void stub(HttpResponse<Uint8List> response) {
      when(
        () => mockRemoteDataSource.getTillReceiptsReport(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async => response);
    }

    test(
      'la fenêtre part telle quelle, et AUCUNE devise ne la cadre',
      () async {
        stub(pdfResponse());

        final result = await repository.getTillReceiptsReport(
          window: TillWindow.custom(
            from: DateTime(2026, 5, 1),
            to: DateTime(2026, 5, 15),
          ),
        );

        expect(result.isRight(), isTrue);
        // Le document rend les deux unités, comme la table : le cadrer sur une
        // caisse produirait une pièce que personne n'a demandée.
        verify(
          () => mockRemoteDataSource.getTillReceiptsReport(
            tRequiredAuth,
            'custom',
            '2026-05-01',
            '2026-05-15',
            any(),
          ),
        ).called(1);
      },
    );

    test('le délai de réception est ALLONGÉ pour ce document', () async {
      stub(pdfResponse());

      await repository.getTillReceiptsReport();

      // ⚠️ Le client vaut 12 s, calibrés sur des réponses de guichet. Composer
      // ce document prend plusieurs secondes : sans allongement, un rapport
      // mensuel expirerait côté client pendant que le serveur le produit
      // encore, et l'appel suivant tomberait sur le 429 d'un rendu qu'on
      // croirait abandonné.
      final options =
          verify(
                () => mockRemoteDataSource.getTillReceiptsReport(
                  any(),
                  any(),
                  any(),
                  any(),
                  captureAny(),
                ),
              ).captured.single
              as Options;
      expect(options.receiveTimeout, const Duration(seconds: 60));
    });

    test('le nom annoncé par le serveur est celui du document rendu', () async {
      stub(pdfResponse());

      final result = await repository.getTillReceiptsReport();

      expect(
        result.getOrElse(() => throw StateError('attendu')).fileName,
        'encaissements-USD-2026-05-15_2026-05-15.pdf',
      );
    });

    test('le message du serveur survit au refus de plafond', () async {
      when(
        () => mockRemoteDataSource.getTillReceiptsReport(
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/receipts.pdf'),
          response: Response<List<int>>(
            requestOptions: RequestOptions(path: '/receipts.pdf'),
            statusCode: 400,
            data: utf8.encode(
              '{"status":400,"code":"BUSINESS_RULE",'
              '"message":"Le rapport dépasse 5 000 lignes (7 213)."}',
            ),
          ),
          error: const ValidationFailure('Invalid request data'),
        ),
      );

      final result = await repository.getTillReceiptsReport();

      // Sans ce message, l'écran ne pourrait dire que « resserrez la période »,
      // sans dire de combien — l'intercepteur global, lui, l'écrase par une
      // constante.
      result.fold(
        (failure) => expect(failure.message, contains('7 213')),
        (_) => fail('un refus était attendu'),
      );
    });
  });

  group('getFinanceTill', () {
    final tTillModel = FinanceTillResponseModel.fromJson(
      jsonDecode(_tillJson) as Map<String, dynamic>,
    );

    test('rend Right(FinanceTill) et transmet la période demandée', () async {
      when(
        () => mockRemoteDataSource.getFinanceTill(
          tRequiredAuth,
          'month',
          null,
          null,
        ),
      ).thenAnswer((_) async => tTillModel);

      final result = await repository.getFinanceTill(
        window: const TillWindow.month(),
      );

      result.fold((_) => fail('Expected Right but got Left'), (till) {
        expect(till.timeZone, 'Africa/Kinshasa');
        final block = till.encaisse.single;
        expect(block.summary.total, 123450);
        expect(block.summary.boutique, 23450);
        expect(block.buckets.single.key, '2026-05-15');
      });

      verify(
        () => mockRemoteDataSource.getFinanceTill(
          tRequiredAuth,
          'month',
          null,
          null,
        ),
      ).called(1);
    });

    test('le défaut est la journée — la question de la fermeture', () async {
      when(
        () => mockRemoteDataSource.getFinanceTill(
          tRequiredAuth,
          'day',
          null,
          null,
        ),
      ).thenAnswer((_) async => tTillModel);

      await repository.getFinanceTill();

      verify(
        () => mockRemoteDataSource.getFinanceTill(
          tRequiredAuth,
          'day',
          null,
          null,
        ),
      ).called(1);
    });

    test('rend Left(Failure) quand la DioException en porte une', () async {
      // Le serveur REFUSE une ancre incohérente en 400 plutôt que de l'ignorer :
      // c'est cette famille-là qui remontera le jour où le sélecteur de date
      // arrivera.
      const failure = ValidationFailure('Invalid request data');
      when(
        () => mockRemoteDataSource.getFinanceTill(
          tRequiredAuth,
          'week',
          null,
          null,
        ),
      ).thenThrow(_dioException(error: failure));

      final result = await repository.getFinanceTill(
        window: const TillWindow.week(),
      );

      expect(result, const Left<Failure, FinanceTill>(failure));
    });

    test(
      'une charge utile illisible devient une erreur, jamais un tiroir vide',
      () async {
        when(
          () => mockRemoteDataSource.getFinanceTill(
            tRequiredAuth,
            'day',
            null,
            null,
          ),
        ).thenThrow(TypeError());

        final result = await repository.getFinanceTill();

        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('un caissier a le tiroir ouvert devant lui'),
        );
      },
    );
  });
}

DioException _dioException({Object? error}) {
  return DioException(
    requestOptions: RequestOptions(path: '/api/v1/finance-stats'),
    error: error,
    type: DioExceptionType.unknown,
  );
}

const String _tillJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "month",
    "periodStart": "2026-05-01",
    "periodEnd": "2026-05-31",
    "generatedAt": "2026-05-23T08:00:00Z"
  },
  "timeZone": "Africa/Kinshasa",
  "encaisse": [
    {
      "currency": "USD",
      "summary": { "total": 123450, "fees": 100000, "boutique": 23450 },
      "buckets": [
        {
          "key": "2026-05-15", "total": 123450, "fees": 100000,
          "boutique": 23450, "isCurrent": true
        }
      ]
    }
  ],
  "impute": [
    {
      "currency": "USD",
      "total": 100000,
      "byFeeCode": [
        { "code": "TUITION", "label": "Minerval", "amount": 100000 }
      ]
    }
  ]
}
''';
