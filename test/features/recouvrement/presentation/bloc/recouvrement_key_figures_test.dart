import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_fee_charge_aggregate.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_key_figures.dart';

/// Le projecteur des quatre chiffres de tête : pur, testable sans base ni
/// widget.
void main() {
  LocalRecoveryLine line(
    String studentId, {
    String? level = 'lvl-1',
    required List<(String feeCode, String currency, int expected, int paid)>
    charges,
  }) => LocalRecoveryLine(
    schoolLevelId: level,
    studentId: studentId,
    charges: [
      for (final (feeCode, currency, expected, paid) in charges)
        RecoveryChargePosition(
          feeCode: feeCode,
          position: FeeChargePosition(
            currency: currency,
            expectedInCents: expected,
            paidMirrorInCents: paid,
            paidPendingInCents: 0,
          ),
        ),
    ],
  );

  group('l\'invariant des trois statuts', () {
    test('rien + partiel + soldé == total, toujours', () {
      final figures = RecouvrementKeyFiguresProjector.project([
        line('s1', charges: [('TUITION', 'USD', 30000, 0)]),
        line('s2', charges: [('TUITION', 'USD', 30000, 12000)]),
        line('s3', charges: [('TUITION', 'USD', 30000, 30000)]),
        line('s4', charges: [('TUITION', 'USD', 30000, 0)]),
      ]);

      expect(figures.total, 4);
      expect(figures.none, 2);
      expect(figures.partial, 1);
      expect(figures.settled, 1);
      expect(figures.none + figures.partial + figures.settled, figures.total);
    });

    test('les trois sont exclusifs : un soldé n\'est jamais partiel', () {
      final figures = RecouvrementKeyFiguresProjector.project([
        line(
          's1',
          charges: [('TUITION', 'USD', 30000, 30000), ('BOOKS', 'USD', 0, 0)],
        ),
      ]);

      expect(figures.settled, 1);
      expect(figures.partial, 0);
      expect(figures.none, 0);
    });
  });

  group('la population comptée', () {
    test(
      'le même élève sur deux niveaux compte deux fois — il doit à chacun',
      () {
        final figures = RecouvrementKeyFiguresProjector.project([
          line('s1', level: 'lvl-1', charges: [('TUITION', 'USD', 30000, 0)]),
          line('s1', level: 'lvl-2', charges: [('TUITION', 'USD', 20000, 0)]),
        ]);

        expect(
          figures.total,
          2,
          reason: 'le total de la page reste la somme de ses groupes',
        );
        expect(figures.expected.amountIn('USD')!.amountInCents, 50000);
      },
    );

    test('un registre vide rend les chiffres vides, pas des zéros bâtis', () {
      expect(
        RecouvrementKeyFiguresProjector.project(const []),
        RecouvrementKeyFigures.empty,
      );
      expect(RecouvrementKeyFigures.empty.isEmpty, isTrue);
    });
  });

  group('les montants', () {
    test('deux devises restent côte à côte, jamais sommées', () {
      final figures = RecouvrementKeyFiguresProjector.project([
        line(
          's1',
          charges: [
            ('TUITION', 'USD', 30000, 12000),
            ('REGISTRATION', 'CDF', 5000000, 1000000),
          ],
        ),
      ]);

      expect(figures.expected.entries, hasLength(2));
      expect(figures.expected.amountIn('USD')!.amountInCents, 30000);
      expect(figures.expected.amountIn('CDF')!.amountInCents, 5000000);
      expect(figures.paid.amountIn('USD')!.amountInCents, 12000);
      expect(figures.remaining.amountIn('CDF')!.amountInCents, 4000000);
    });

    test(
      'le reste n\'est PAS attendu − perçu : le trop-perçu croisé le prouve',
      () {
        // 400 payés sur 300 de scolarité, rien sur 100 de fournitures.
        final figures = RecouvrementKeyFiguresProjector.project([
          line(
            's1',
            charges: [
              ('TUITION', 'USD', 30000, 40000),
              ('BOOKS', 'USD', 10000, 0),
            ],
          ),
        ]);

        expect(figures.expected.amountIn('USD')!.amountInCents, 40000);
        expect(figures.paid.amountIn('USD')!.amountInCents, 40000);
        expect(
          figures.remaining.amountIn('USD')!.amountInCents,
          10000,
          reason: 'attendu − perçu vaudrait 0, et ce serait faux',
        );
      },
    );

    test(
      'le perçu n\'est jamais plafonné : un trop-perçu remonte tel quel',
      () {
        final figures = RecouvrementKeyFiguresProjector.project([
          line('s1', charges: [('TUITION', 'USD', 30000, 45000)]),
        ]);

        expect(figures.paid.amountIn('USD')!.amountInCents, 45000);
        expect(figures.remaining.amountIn('USD')!.amountInCents, 0);
        expect(figures.settled, 1);
      },
    );
  });

  group('la part de l\'effectif', () {
    test('arrondie à l\'entier', () {
      final figures = RecouvrementKeyFiguresProjector.project([
        for (var i = 0; i < 3; i++)
          line('s$i', charges: [('TUITION', 'USD', 30000, 0)]),
      ]);

      expect(figures.percentOf(1), 33);
      expect(figures.percentOf(2), 67);
      expect(figures.percentOf(3), 100);
    });

    test('personne de concerné ⇒ 0, jamais une division par zéro', () {
      expect(RecouvrementKeyFigures.empty.percentOf(0), 0);
      expect(RecouvrementKeyFigures.empty.percentOf(5), 0);
    });
  });
}
