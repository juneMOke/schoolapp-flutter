import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';

LocalFeeChargeAggregate _aggregate(List<FeeChargePosition> positions) =>
    LocalFeeChargeAggregate(studentId: 's1', positions: positions);

FeeChargePosition _position({
  required String currency,
  required int expected,
  int mirror = 0,
  int pending = 0,
}) => FeeChargePosition(
  currency: currency,
  expectedInCents: expected,
  paidMirrorInCents: mirror,
  paidPendingInCents: pending,
);

/// Le statut et le tri du Contrôle des frais, depuis qu'un élève peut porter
/// une position par devise sur un même frais.
void main() {
  group('position — les montants d\'une devise', () {
    test('le payé est composé, le reste borné à zéro', () {
      final p = _position(
        currency: 'USD',
        expected: 100000,
        mirror: 20000,
        pending: 40000,
      );

      expect(p.paidTotalInCents, 60000);
      expect(p.remainingInCents, 40000);
    });

    test('un trop-perçu ne rend pas le reste négatif', () {
      final p = _position(currency: 'USD', expected: 50000, mirror: 80000);

      expect(p.remainingInCents, 0);
    });
  });

  group('statut — soldé seulement si TOUTES les devises le sont', () {
    test('rien payé nulle part → dû', () {
      final a = _aggregate([
        _position(currency: 'USD', expected: 100000),
        _position(currency: 'CDF', expected: 9000000),
      ]);

      expect(a.status, StudentChargeStatus.due);
    });

    test('tout soldé partout → payé', () {
      final a = _aggregate([
        _position(currency: 'USD', expected: 100000, mirror: 100000),
        _position(currency: 'CDF', expected: 9000000, mirror: 9000000),
      ]);

      expect(a.status, StudentChargeStatus.paid);
    });

    test('soldé en dollars, débiteur en francs → partiel, PAS payé', () {
      // C'est tout l'enjeu : un élève à jour dans une unité et débiteur dans
      // l'autre n'est pas en règle sur ce frais.
      final a = _aggregate([
        _position(currency: 'USD', expected: 100000, mirror: 100000),
        _position(currency: 'CDF', expected: 9000000),
      ]);

      expect(a.status, StudentChargeStatus.partial);
    });

    test('un encaissement non remonté suffit à sortir de « dû »', () {
      // FRONT §5 : sans la part locale, un poste réglé le matin hors ligne
      // ressortirait « aucun paiement » l'après-midi.
      final a = _aggregate([
        _position(currency: 'USD', expected: 100000, pending: 10000),
      ]);

      expect(a.status, StudentChargeStatus.partial);
    });
  });

  group('sacs', () {
    test('une entrée par devise, jamais une somme', () {
      final a = _aggregate([
        _position(currency: 'USD', expected: 100000, mirror: 25000),
        _position(currency: 'CDF', expected: 9000000),
      ]);

      expect(a.expected.length, 2);
      expect(a.expected.amountIn('USD'), const Money(100000, 'USD'));
      expect(a.paidTotal.amountIn('CDF'), const Money(0, 'CDF'));
      expect(a.remaining.amountIn('USD'), const Money(75000, 'USD'));
    });

    test('le raccourci mono-devise construit une seule position', () {
      final a = LocalFeeChargeAggregate.single(
        studentId: 's1',
        currency: 'USD',
        expectedInCents: 100000,
        paidMirrorInCents: 25000,
        paidPendingInCents: 0,
      );

      expect(a.positions, hasLength(1));
      expect(a.remaining.soleEntry, const Money(75000, 'USD'));
    });
  });

  group('clé de tri', () {
    test('en mono-devise, c\'est le reste', () {
      final a = LocalFeeChargeAggregate.single(
        studentId: 's1',
        currency: 'USD',
        expectedInCents: 100000,
        paidMirrorInCents: 25000,
        paidPendingInCents: 0,
      );

      expect(a.sortableRemainingInCents, 75000);
    });

    test('en bi-devise, elle reste STABLE et reproductible', () {
      // Un reste en francs et un reste en dollars ne se comparent pas — aucun
      // taux n'entre ici. L'ordre ne prétend donc pas être juste : il prétend
      // être le même à chaque rendu, et ne jamais faire écrire un montant faux.
      final a = _aggregate([
        _position(currency: 'CDF', expected: 9000000),
        _position(currency: 'USD', expected: 100000),
      ]);
      final b = _aggregate([
        _position(currency: 'USD', expected: 100000),
        _position(currency: 'CDF', expected: 9000000),
      ]);

      expect(a.sortableRemainingInCents, b.sortableRemainingInCents);
    });

    test('un agrégat sans position ne fait pas lever le tri', () {
      // Ne doit pas arriver — un élève sans créance n'a pas d'agrégat — mais un
      // tri qui lève emporterait tout le tableau.
      expect(_aggregate(const []).sortableRemainingInCents, 0);
      expect(_aggregate(const []).status, StudentChargeStatus.paid);
    });
  });
}
