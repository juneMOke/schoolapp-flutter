/// Les charges utiles de référence du pilotage financier — **du JSON brut**,
/// recopié depuis `openApi.yaml` §Finance et les DTO du serveur, jamais depuis
/// l'exemple d'une note de migration.
///
/// ## Pourquoi des chaînes et pas des `Map` Dart
///
/// Une `Map` littérale porte déjà les types que le modèle attend : ses nombres
/// sont des `int`, ses objets imbriqués des `Map<String, dynamic>`. Elle ne dit
/// donc rien des deux endroits où la lecture casse en vrai — un
/// `as Map<String, dynamic>` sur un élément de liste, et un entier que le
/// décodeur rend en `double`. `jsonDecode` reproduit exactement ce que Dio pose dans le
/// modèle ; c'est le seul décodage qui prouve quelque chose.
///
/// ## Fidélité au serveur, y compris là où elle surprend
///
/// - `periodStart` / `periodEnd` sont des `LocalDate` côté Java : ils
///   descendent en `"2025-09-01"`, **sans heure**. `generatedAt` est un
///   `Instant`, lui horodaté.
/// - Tous les montants sont en **centimes**, CDF compris.
/// - `byCurrency` est trié par code de devise, et une devise que l'école
///   facture sans qu'un franc y circule est renvoyée **à zéro**, jamais absente.
library;

import 'dart:convert';

/// Décode une fixture comme le ferait la couche réseau.
Map<String, dynamic> decodeFixture(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

// ─────────────────────────────────────────────────────────────────────────────
// Recouvrement — GET /api/v1/finance-stats/recovery
// ─────────────────────────────────────────────────────────────────────────────

/// Le cas nominal : une école mono-devise, trois postes de frais, douze mois
/// d'axe. `currentBucketIndex` désigne le mois en cours.
const String recoverySingleCurrencyJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "byCurrency": [
    {
      "currency": "USD",
      "kpis": {
        "collected": 5240000,
        "expected": 7820000,
        "outstanding": 2580000,
        "collectionRate": 67
      },
      "byFeeCode": [
        {
          "code": "TUITION",
          "label": "Minerval",
          "collected": 4100000,
          "expected": 6000000,
          "outstanding": 1900000,
          "collectionRate": 68
        },
        {
          "code": "REGISTRATION",
          "label": "Frais d'inscription",
          "collected": 900000,
          "expected": 1200000,
          "outstanding": 300000,
          "collectionRate": 75
        },
        {
          "code": "TRANSPORT",
          "label": "Transport scolaire",
          "collected": 240000,
          "expected": 620000,
          "outstanding": 380000,
          "collectionRate": 39
        }
      ],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [
          { "key": "2025-09", "value": 1200000, "isCurrent": false },
          { "key": "2025-10", "value": 980000, "isCurrent": false },
          { "key": "2025-11", "value": 640000, "isCurrent": false },
          { "key": "2025-12", "value": 210000, "isCurrent": false },
          { "key": "2026-01", "value": 730000, "isCurrent": false },
          { "key": "2026-02", "value": 410000, "isCurrent": false },
          { "key": "2026-03", "value": 300000, "isCurrent": false },
          { "key": "2026-04", "value": 160000, "isCurrent": false },
          { "key": "2026-05", "value": 610000, "isCurrent": true },
          { "key": "2026-06", "value": 0, "isCurrent": false },
          { "key": "2026-07", "value": 0, "isCurrent": false },
          { "key": "2026-08", "value": 0, "isCurrent": false }
        ]
      }
    }
  ]
}
''';

/// Deux devises, dont une **dormante à zéro** : l'école facture en francs, rien
/// n'y a circulé. Le bloc est présent — son absence se lirait comme une école
/// qui aurait cessé de facturer dedans.
///
/// Le taux de la devise dormante vaut **100** parce que `expected` vaut 0. Il
/// se lit « rien ne manque », pas « tout a été recouvré » : c'est le cas qui
/// doit rendre un tiret à l'écran, jamais un 100 % triomphant.
const String recoveryDormantCurrencyJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "byCurrency": [
    {
      "currency": "CDF",
      "kpis": {
        "collected": 0,
        "expected": 0,
        "outstanding": 0,
        "collectionRate": 100
      },
      "byFeeCode": [],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [
          { "key": "2025-09", "value": 0, "isCurrent": false },
          { "key": "2026-05", "value": 0, "isCurrent": true }
        ]
      }
    },
    {
      "currency": "USD",
      "kpis": {
        "collected": 5240000,
        "expected": 7820000,
        "outstanding": 2580000,
        "collectionRate": 67
      },
      "byFeeCode": [
        {
          "code": "TUITION",
          "label": "Minerval",
          "collected": 4100000,
          "expected": 6000000,
          "outstanding": 1900000,
          "collectionRate": 68
        }
      ],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [
          { "key": "2025-09", "value": 1200000, "isCurrent": false },
          { "key": "2026-05", "value": 610000, "isCurrent": true }
        ]
      }
    }
  ]
}
''';

/// Un poste où **`collected` dépasse `expected`** : un arriéré d'un autre
/// exercice qui se solde. Le taux reste sous 100 parce qu'il se calcule sur
/// `(expected − outstanding) / expected`, et non sur l'encaissé.
///
/// C'est la ligne que la carte de poste rendait incohérente tant qu'elle
/// n'affichait pas `outstanding` : un encaissé supérieur à l'attendu à côté
/// d'une barre aux deux tiers, sans rien pour expliquer l'écart.
const String recoveryOverCollectedJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "byCurrency": [
    {
      "currency": "USD",
      "kpis": {
        "collected": 1450000,
        "expected": 1200000,
        "outstanding": 400000,
        "collectionRate": 66
      },
      "byFeeCode": [
        {
          "code": "TUITION",
          "label": "Minerval",
          "collected": 1450000,
          "expected": 1200000,
          "outstanding": 400000,
          "collectionRate": 66
        }
      ],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [
          { "key": "2026-05", "value": 1450000, "isCurrent": true }
        ]
      }
    }
  ]
}
''';

// ─────────────────────────────────────────────────────────────────────────────
// Caisse — GET /api/v1/finance-stats/till
// ─────────────────────────────────────────────────────────────────────────────

/// Le cas nominal de la caisse : une journée, deux devises reçues, des ventes
/// boutique en dollars et rien que des frais en francs.
///
/// Deux invariants s'y lisent : `summary.total == fees + boutique`, et
/// `summary.total == somme des buckets[].total`. Le second est le seul des deux
/// qui vaille comme contrôle de cohérence — voir `monthlyCollected` côté
/// recouvrement, qui n'en est pas un.
///
/// ⚠️ **`impute` ne se déduit pas de `encaisse`, et cette fixture l'impose** :
/// le bloc USD de l'imputation (1 500,00 $) dépasse la moitié frais du bloc USD
/// de l'encaisse (1 000,00 $), parce qu'une partie des créances en dollars a
/// été réglée **en francs**. Toute tentative de recontrôler « imputé == frais
/// encaissés » rougit ici, et c'est fait exprès : c'est précisément ce que la
/// bascule perçu/imputé rend faux.
const String tillDayJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "day",
    "periodStart": "2026-05-15",
    "periodEnd": "2026-05-15",
    "generatedAt": "2026-05-15T18:04:11Z"
  },
  "timeZone": "Africa/Kinshasa",
  "encaisse": [
    {
      "currency": "CDF",
      "summary": { "total": 9000000, "fees": 9000000, "boutique": 0 },
      "buckets": [
        {
          "key": "2026-05-15",
          "total": 9000000,
          "fees": 9000000,
          "boutique": 0,
          "isCurrent": true
        }
      ]
    },
    {
      "currency": "USD",
      "summary": { "total": 123450, "fees": 100000, "boutique": 23450 },
      "buckets": [
        {
          "key": "2026-05-15",
          "total": 123450,
          "fees": 100000,
          "boutique": 23450,
          "isCurrent": true
        }
      ]
    }
  ],
  "impute": [
    {
      "currency": "CDF",
      "total": 6000000,
      "byFeeCode": [
        { "code": "TUITION", "label": "Minerval", "amount": 6000000 }
      ]
    },
    {
      "currency": "USD",
      "total": 150000,
      "byFeeCode": [
        { "code": "TUITION", "label": "Minerval", "amount": 120000 },
        {
          "code": "REGISTRATION",
          "label": "Frais d'inscription",
          "amount": 30000
        }
      ]
    }
  ]
}
''';

/// Un mois de 31 jours : l'axe le plus chargé que l'écran ait à dessiner, et
/// celui où le libellé sous chaque barre doit être allégé.
///
/// Les clés sont journalières (`YYYY-MM-DD`) — le mois se lit jour par jour,
/// jamais en semaines ISO, qui débordent de part et d'autre. Seule la période
/// `year` replie l'axe en mois (`YYYY-MM`).
final String tillMonthJson = _tillMonth();

String _tillMonth() {
  final buckets = <String>[];
  for (var day = 1; day <= 31; day++) {
    final key = '2026-05-${day.toString().padLeft(2, '0')}';
    // Un dimanche sans guichet : l'intervalle creux rend une barre à zéro,
    // jamais une barre absente.
    final fees = day % 7 == 0 ? 0 : 40000 + day * 1000;
    final boutique = day % 3 == 0 ? 5000 : 0;
    buckets.add(
      '{ "key": "$key", "total": ${fees + boutique}, "fees": $fees, '
      '"boutique": $boutique, "isCurrent": ${day == 15} }',
    );
  }
  final fees = List.generate(
    31,
    (i) => (i + 1) % 7 == 0 ? 0 : 40000 + (i + 1) * 1000,
  ).fold<int>(0, (sum, value) => sum + value);
  final boutique = List.generate(
    31,
    (i) => (i + 1) % 3 == 0 ? 5000 : 0,
  ).fold<int>(0, (sum, value) => sum + value);

  return '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "month",
    "periodStart": "2026-05-01",
    "periodEnd": "2026-05-31",
    "generatedAt": "2026-05-15T18:04:11Z"
  },
  "timeZone": "Africa/Kinshasa",
  "encaisse": [
    {
      "currency": "USD",
      "summary": {
        "total": ${fees + boutique},
        "fees": $fees,
        "boutique": $boutique
      },
      "buckets": [${buckets.join(', ')}]
    }
  ],
  "impute": [
    {
      "currency": "USD",
      "total": $fees,
      "byFeeCode": [
        { "code": "TUITION", "label": "Minerval", "amount": $fees }
      ]
    }
  ]
}
''';
}

/// Une journée creuse : l'école facture en dollars, rien n'est entré. Le bloc
/// est renvoyé **à zéro**, et `buckets` porte quand même sa journée.
///
/// C'est le cas le plus fréquent de l'onglet Caisse, et celui qui rendait une
/// planche de zéros tant que l'état vide de l'écran pendait à
/// `encaisse.isEmpty`.
///
/// `impute` y est **vide** : rien n'a été encaissé, donc rien n'a été éteint.
const String tillEmptyDayJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "day",
    "periodStart": "2026-05-17",
    "periodEnd": "2026-05-17",
    "generatedAt": "2026-05-17T19:00:00Z"
  },
  "timeZone": "Africa/Kinshasa",
  "encaisse": [
    {
      "currency": "USD",
      "summary": { "total": 0, "fees": 0, "boutique": 0 },
      "buckets": [
        {
          "key": "2026-05-17",
          "total": 0,
          "fees": 0,
          "boutique": 0,
          "isCurrent": true
        }
      ]
    }
  ],
  "impute": []
}
''';

/// L'axe annuel de la caisse : douze compartiments, clés `YYYY-MM`. C'est la
/// seule période où la clé n'est pas journalière — le formatteur de libellé
/// doit s'en apercevoir.
const String tillYearJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-15T18:04:11Z"
  },
  "timeZone": "Africa/Kinshasa",
  "impute": [
    {
      "currency": "USD",
      "total": 3400000,
      "byFeeCode": [
        { "code": "TUITION", "label": "Minerval", "amount": 3400000 }
      ]
    }
  ],
  "encaisse": [
    {
      "currency": "USD",
      "summary": { "total": 3600000, "fees": 3400000, "boutique": 200000 },
      "buckets": [
        { "key": "2025-09", "total": 900000, "fees": 880000, "boutique": 20000, "isCurrent": false },
        { "key": "2025-10", "total": 700000, "fees": 660000, "boutique": 40000, "isCurrent": false },
        { "key": "2025-11", "total": 400000, "fees": 380000, "boutique": 20000, "isCurrent": false },
        { "key": "2025-12", "total": 150000, "fees": 140000, "boutique": 10000, "isCurrent": false },
        { "key": "2026-01", "total": 500000, "fees": 470000, "boutique": 30000, "isCurrent": false },
        { "key": "2026-02", "total": 300000, "fees": 290000, "boutique": 10000, "isCurrent": false },
        { "key": "2026-03", "total": 200000, "fees": 190000, "boutique": 10000, "isCurrent": false },
        { "key": "2026-04", "total": 100000, "fees": 90000, "boutique": 10000, "isCurrent": false },
        { "key": "2026-05", "total": 350000, "fees": 300000, "boutique": 50000, "isCurrent": true },
        { "key": "2026-06", "total": 0, "fees": 0, "boutique": 0, "isCurrent": false },
        { "key": "2026-07", "total": 0, "fees": 0, "boutique": 0, "isCurrent": false },
        { "key": "2026-08", "total": 0, "fees": 0, "boutique": 0, "isCurrent": false }
      ]
    }
  ]
}
''';

/// Ni grille tarifaire, ni catalogue, ni mouvement : **les deux tableaux sont
/// vides**, et c'est l'état vide légitime de l'écran caisse.
///
/// À ne pas confondre avec [tillLegacyByCurrencyJson], qui est vide **par
/// accident de contrat** et doit lever.
const String tillNoCurrencyJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "timeZone": "Africa/Kinshasa",
  "encaisse": [],
  "impute": []
}
''';

/// **Le corps de l'ancien contrat**, servi par un serveur pas encore déployé :
/// `byCurrency[]`, et aucune des deux clés d'aujourd'hui.
///
/// Il porte pourtant 90 000 FC bien réels. Une tolérance `?? const []` sur
/// `encaisse` en ferait un écran « aucun mouvement aujourd'hui » devant un
/// caissier qui a le tiroir plein — le mode de panne silencieux que ce lot
/// interdit. La lecture doit **lever**.
const String tillLegacyByCurrencyJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "day",
    "periodStart": "2026-05-15",
    "periodEnd": "2026-05-15",
    "generatedAt": "2026-05-15T18:04:11Z"
  },
  "timeZone": "Africa/Kinshasa",
  "byCurrency": [
    {
      "currency": "CDF",
      "summary": {
        "total": 9000000,
        "fees": 9000000,
        "boutique": 0,
        "byFeeCode": [
          { "code": "TUITION", "label": "Minerval", "amount": 9000000 }
        ]
      },
      "buckets": [
        {
          "key": "2026-05-15",
          "total": 9000000,
          "fees": 9000000,
          "boutique": 0,
          "isCurrent": true
        }
      ]
    }
  ]
}
''';

// ─────────────────────────────────────────────────────────────────────────────
// Communes aux deux routes
// ─────────────────────────────────────────────────────────────────────────────

/// Ni grille tarifaire, ni catalogue, ni mouvement : la liste est vide. Ce
/// n'est pas une erreur — c'est le refus d'afficher zéro dans une devise que
/// personne n'a choisie. Vaut pour les deux routes.
const String statsNoCurrencyJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "timeZone": "Africa/Kinshasa",
  "byCurrency": []
}
''';

/// Le même corps que [recoverySingleCurrencyJson], mais dont les montants
/// descendent en `double` — ce que fait un décodeur JSON dès qu'une plateforme
/// rend un entier flottant. Le modèle doit les accepter (`(json['x'] as num)`)
/// sans se casser ni perdre le centime.
///
/// Le code de devise y est en **minuscules** pour éprouver la normalisation du
/// même coup : elle est normalisée, jamais refusée — une devise que le serveur
/// ajouterait avant cette version du client ne doit pas faire échouer la
/// lecture de tout le tableau de bord.
const String recoveryFloatingAmountsJson = '''
{
  "context": {
    "schoolYear": "2025-2026",
    "period": "year",
    "periodStart": "2025-09-01",
    "periodEnd": "2026-08-31",
    "generatedAt": "2026-05-22T08:00:00Z"
  },
  "byCurrency": [
    {
      "currency": "usd",
      "kpis": {
        "collected": 5240000.0,
        "expected": 7820000.0,
        "outstanding": 2580000.0,
        "collectionRate": 67.0
      },
      "byFeeCode": [
        {
          "code": "TUITION",
          "label": "Minerval",
          "collected": 4100000.0,
          "expected": 6000000.0,
          "outstanding": 1900000.0,
          "collectionRate": 68.0
        }
      ],
      "monthlyCollected": {
        "granularity": "month",
        "currentBucketIndex": 8,
        "buckets": [
          { "key": "2026-05", "value": 610000.0, "isCurrent": true }
        ]
      }
    }
  ]
}
''';
