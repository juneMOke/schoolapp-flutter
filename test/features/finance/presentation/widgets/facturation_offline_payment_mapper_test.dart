import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_offline_payment_mapper.dart';

/// Ce que ces tests tiennent : **la date que le guichet désigne est celle qui
/// est écrite**, et le cas par défaut — aujourd'hui — reste rigoureusement
/// identique à l'horodatage automatique qu'il remplace.
PaymentsCreateRequested _request({required DateTime paidAt}) =>
    PaymentsCreateRequested(
      studentId: 's1',
      academicYearId: 'y1',
      paidAt: paidAt,
      amounts: MoneyBag.of(const [Money(700000, 'CDF')]),
      allocations: const [
        CreatePaymentAllocationInput(
          studentChargeId: 'c1',
          feeCode: 'TUITION',
          studentChargeLabel: 'Frais',
          amountInCents: 700000,
          currency: 'CDF',
        ),
      ],
    );

void main() {
  group('paidAt', () {
    test('l\'instant de l\'écriture atteint le draft, rendu en UTC', () {
      // Il est 14 h 30 à Kinshasa (13 h 30 UTC). Le jour porté par la requête
      // n'est plus lu : un versement est daté de sa saisie (lot C).
      final draft = recordPaymentDraftFromRequest(
        _request(paidAt: DateTime(2026, 9, 12)),
        now: DateTime.utc(2026, 9, 16, 13, 30),
      );

      expect(draft.paidAt, '2026-09-16T13:30:00.000Z');
    });

    // La revue l'a trouvé : la requête est construite au clic sur « Encaisser »,
    // le versement écrit à la validation de la popin. Minuit passé entre les
    // deux, recomposer le jour de la requête avec l'heure datait le versement
    // de la VEILLE à 00 h 00, en tête de la pile d'hier.
    test(
      'validé juste après minuit, le versement est du jour de la validation',
      () {
        // Requête construite le 16 à 23 h 59 (Kinshasa), validée le 17 à 00 h 00.
        final now = DateTime.utc(2026, 9, 16, 23, 0, 10);

        final draft = recordPaymentDraftFromRequest(
          _request(paidAt: DateTime(2026, 9, 16)),
          now: now,
        );

        expect(draft.paidAt, now.toIso8601String());
        expect(SchoolTime.wallClock(DateTime.parse(draft.paidAt)).day, 17);
      },
    );

    test('un versement daté d\'aujourd\'hui reproduit l\'horodatage courant', () {
      // Non-régression A1 : avant ce lot, le mapper posait
      // `DateTime.now().toUtc()`. Le cas par défaut doit rendre exactement cela.
      final now = DateTime.utc(2026, 9, 16, 13, 30, 12, 340);

      final draft = recordPaymentDraftFromRequest(
        _request(paidAt: SchoolTime.today(now)),
        now: now,
      );

      expect(draft.paidAt, now.toIso8601String());
    });

    test(
      'une tablette réglée en UTC ne fait pas glisser la journée de caisse',
      () {
        // 23 h 30 UTC le 16 = 00 h 30 le 17 à Kinshasa. La caisse serveur
        // agrège en heure de Kinshasa : le versement appartient au 17.
        final now = DateTime.utc(2026, 9, 16, 23, 30);

        final draft = recordPaymentDraftFromRequest(
          _request(paidAt: SchoolTime.today(now)),
          now: now,
        );

        expect(SchoolTime.wallClock(DateTime.parse(draft.paidAt)).day, 17);
      },
    );
  });

  group('le reste du draft', () {
    test('traverse sans être retouché', () {
      final draft = recordPaymentDraftFromRequest(
        _request(paidAt: DateTime(2026, 9, 12)),
        now: DateTime.utc(2026, 9, 16, 13, 30),
      );

      expect(draft.studentId, 's1');
      expect(draft.academicYearId, 'y1');
      expect(draft.allocations.single.feeCode, 'TUITION');
      expect(draft.allocations.single.amountInCents, 700000);
      // Laissé nul : c'est le repository qui applique le défaut CASH.
      expect(draft.method, isNull);
      // Vide ⇒ nul : le repository écrit alors l'identité perçu/imputé.
      expect(draft.tenders, isNull);
    });
  });
}
