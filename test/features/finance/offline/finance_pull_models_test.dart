import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';

/// Le **parsing** des deltas de paiement — pas leur persistance.
///
/// Le test du repository construit ses DTO directement en Dart : il n'exerce
/// donc jamais `fromJson`, et une devise codée en dur y passerait au vert.
/// C'est le trou que ce fichier ferme.
void main() {
  Map<String, dynamic> delta({
    List<Map<String, dynamic>> allocations = const [],
  }) => {
    'id': 'pay-1',
    'studentId': 'stu-1',
    'academicYearId': 'ay-1',
    'paidAt': '2026-08-30T09:00:00Z',
    'payerFirstName': 'Joseph',
    'payerLastName': 'Kabongo',
    'allocations': allocations,
  };

  Map<String, dynamic> allocation({
    String currency = 'CDF',
    int amountInCents = 9000000,
  }) => {
    'id': 'alloc-1',
    'studentChargeId': 'ch-1',
    'feeCode': 'ASSURANCE',
    'studentChargeLabel': 'Assurance scolaire',
    'amountInCents': amountInCents,
    'currency': currency,
  };

  group('l\'imputation d\'un delta porte SA devise', () {
    test('elle est lue depuis le payload, jamais supposée', () {
      final dto = PaymentDeltaDto.fromJson(delta(allocations: [allocation()]));

      expect(dto.allocations.single.currency, 'CDF');
      expect(dto.allocations.single.amountInCents, 9000000);
    });

    test('deux imputations gardent CHACUNE la sienne', () {
      // L'héritage depuis le paiement parent était faux dès qu'un versement en
      // portait deux : toutes prenaient la première.
      final dto = PaymentDeltaDto.fromJson(
        delta(
          allocations: [
            allocation(),
            allocation(currency: 'USD', amountInCents: 42500),
          ],
        ),
      );

      expect(dto.allocations.map((a) => a.currency), ['CDF', 'USD']);
    });

    test('le libellé de la créance est lu, plus replié sur le fee_code', () {
      final dto = PaymentDeltaDto.fromJson(delta(allocations: [allocation()]));

      expect(dto.allocations.single.studentChargeLabel, 'Assurance scolaire');
    });

    test('un libellé absent retombe sur le fee_code, sans lever', () {
      // Un delta scellé avant que le contrat ne le porte peut encore descendre.
      final raw = allocation()..remove('studentChargeLabel');
      final dto = PaymentDeltaDto.fromJson(delta(allocations: [raw]));

      expect(dto.allocations.single.studentChargeLabel, 'ASSURANCE');
    });

    test('une devise absente reste VIDE, jamais « USD » par défaut', () {
      // Écrire une unité que personne n'a choisie ferait imprimer des dollars
      // sur un reçu qui n'en est pas.
      final raw = allocation()..remove('currency');
      final dto = PaymentDeltaDto.fromJson(delta(allocations: [raw]));

      expect(dto.allocations.single.currency, isEmpty);
    });

    test(
      'les imputations descendent jusqu\'au modèle local avec leur devise',
      () {
        final dto = PaymentDeltaDto.fromJson(
          delta(
            allocations: [
              allocation(),
              allocation(currency: 'USD', amountInCents: 42500),
            ],
          ),
        );

        expect(dto.allocationModels().map((a) => a.currency), ['CDF', 'USD']);
      },
    );
  });

  group('le versement n\'a plus de montant à lui', () {
    test('il se dérive des imputations, pas d\'un champ du delta', () {
      // `amounts` est sur le fil, mais les imputations sont l'autorité : le
      // back lui-même invite à reconstruire le total sans lui faire confiance.
      final dto = PaymentDeltaDto.fromJson(delta(allocations: [allocation()]));

      expect(dto.allocationModels().single.amountInCents, 9000000);
    });
  });
}
