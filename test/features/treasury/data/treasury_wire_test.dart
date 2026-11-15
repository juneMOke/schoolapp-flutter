import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';

/// Un `RegisterConfig` tel que le contrat (PR back #222) le décrit.
const _config = {
  'register': {
    'id': 'reg-cdf',
    'name': 'Caisse CDF',
    'currency': 'CDF',
    'inServiceAt': '2026-10-20T06:00:00Z',
    'inServiceOn': '2026-10-20',
    'openingAmountInCents': 75000000,
  },
  'balanceInCents': 344500000,
  'todayClosure': {
    'id': 'clo-1',
    'registerId': 'reg-cdf',
    'currency': 'CDF',
    'cashDay': '2026-10-22',
    'closedAt': '2026-10-22T16:45:00Z',
    'closedByName': 'Ilunga Céline',
    'closedByRole': 'ACCOUNTANT',
    'matches': false,
    'expectedInCents': 345000000,
    'declaredInCents': 344500000,
    'gapInCents': -500000,
    'justification': 'Erreur de rendu de monnaie',
    'reopenedAt': null,
  },
  'adjustmentsCount': 2,
  'last8Days': [
    {'day': '2026-10-21', 'balanceInCents': 332626900, 'closed': true},
  ],
};

void main() {
  group('lecture', () {
    test('une caisse configurée, montants en centimes, CDF compris', () {
      final config = TreasuryWire.registerConfigsFromJson([_config]).single;
      expect(config.register.currency, TreasuryCurrency.cdf);
      expect(config.register.openingAmountInCents, 75000000);
      expect(config.register.inServiceOn, DateTime(2026, 10, 20));
      expect(config.register.inServiceAt, DateTime.utc(2026, 10, 20, 6));
      expect(config.balanceInCents, 344500000);
      expect(config.adjustmentsCount, 2);
      expect(config.closedToday, isTrue);
      expect(config.todayClosure!.gapInCents, -500000);
      expect(config.last8Days.single.closed, isTrue);
    });

    test('une clôture rouverte ne verrouille plus la caisse', () {
      final reopened = {
        ..._config,
        'todayClosure': {
          ...(_config['todayClosure']! as Map<String, Object?>),
          'reopenedAt': '2026-10-22T17:00:00Z',
        },
      };
      final config = TreasuryWire.registerConfigFromJson(reopened);
      expect(config.closedToday, isFalse);
    });

    test(
      'une devise inconnue est illisible, jamais prise pour l une des deux',
      () {
        final bad = {
          ..._config,
          'register': {
            ...(_config['register']! as Map<String, Object?>),
            'currency': 'EUR',
          },
        };
        expect(
          () => TreasuryWire.registerConfigFromJson(bad),
          throwsFormatException,
        );
      },
    );

    test('un montant manquant est illisible, jamais 0', () {
      final bad = Map<String, Object?>.of(_config)..remove('balanceInCents');
      expect(
        () => TreasuryWire.registerConfigFromJson(bad),
        throwsFormatException,
      );
    });
  });

  group('écriture', () {
    test(
      'un nom vide n est pas envoyé : le serveur pose le nom automatique',
      () {
        expect(
          TreasuryWire.createRegisterToJson(
            currency: TreasuryCurrency.usd,
            name: '   ',
            openingAmountInCents: 0,
          ),
          {'currency': 'USD', 'openingAmountInCents': 0},
        );
      },
    );

    test('l ajustement porte sa clé de rejeu et le montant montré', () {
      expect(
        TreasuryWire.adjustmentToJson(
          id: 'uuid-1',
          shownExpectedInCents: 482000,
          newAmountInCents: 490000,
          reason: '  Recomptage ',
        ),
        {
          'id': 'uuid-1',
          'shownExpectedInCents': 482000,
          'newAmountInCents': 490000,
          'reason': 'Recomptage',
        },
      );
    });
  });

  group('guardTreasury — le refus métier survit au 409', () {
    DioException refusedWith(int status, Map<String, Object?> body) =>
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: status,
            data: body,
          ),
          // Ce que l'intercepteur range pour tout 409 : un conflit muet.
          error: const ConflictFailure('Conflict — stale version'),
        );

    test('EXPECTED_CHANGED garde son attendu serveur', () async {
      final result = await guardTreasury<int>(
        () => Future.error(
          refusedWith(409, {
            'detailCode': 'EXPECTED_CHANGED',
            'details': {
              'shownExpectedInCents': 482000,
              'expectedInCents': 500000,
            },
          }),
        ),
      );
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<TreasuryRefusalFailure>());
      final refusal = failure! as TreasuryRefusalFailure;
      expect(refusal.refusal, TreasuryRefusal.expectedChanged);
      expect(refusal.serverExpectedInCents, 500000);
    });

    test('un 409 sans code connu reste le conflit de l intercepteur', () async {
      final result = await guardTreasury<int>(
        () => Future.error(refusedWith(409, {'detailCode': 'SOMETHING_ELSE'})),
      );
      expect(result.fold((f) => f, (_) => null), isA<ConflictFailure>());
    });

    test('une réponse illisible devient une panne serveur', () async {
      final result = await guardTreasury<int>(
        () => Future.error(const FormatException('Liste attendue')),
      );
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
