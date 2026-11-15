import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/online/report_signatories_api.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/report_signatories_repository_impl.dart';
import 'package:school_app_flutter/features/treasury/data/wire/report_signatories_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';

class _MockApi extends Mock implements ReportSignatoriesApi {}

const _defaultsBody = {
  'signatories': <Object>[],
  'updatedAt': null,
  'updatedByName': null,
  'defaults': true,
  'defaultSignatories': [
    {
      'rank': 2,
      'caption': 'VÉRIFIÉ PAR',
      'name': 'MWAMBA Paul',
      'function': 'Préfet des études',
      'filledByCloser': false,
    },
    {
      'rank': 1,
      'caption': 'ÉTABLI PAR',
      'name': null,
      'function': 'Caissière',
      'filledByCloser': true,
    },
  ],
};

const _designatedBody = {
  'signatories': [
    {
      'rank': 1,
      'caption': 'ÉTABLI PAR',
      'name': 'KABONGO Marie',
      'function': 'Caissière',
      'filledByCloser': true,
    },
  ],
  'updatedAt': '2026-11-15T16:00:00.123456Z',
  'updatedByName': 'Jean MUKENDI',
  'defaults': false,
  'defaultSignatories': <Object>[],
};

void main() {
  group('ReportSignatoriesWire', () {
    test('rien de désigné : les défauts, rangés par rang', () {
      final s = ReportSignatoriesWire.fromJson(_defaultsBody);
      expect(s.defaults, isTrue);
      expect(s.signatories, isEmpty);
      expect(s.updatedAtWire, isNull);
      expect(s.printed.map((x) => x.rank), [1, 2]);
      expect(s.printed.first.name, isNull);
      expect(s.printed.first.filledByCloser, isTrue);
    });

    test('l instant revient tel que reçu, microsecondes comprises', () {
      final s = ReportSignatoriesWire.fromJson(_designatedBody);
      expect(s.updatedAtWire, '2026-11-15T16:00:00.123456Z');
      expect(s.updatedAt, DateTime.utc(2026, 11, 15, 16, 0, 0, 123, 456));
      expect(s.printed.single.name, 'KABONGO Marie');
      expect(
        ReportSignatoriesWire.putBody(
          expectedUpdatedAt: s.updatedAtWire,
          signatories: s.signatories,
        ),
        {
          'expectedUpdatedAt': '2026-11-15T16:00:00.123456Z',
          'signatories': [
            {
              'rank': 1,
              'caption': 'ÉTABLI PAR',
              'name': 'KABONGO Marie',
              'function': 'Caissière',
              'filledByCloser': true,
            },
          ],
        },
      );
    });

    test('un signataire sans fonction rend la liste illisible', () {
      expect(
        () => ReportSignatoriesWire.fromJson({
          'defaults': false,
          'signatories': [
            {'rank': 1, 'caption': 'ÉTABLI PAR'},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('ReportSignatoriesRepositoryImpl', () {
    late _MockApi api;
    late ReportSignatoriesRepositoryImpl repo;

    setUp(() {
      api = _MockApi();
      repo = ReportSignatoriesRepositoryImpl(api);
    });

    DioException refused(Map<String, Object?> body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: 409,
        data: body,
      ),
      error: const ConflictFailure('Conflict — stale version'),
    );

    test('SIGNATORIES_CHANGED rend la liste actuelle', () async {
      when(
        () => api.replace(
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
          signatories: any(named: 'signatories'),
        ),
      ).thenAnswer(
        (_) => Future.error(
          refused({
            'detailCode': 'SIGNATORIES_CHANGED',
            'details': _designatedBody,
          }),
        ),
      );
      final result = await repo.replace(
        expectedUpdatedAt: null,
        signatories: const [],
      );
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<SignatoriesChangedFailure>());
      final current = (failure! as SignatoriesChangedFailure).current;
      expect(current.updatedByName, 'Jean MUKENDI');
      expect(current.printed.single.name, 'KABONGO Marie');
    });

    test('SIGNATORIES_CHANGED sans liste lisible reste un refus', () async {
      when(
        () => api.replace(
          expectedUpdatedAt: any(named: 'expectedUpdatedAt'),
          signatories: any(named: 'signatories'),
        ),
      ).thenAnswer(
        (_) => Future.error(refused({'detailCode': 'SIGNATORIES_CHANGED'})),
      );
      final result = await repo.replace(
        expectedUpdatedAt: null,
        signatories: const [],
      );
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isNot(isA<SignatoriesChangedFailure>()));
      expect(
        (failure! as TreasuryRefusalFailure).refusal,
        TreasuryRefusal.signatoriesChanged,
      );
    });
  });
}
