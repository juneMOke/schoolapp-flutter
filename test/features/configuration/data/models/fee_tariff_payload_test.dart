import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/data/models/fee_tariff_payload_model.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';

void main() {
  group('corps envoyé à /finance/tariffs', () {
    final draft = FeeTariffDraft(
      feeCode: 'CANTEEN',
      label: 'Cantine',
      amountInCents: 800000,
      currency: 'USD',
      dueAt: DateTime.utc(2027, 6, 30, 23, 59, 59),
      schoolLevelId: 'niveau-1',
      schoolLevelGroupId: 'cycle-1',
      academicYearId: 'annee-1',
    );

    test('dueAt part SANS le suffixe Z', () {
      // La même notion part AVEC sur /provisioning/apply. Le serveur attend ici
      // un LocalDateTime, et le Z le ferait échouer : dette de contrat assumée
      // côté serveur, isolée en deux fonctions nommées.
      final body = FeeTariffPayloadModel.fromEntity(draft).toJson();

      expect(body['dueAt'], '2027-06-30T23:59:59');
      expect(body['dueAt'], isNot(endsWith('Z')));
    });

    test('le corps porte le niveau, le cycle et l\'année', () {
      final body = FeeTariffPayloadModel.fromEntity(draft).toJson();

      expect(body['schoolLevelId'], 'niveau-1');
      expect(body['schoolLevelGroupId'], 'cycle-1');
      expect(body['academicYearId'], 'annee-1');
      expect(body['amountInCents'], 800000);
    });

    test('une échéance absente ne part pas du tout', () {
      final body = FeeTariffPayloadModel.fromEntity(
        const FeeTariffDraft(
          feeCode: 'TUITION',
          label: 'Minerval',
          amountInCents: 68000,
          currency: 'USD',
          dueAt: null,
          schoolLevelId: 'n',
          schoolLevelGroupId: 'c',
          academicYearId: 'a',
        ),
      ).toJson();

      expect(body.containsKey('dueAt'), isFalse);
    });
  });

  group('lecture d\'un tarif', () {
    test('un tarif porte UN niveau', () {
      final tariff = FeeTariffResponseModel.fromJson(
        jsonDecode('''
        {"id":"t-1","feeCode":"TUITION","label":"Minerval",
         "amountInCents":68000,"currency":"USD",
         "dueAt":"2027-06-30T23:59:59",
         "schoolLevelId":"n-1","schoolLevelGroupId":"c-1"}
        ''')
            as Map<String, dynamic>,
      ).toEntity();

      expect(tariff.schoolLevelId, 'n-1');
      expect(tariff.dueAt, isNotNull);
      expect(tariff.dueAt!.day, 30);
    });

    test('un libellé absent se rabat sur le code', () {
      // Mieux vaut « CANTEEN » qu'une ligne vide dans une liste de tarifs.
      final tariff = FeeTariffResponseModel.fromJson(
        jsonDecode('{"id":"t-2","feeCode":"CANTEEN","amountInCents":8000}')
            as Map<String, dynamic>,
      ).toEntity();

      expect(tariff.label, 'CANTEEN');
      expect(tariff.currency, 'USD');
    });

    test('une réponse sans échéance ne lève pas', () {
      final tariff = FeeTariffResponseModel.fromJson(
        jsonDecode('{"id":"t-3","feeCode":"BOOKS"}') as Map<String, dynamic>,
      ).toEntity();

      expect(tariff.dueAt, isNull);
      expect(tariff.schoolLevelId, isEmpty);
    });
  });
}
