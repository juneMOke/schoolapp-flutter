import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/models/payment_local_model.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';

/// L'encaisseur d'un versement, de la synchro jusqu'au nom affiché.
///
/// Deux sources qui ne se valent pas : ce que CE poste a stampé au guichet
/// (`cashier_*`, v19) et ce que le SERVEUR attribue (`collected_by_*`, v29).
/// La seconde n'existe que depuis que le contrat de synchro la transporte, et
/// c'est elle qui comble le vide d'un versement encaissé ailleurs.
void main() {
  Map<String, dynamic> paymentJson({
    String? collectedById,
    String? collectedByName,
  }) => {
    'id': 'pay-1',
    'studentId': 's-1',
    'academicYearId': 'y-1',
    'amountInCents': 150000,
    'currency': 'CDF',
    'paidAt': '2026-08-24T09:30:00.000Z',
    'payerFirstName': 'Joseph',
    'payerLastName': 'Kabongo',
    'collectedById': ?collectedById,
    'collectedByName': ?collectedByName,
  };

  group('pull', () {
    test('lit l\'encaisseur aplati par le flux de synchro', () {
      final dto = PaymentDto.fromJson(
        paymentJson(collectedById: 'u-42', collectedByName: 'Sarah Moke'),
      );

      expect(dto.collectedById, 'u-42');
      expect(dto.collectedByName, 'Sarah Moke');
    });

    /// Un delta scellé avant l'évolution du contrat n'en porte aucun : le
    /// parsing doit l'accepter, pas le refuser.
    test('un delta sans encaisseur reste lisible', () {
      final dto = PaymentDto.fromJson(paymentJson());

      expect(dto.collectedById, isNull);
      expect(dto.collectedByName, isNull);
    });

    test('l\'encaisseur descend jusqu\'à la ligne locale', () {
      final model = PaymentDto.fromJson(
        paymentJson(collectedById: 'u-42', collectedByName: 'Sarah Moke'),
      ).toLocalModel(1000);

      expect(model.toMap()['collected_by_id'], 'u-42');
      expect(model.toMap()['collected_by_name'], 'Sarah Moke');
    });
  });

  group('toPullPatch', () {
    PaymentLocalModel model({String? collectedById, String? collectedByName}) =>
        PaymentLocalModel(
          id: 'pay-1',
          clientUuid: 'pay-1',
          studentId: 's-1',
          amountInCents: 150000,
          currency: 'CDF',
          paidAt: '2026-08-24T09:30:00.000Z',
          payerFirstName: 'Joseph',
          payerLastName: 'Kabongo',
          collectedById: collectedById,
          collectedByName: collectedByName,
        );

    test('porte l\'attribution serveur quand le delta la nomme', () {
      final patch = model(
        collectedById: 'u-42',
        collectedByName: 'Sarah Moke',
      ).toPullPatch();

      expect(patch['collected_by_id'], 'u-42');
      expect(patch['collected_by_name'], 'Sarah Moke');
    });

    /// Le delta ne peut qu'AJOUTER l'attribution, jamais l'effacer : un
    /// payload qui l'omet — versement scellé avant l'évolution, poste resté en
    /// arrière — rendrait sinon anonyme une ligne déjà nommée.
    test('un delta muet ne rend pas anonyme une ligne déjà nommée', () {
      final patch = model().toPullPatch();

      expect(patch.containsKey('collected_by_id'), isFalse);
      expect(patch.containsKey('collected_by_name'), isFalse);
    });

    /// Ce que ce poste a imprimé sur le ticket ne se réécrit pas depuis le
    /// réseau : le patch ne touche à aucun `cashier_*`.
    test('le patch ne touche jamais au caissier stampé localement', () {
      final patch = model(collectedByName: 'Sarah Moke').toPullPatch();

      expect(patch.keys.where((k) => k.startsWith('cashier_')), isEmpty);
    });
  });

  group('nom affiché', () {
    Payment payment({
      String? cashierFirstName,
      String? cashierLastName,
      String? collectedByName,
    }) => Payment(
      id: 'pay-1',
      studentId: 's-1',
      academicYearId: 'y-1',
      amountInCents: 150000,
      currency: 'CDF',
      payerFirstName: 'Joseph',
      payerLastName: 'Kabongo',
      paidAt: DateTime.utc(2026, 8, 24),
      cashierFirstName: cashierFirstName,
      cashierLastName: cashierLastName,
      collectedByName: collectedByName,
    );

    test('le nom stampé ici l\'emporte — c\'est celui du ticket imprimé', () {
      final name = payment(
        cashierFirstName: 'Alice',
        cashierLastName: 'Mbayo',
        collectedByName: 'MBAYO Alice',
      ).cashierFullName;

      // Les deux nomment la même personne ; laisser le serveur réécrire
      // l'orthographe ferait diverger l'écran du papier remis au payeur.
      expect(name, 'Alice Mbayo');
    });

    test('l\'attribution serveur comble le vide d\'un autre guichet', () {
      final name = payment(collectedByName: 'Sarah Moke').cashierFullName;

      expect(name, 'Sarah Moke');
    });

    test('personne ne l\'a nommé : rien à afficher', () {
      expect(payment().cashierFullName, isNull);
    });

    test('un nom serveur vide ne vaut pas un nom', () {
      expect(payment(collectedByName: '   ').cashierFullName, isNull);
    });
  });
}
