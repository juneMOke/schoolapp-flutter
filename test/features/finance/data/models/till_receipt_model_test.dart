import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model/till_receipt_model.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';

TillReceipt _receipt(String raw) => TillReceiptModel.fromJson(
  jsonDecode(raw) as Map<String, dynamic>,
).toEntity();

List<TillReceipt> _receipts(String raw) => [
  for (final item in jsonDecode(raw) as List<dynamic>)
    TillReceiptModel.fromJson(item as Map<String, dynamic>).toEntity(),
];

/// Une **ligne d'encaissement**, lue depuis le fil.
///
/// ⚠️ L'unité est la ligne, pas le reçu : un versement qui a pris des francs
/// *et* des dollars apparaît deux fois sous le même numéro, et ce n'est pas un
/// doublon. Les tests qui suivent l'imposent.
///
/// L'**enveloppe paginée** n'est pas testée ici : sa forme change (le serveur
/// ajoute un compteur de fenêtre à côté de `totalElements`, ce qui lui impose
/// une enveloppe maison). Seule la ligne, dont le contrat est figé, l'est.
void main() {
  group('le numéro scellé', () {
    test('descend tel quel — jamais recomposé', () {
      expect(_receipt(_nominal).receiptNumber, 'ETL-RC-2526-000184');
      expect(
        _receipt(_boutiqueSale).receiptNumber,
        'ETL-RV-2526-000182',
        reason:
            'le type RV désigne une vente : il se lit sur la pièce, il ne se '
            'déduit pas de la source',
      );
    });

    test(
      'un versement sans pièce scellée le dit, il n’invente pas de numéro',
      () {
        final row = _receipt(_crossedWithoutNumber);

        expect(row.receiptNumber, isNull);
        expect(row.hasNoSealedNumber, isTrue);
        expect(
          row.paymentId,
          isNotEmpty,
          reason:
              'l’identifiant technique existe, mais il ne doit jamais prendre la '
              'place du numéro à l’écran',
        );
      },
    );

    test('un numéro vide vaut absent — les deux disent la même chose', () {
      expect(_receipt(_blankNumber).hasNoSealedNumber, isTrue);
      expect(_receipt(_blankNumber).receiptNumber, isNull);
    });
  });

  group('les identités', () {
    test('un champ vide devient null, pas une chaîne vide', () {
      // Le serveur envoie `""` pour un caissier non résolu ; le tiret se décide
      // à l'affichage, sur null. Une chaîne vide rendrait la cellule blanche
      // indiscernable d'une donnée absente.
      expect(_receipt(_crossedWithoutNumber).collectedBy, isNull);
    });

    test('une vente boutique ne désigne ni élève ni classe', () {
      final row = _receipt(_boutiqueSale);

      expect(row.studentName, isNull);
      expect(row.classroom, isNull);
      expect(row.source, 'BOUTIQUE');
    });
  });

  group('le croisement', () {
    test('porte ses trois informations, ou n’est pas annoncé', () {
      final crossed = _receipt(_crossedWithoutNumber);
      final plain = _receipt(_nominal);

      expect(crossed.isCrossed, isTrue);
      expect(crossed.settledAmount, 11500000);
      expect(crossed.settledCurrency, 'CDF');
      expect(crossed.rateMicros, 2850 * ExchangeRate.scale);

      expect(plain.isCrossed, isFalse);
      expect(plain.settledAmount, isNull);
      expect(plain.rateMicros, isNull);
    });

    test('un croisement amputé de son taux n’est pas annoncé du tout', () {
      final row = _receipt(_partialCrossing);

      expect(
        row.isCrossed,
        isFalse,
        reason:
            'un montant soldé sans son taux serait une conversion à moitié '
            'annoncée — la doctrine interdit la conversion silencieuse',
      );
      expect(
        row.settledAmount,
        isNotNull,
        reason:
            'la donnée reçue n’est pas effacée ; c’est son ANNONCE qui est '
            'refusée tant qu’elle est incomplète',
      );
    });

    test('un taux nul est écarté, jamais replié sur zéro', () {
      expect(
        _receipt(_zeroRate).rateMicros,
        isNull,
        reason: '« au taux de 0 » se lirait comme une conversion observée',
      );
    });
  });

  group('le montant', () {
    test('est le net conservé, dans la devise réellement tendue', () {
      final row = _receipt(_nominal);

      // 120 000 tendus dont 5 000 rendus s'écrivent 115 000, sans quoi le total
      // ne retombe pas sur le comptage du tiroir.
      expect(row.amount, 24000);
      expect(row.currency, 'USD');
    });

    test('absent, il lève — une ligne de preuve à zéro serait fausse', () {
      expect(
        () => _receipt(_missingAmount),
        throwsA(isA<TypeError>()),
        reason:
            'elle s’afficherait à zéro dans une table qu’un caissier rapproche '
            'de ses billets',
      );
    });
  });

  group('l’unité est la ligne', () {
    test('un même reçu porte deux lignes quand le panier est mixte', () {
      final rows = _receipts(_mixedBasket);

      expect(rows, hasLength(2));
      expect(
        rows.map((row) => row.receiptNumber).toSet(),
        {'ETL-RC-2526-000200'},
        reason: 'même numéro : c’est un seul reçu, à deux lignes de tender',
      );
      expect(
        rows.map((row) => row.paymentId).toSet(),
        hasLength(1),
        reason: 'un seul versement, donc un seul identifiant technique',
      );
      expect(
        rows.map((row) => row.currency),
        ['USD', 'CDF'],
        reason:
            'chaque ligne range son montant dans SA caisse — le reçu n’a pas '
            'de devise à lui',
      );
    });
  });
}

const String _nominal = '''
{
  "paymentId": "9d1f0a10-1111-4c22-9f01-aaaaaaaaaaaa",
  "paidAt": "2026-05-15T09:12:00Z",
  "receiptNumber": "ETL-RC-2526-000184",
  "studentName": "Kabongo Mwamba Daniel",
  "classroom": "6ème primaire",
  "collectedBy": "Moke Junior",
  "source": "FACTURATION",
  "amount": 24000,
  "currency": "USD",
  "settledAmount": null,
  "settledCurrency": null,
  "rate": null
}
''';

/// Croisée **et** sans pièce scellée : une reprise de cahier qui a soldé une
/// créance en francs avec des dollars.
const String _crossedWithoutNumber = '''
{
  "paymentId": "9d1f0a10-2222-4c22-9f01-bbbbbbbbbbbb",
  "paidAt": "2026-05-15T10:40:00Z",
  "receiptNumber": null,
  "studentName": "Ilunga Kasongo Esther",
  "classroom": "1ère humanités",
  "collectedBy": "",
  "source": "FACTURATION",
  "amount": 4000,
  "currency": "USD",
  "settledAmount": 11500000,
  "settledCurrency": "CDF",
  "rate": 2850
}
''';

const String _blankNumber = '''
{
  "paymentId": "9d1f0a10-7777-4c22-9f01-777777777777",
  "paidAt": "2026-05-15T08:00:00Z",
  "receiptNumber": "   ",
  "studentName": "Numéro Blanc",
  "classroom": "6ème primaire",
  "collectedBy": "Moke Junior",
  "source": "FACTURATION",
  "amount": 1000,
  "currency": "USD"
}
''';

const String _boutiqueSale = '''
{
  "paymentId": "9d1f0a10-3333-4c22-9f01-cccccccccccc",
  "paidAt": "2026-05-14T15:02:00Z",
  "receiptNumber": "ETL-RV-2526-000182",
  "studentName": null,
  "classroom": null,
  "collectedBy": "Bofunda Alain",
  "source": "BOUTIQUE",
  "amount": 5500,
  "currency": "USD",
  "settledAmount": null,
  "settledCurrency": null,
  "rate": null
}
''';

/// Un montant soldé sans son taux : le serveur ne devrait pas l'envoyer, et
/// l'écran ne doit surtout pas l'annoncer à moitié.
const String _partialCrossing = '''
{
  "paymentId": "9d1f0a10-4444-4c22-9f01-dddddddddddd",
  "paidAt": "2026-05-15T11:00:00Z",
  "receiptNumber": "ETL-RC-2526-000190",
  "studentName": "Ngoy Nsimba Merveille",
  "classroom": "2ème maternelle",
  "collectedBy": "Moke Junior",
  "source": "FACTURATION",
  "amount": 3000,
  "currency": "USD",
  "settledAmount": 8550000,
  "settledCurrency": "CDF",
  "rate": null
}
''';

const String _zeroRate = '''
{
  "paymentId": "9d1f0a10-8888-4c22-9f01-888888888888",
  "paidAt": "2026-05-15T11:30:00Z",
  "receiptNumber": "ETL-RC-2526-000191",
  "studentName": "Taux Nul",
  "classroom": "2ème maternelle",
  "collectedBy": "Moke Junior",
  "source": "FACTURATION",
  "amount": 3000,
  "currency": "USD",
  "settledAmount": 8550000,
  "settledCurrency": "CDF",
  "rate": 0
}
''';

/// Un versement réglé moitié en dollars, moitié en francs : **deux lignes sous
/// le même numéro**, et ce n'est pas un doublon.
const String _mixedBasket = '''
[
  {
    "paymentId": "9d1f0a10-5555-4c22-9f01-eeeeeeeeeeee",
    "paidAt": "2026-05-15T12:00:00Z",
    "receiptNumber": "ETL-RC-2526-000200",
    "studentName": "Mbala Tshibangu Grace",
    "classroom": "3ème primaire",
    "collectedBy": "Ilunga Céline",
    "source": "FACTURATION",
    "amount": 1000,
    "currency": "USD",
    "settledAmount": null, "settledCurrency": null, "rate": null
  },
  {
    "paymentId": "9d1f0a10-5555-4c22-9f01-eeeeeeeeeeee",
    "paidAt": "2026-05-15T12:00:00Z",
    "receiptNumber": "ETL-RC-2526-000200",
    "studentName": "Mbala Tshibangu Grace",
    "classroom": "3ème primaire",
    "collectedBy": "Ilunga Céline",
    "source": "FACTURATION",
    "amount": 10000000,
    "currency": "CDF",
    "settledAmount": null, "settledCurrency": null, "rate": null
  }
]
''';

const String _missingAmount = '''
{
  "paymentId": "9d1f0a10-6666-4c22-9f01-ffffffffffff",
  "paidAt": "2026-05-15T13:00:00Z",
  "receiptNumber": "ETL-RC-2526-000201",
  "studentName": "Sans Montant",
  "classroom": "6ème primaire",
  "collectedBy": "Moke Junior",
  "source": "FACTURATION",
  "currency": "USD"
}
''';
