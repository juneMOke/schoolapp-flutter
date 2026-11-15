import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/data/repositories/treasury_online.dart';
import 'package:school_app_flutter/features/treasury/data/wire/treasury_wire.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_movement.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';

const _register = {
  'id': 'reg-usd',
  'name': 'Caisse USD',
  'currency': 'USD',
  'inServiceAt': '2026-10-01T06:00:00Z',
  'inServiceOn': '2026-10-01',
  'openingAmountInCents': 522000,
};

const _closure = {
  'id': 'clo-1',
  'registerId': 'reg-usd',
  'currency': 'USD',
  'cashDay': '2026-10-22',
  'closedAt': '2026-10-22T16:45:00.123456Z',
  'closedByName': 'Junior Moke',
  'closedByRole': 'DIRECTOR',
  'matches': true,
  'expectedInCents': 481900,
  'declaredInCents': 481900,
  'gapInCents': 0,
};

void main() {
  test('une journée : caisses, lignes en attente, clôture du promoteur', () {
    final day = TreasuryWire.dayFromJson({
      'date': '2026-10-22',
      'businessDate': '2026-10-22',
      'dayClosed': true,
      'registers': [
        {
          'register': _register,
          'openingInCents': 493300,
          'inflowsInCents': 18100,
          'inflowsCount': 7,
          'outflowsInCents': 29500,
          'outflowsCount': 3,
          'expectedInCents': 481900,
          'gapInCents': 0,
          'closingBalanceInCents': 481800,
          'closure': _closure,
          'pendingAfterClosureCount': 2,
        },
      ],
    });
    expect(day.isToday, isTrue);
    expect(day.closedCount, 1);
    // Chaque montant à sa place : une inversion passerait sinon inaperçue.
    final summary = day.registers.single;
    expect(summary.openingInCents, 493300);
    expect(summary.inflowsInCents, 18100);
    expect(summary.inflowsCount, 7);
    expect(summary.outflowsInCents, 29500);
    expect(summary.outflowsCount, 3);
    expect(summary.expectedInCents, 481900);
    expect(summary.closingBalanceInCents, 481800);
    expect(summary.pendingAfterClosureCount, 2);
    final closure = day.registers.single.closure!;
    expect(closure.closedByCashier, isFalse);
    expect(closure.closedAt, DateTime.utc(2026, 10, 22, 16, 45, 0, 123, 456));
  });

  test('une ligne arrivée après clôture garde son jour métier', () {
    final movement = TreasuryWire.movementsFromJson({
      'items': [
        {
          'id': 'mv-1',
          'registerId': 'reg-usd',
          'currency': 'USD',
          'cashDay': '2026-10-22',
          'businessDay': '2026-10-21',
          'occurredAt': '2026-10-21T16:30:00Z',
          'recordedAt': '2026-10-22T07:05:00Z',
          'direction': 'IN',
          'amountInCents': 2000,
          'source': 'FEES',
          'nature': 'ENTRY',
          'label': 'Frais de scolarité — Kabongo Mwamba · 6e A',
          'afterClosure': true,
          'alreadyCounted': null,
        },
      ],
    }).single;
    expect(movement.afterClosure, isTrue);
    expect(movement.awaitsAnswer, isTrue);
    expect(movement.businessDay, DateTime(2026, 10, 21));
    expect(movement.signedInCents, 2000);
  });

  test('une source inconnue rend la ligne illisible, jamais devinée', () {
    expect(
      () => TreasuryWire.movementFromJson({'source': 'MOBILE_MONEY'}),
      throwsFormatException,
    );
  });

  test('« Oui » n envoie que le reste montré ; « Non » envoie le déclaré', () {
    expect(
      TreasuryWire.closureToJson(
        id: 'u1',
        registerId: 'reg-usd',
        matches: true,
        shownExpectedInCents: 481900,
      ),
      {
        'id': 'u1',
        'registerId': 'reg-usd',
        'matches': true,
        'shownExpectedInCents': 481900,
      },
    );
    expect(
      TreasuryWire.closureToJson(
        id: 'u1',
        registerId: 'reg-usd',
        matches: false,
        shownExpectedInCents: 481900,
        declaredAmountInCents: 480000,
        justification: '  Billet refusé ',
      ),
      containsPair('justification', 'Billet refusé'),
    );
  });

  test('CASH_DAY_ALREADY_CLOSED rend la clôture enregistrée', () async {
    final result = await guardTreasury<int>(
      () => Future.error(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 409,
            data: {
              'detailCode': 'CASH_DAY_ALREADY_CLOSED',
              'closure': _closure,
            },
          ),
          error: const ConflictFailure(),
        ),
      ),
    );
    final failure =
        result.fold((f) => f, (_) => null)! as TreasuryRefusalFailure;
    expect(failure.refusal, TreasuryRefusal.cashDayAlreadyClosed);
    expect(failure.closure!.closedByName, 'Junior Moke');
  });

  test('une direction se lit sur le fil', () {
    expect(MovementDirection.fromWire('OUT'), MovementDirection.outflow);
  });

  test('une annulation dit quelle ligne elle défait', () {
    final movement = TreasuryWire.movementFromJson({
      'id': 'mv-2',
      'registerId': 'reg-usd',
      'currency': 'USD',
      'cashDay': '2026-10-22',
      'businessDay': '2026-10-22',
      'occurredAt': '2026-10-22T09:00:00Z',
      'direction': 'OUT',
      'amountInCents': 2000,
      'source': 'FEES',
      'nature': 'CANCELLATION',
      'label': 'Annulation — CF-RC-2627-000123',
      'afterClosure': false,
      'undoesMovementId': 'mv-1',
    });
    expect(movement.undoesMovementId, 'mv-1');
    expect(movement.direction, MovementDirection.outflow);
  });

  test('la date d un refus se lit, ou rend null sans lever', () {
    expect(TreasuryWire.dayOrNull('2026-10-22'), DateTime(2026, 10, 22));
    expect(TreasuryWire.dayOrNull('pas une date'), isNull);
    expect(TreasuryWire.dayOrNull(42), isNull);
  });

  test(
    'un 409 dont la clôture a un champ du mauvais type reste un refus lisible',
    () async {
      final result = await guardTreasury<void>(
        () => Future.error(
          DioException(
            requestOptions: RequestOptions(path: '/x'),
            response: Response(
              requestOptions: RequestOptions(path: '/x'),
              statusCode: 409,
              data: {
                'detailCode': 'CASH_DAY_ALREADY_CLOSED',
                'closure': {..._closure, 'justification': 12},
              },
            ),
          ),
        ),
      );
      final failure = result.fold((f) => f, (_) => null);
      expect(failure, isA<TreasuryRefusalFailure>());
      expect((failure! as TreasuryRefusalFailure).closure, isNull);
    },
  );
}
