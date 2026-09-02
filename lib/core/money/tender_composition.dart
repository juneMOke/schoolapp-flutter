import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Ce qu'un comptoir déclare avoir **reçu**, avant que le repo ne lui donne un
/// identifiant.
///
/// Vit dans le socle monétaire et non dans la Facturation : la caisse boutique
/// pose exactement la même question — « qu'est-ce qui est entré dans le tiroir,
/// à côté de ce que ça a réglé » — et son pivot est la devise du catalogue là où
/// celui du versement est la devise de la créance. Le loger dans l'un des deux
/// modules obligerait l'autre à en dépendre.
///
/// Une entrée par couple (devise reçue, pivot) : on découpe quand l'unité ou le
/// taux change, **jamais quand seul le geste change**. Un parent qui pose
/// 100 000 FC puis complète par 12 000 FC au même guichet et au même taux
/// produit UNE ligne de 112 000 FC — ce découpage-là décrit une pile de billets,
/// pas une décision.
class TenderDraft {
  /// Le **net conservé**, jamais le montant présenté.
  final int amountInCents;

  /// La devise reçue.
  final String currency;

  /// Le taux de guichet appliqué, en micro-unités.
  final int rateMicros;

  /// La devise de la créance que ce règlement éteint.
  final String pivotCurrency;

  const TenderDraft({
    required this.amountInCents,
    required this.currency,
    this.rateMicros = ExchangeRate.scale,
    required this.pivotCurrency,
  });

  /// Le taux gelé de ce règlement, prêt à convertir une imputation.
  ExchangeRate get rate => ExchangeRate.parse(
    base: pivotCurrency,
    quote: currency,
    rateMicros: rateMicros,
    effectiveFrom: DateTime.utc(1970),
  );
}

/// Pourquoi un couple perçu/imputé a été refusé.
///
/// Le message est destiné au diagnostic, pas au parent : l'écran a déjà dit ce
/// qu'il fallait avant qu'on en arrive là.
class TenderInvariantViolation {
  final String message;

  const TenderInvariantViolation(this.message);

  @override
  String toString() => message;
}

/// L'invariant qui rend le couple perçu/réglé auditable, et la composition qui
/// va avec.
///
/// Vaut pour un **versement** (pivot = devise de la créance) comme pour une
/// **vente** (pivot = devise du catalogue) : c'est la même égalité, et la faire
/// vivre deux fois la ferait diverger une fois.
///
/// ## Ce que l'invariant dit
///
/// `Σ(tender ÷ taux)` par pivot `==` `Σ(allocation)` de ce pivot, **comparé
/// dans la devise de la créance**. Mot pour mot la règle du serveur
/// (`Encaissements.exigerInvariant`) : côté créance, pivot par pivot, jamais
/// globalement — compenser un excédent en dollars par un manque en francs est
/// précisément l'erreur que ce contrôle existe pour voir.
///
/// ## La tolérance, et pourquoi elle n'a pas besoin d'unité commune
///
/// `Σ max(1, unité d'affichage de la devise REÇUE ÷ taux)`, **une par ligne
/// d'encaissement**.
///
/// L'écart naît là où l'arrondi se produit : le parent pose 50 000 FC ronds,
/// pas 50 000,10 — donc dans la devise reçue. On l'y borne, puis chaque ligne
/// le porte au pivot par **son** taux. Aucune unité reçue commune n'est donc
/// nécessaire, même quand une créance est réglée en deux monnaies : chaque
/// règlement apporte la sienne.
///
/// Le plancher d'un centime de pivot fait tout le travail dans le sens
/// dominant : une créance en dollars réglée en francs admet
/// `max(1, 100 ÷ 2900) = 1` centime. Dans l'autre sens il ne sert pas, et c'est
/// ce qui compte : une créance en francs réglée en dollars admet
/// `1 ÷ 0,000435 ≈ 2 299` centimes de franc, là où un centime forfaitaire
/// refuserait un versement que le serveur accepte sans broncher.
///
/// ## À ne pas confondre avec la bande du taux
///
/// Deux tolérances, deux unités, deux conséquences. Celle-ci porte sur
/// l'**arrondi de conversion**, se compte en centimes, et un dépassement
/// **refuse** le versement (422 `TENDER_SUM_MISMATCH`). La bande de
/// [ExchangeRate.divergenceBandBp] porte sur l'**écart au taux publié**, se
/// compte en pourcent, et ne refuse jamais rien — elle consigne une anomalie.
/// Les fusionner ferait refuser des versements justes, ou taire un vrai écart
/// d'arbitrage.
///
/// ## Pourquoi une tolérance
///
/// Le franc s'affiche sans décimales mais se stocke en centimes : 30,00 $ à
/// 1 666,67 donnent 50 000,10 FC, pour un tiroir qui a vu 50 000 FC. Refuser
/// l'écart, c'est refuser des versements justes.
///
/// ## Ce que ça n'est pas
///
/// Ce n'est **pas** la garde qui compare `amounts` aux imputations. Celle-là
/// compare de l'imputé à de l'imputé et reste juste ; celle-ci est la seconde,
/// et elle n'existait nulle part.
abstract final class TenderComposition {
  /// L'écart admis pour UNE ligne d'encaissement, en centimes de pivot.
  ///
  /// `max(1, unité d'affichage de la devise reçue ÷ taux)` — la formule du
  /// serveur, au même arrondi.
  ///
  /// ⚠️ **Arrondi au plus proche, et non le plancher de
  /// [ExchangeRates.settledCentsFrom].** Les deux conversions inverses ne
  /// servent pas la même chose : à la SAISIE, tronquer est juste — on n'éteint
  /// que ce que l'argent couvre, le reste est de la monnaie à rendre. Ici on
  /// mesure une tolérance, et tronquer la rendrait plus stricte que celle du
  /// serveur d'un centime, sans raison.
  static int _lineToleranceInPivot(TenderDraft tender) {
    final unit = MoneyFormat.displayUnitInCents(tender.currency);
    final micros = BigInt.from(tender.rateMicros);
    if (micros <= BigInt.zero) return 1;
    final scaled = BigInt.from(unit) * BigInt.from(ExchangeRate.scale);
    final rounded = ((scaled + micros ~/ BigInt.two) ~/ micros).toInt();
    return rounded < 1 ? 1 : rounded;
  }

  /// Les lignes de perçu d'un versement dont le règlement suit exactement les
  /// imputations : une par devise, taux 1.
  ///
  /// C'est le cas courant — le parent règle dans la devise de la créance — et il
  /// ne coûte aucune arithmétique.
  static List<TenderDraft> identityFor(Iterable<Money> allocations) {
    final byCurrency = <String, int>{};
    for (final allocation in allocations) {
      final currency = CurrencyCode.normalize(allocation.currency);
      byCurrency[currency] =
          (byCurrency[currency] ?? 0) + allocation.amountInCents;
    }
    final currencies = byCurrency.keys.toList()..sort();
    return [
      for (final currency in currencies)
        TenderDraft(
          amountInCents: byCurrency[currency]!,
          currency: currency,
          pivotCurrency: currency,
        ),
    ];
  }

  /// Vérifie le couple perçu/imputé, `null` quand il tient.
  ///
  /// Trois refus, et chacun décrit une situation réelle :
  ///
  ///  - **un pivot imputé sans aucun règlement** — de l'argent aurait éteint
  ///    une dette sans être jamais entré dans le tiroir ;
  ///  - **un règlement dont le pivot n'est imputé nulle part** — l'inverse : de
  ///    l'argent reçu contre une créance qui n'est pas dans ce versement ;
  ///  - **un écart au-delà de la tolérance** — le taux ne relie pas les deux.
  ///
  /// Un taux nul ou négatif est refusé avec le premier : il diviserait ou
  /// inverserait de l'argent.
  static TenderInvariantViolation? check({
    required Iterable<Money> allocations,
    required Iterable<TenderDraft> tenders,
  }) {
    final imputedByPivot = <String, int>{};
    for (final allocation in allocations) {
      final currency = CurrencyCode.normalize(allocation.currency);
      imputedByPivot[currency] =
          (imputedByPivot[currency] ?? 0) + allocation.amountInCents;
    }

    // Regroupé par (pivot, devise reçue) : deux lignes de même pivot et de même
    // unité s'additionnent avant d'être confrontées, sans quoi un versement en
    // deux temps au même taux serait refusé alors qu'il est juste.
    final receivedByPair = <String, int>{};
    final rateOfPair = <String, TenderDraft>{};
    for (final tender in tenders) {
      final pivot = CurrencyCode.normalize(tender.pivotCurrency);
      final received = CurrencyCode.normalize(tender.currency);
      if (tender.rateMicros <= 0) {
        return TenderInvariantViolation(
          'Taux de guichet invalide (${tender.rateMicros}) sur le règlement en '
          '$received.',
        );
      }
      if (!imputedByPivot.containsKey(pivot)) {
        return TenderInvariantViolation(
          'Règlement en $received adossé à une créance en $pivot, qui n\'est '
          'imputée nulle part dans ce versement.',
        );
      }
      final key = '$pivot>$received';
      receivedByPair[key] = (receivedByPair[key] ?? 0) + tender.amountInCents;
      final known = rateOfPair[key];
      if (known != null && known.rateMicros != tender.rateMicros) {
        // Deux taux pour la même paire dans un même versement : le modèle sait
        // le représenter, mais c'est soit une faute de saisie, soit un
        // arrangement. On refuse en local — l'écran n'a aucune raison d'en
        // produire deux, et le laisser passer ferait remonter un arbitrage que
        // le guichet aurait pu éviter.
        return TenderInvariantViolation(
          'Deux taux différents pour $pivot→$received dans le même versement '
          '(${known.rateMicros} et ${tender.rateMicros}).',
        );
      }
      rateOfPair[key] = tender;
    }

    for (final pivot in imputedByPivot.keys) {
      final pairs = rateOfPair.keys.where((key) => key.startsWith('$pivot>'));
      if (pairs.isEmpty) {
        return TenderInvariantViolation(
          'Rien n\'a été reçu contre les créances en $pivot de ce versement.',
        );
      }
    }

    // Le contrôle, pivot par pivot, **côté créance** — la règle du serveur.
    for (final pivot in imputedByPivot.keys) {
      final imputed = imputedByPivot[pivot]!;
      final keys = rateOfPair.keys
          .where((key) => key.startsWith('$pivot>'))
          .toList();

      var settled = 0;
      var tolerance = 0;
      for (final key in keys) {
        final tender = rateOfPair[key]!;
        settled += ExchangeRates.settledCentsFrom(
          receivedByPair[key]!,
          tender.rate,
        );
        tolerance += _lineToleranceInPivot(tender);
      }

      final gap = (settled - imputed).abs();
      if (gap > tolerance) {
        return TenderInvariantViolation(
          'Perçu converti ($settled $pivot) ≠ dû ($imputed $pivot) : écart de '
          '$gap centimes, $tolerance admis.',
        );
      }
    }

    return null;
  }
}
