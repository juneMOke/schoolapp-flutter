import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Ce que le guichet déclare avoir **reçu**, avant que le repo ne lui donne un
/// identifiant.
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

/// L'invariant qui rend le couple perçu/imputé auditable, et la composition qui
/// va avec.
///
/// ## Ce que l'invariant dit
///
/// `Σ(allocation × taux)` par pivot `==` `Σ(tender)` de ce pivot, **comparé dans
/// la devise reçue**. C'est la même égalité que celle du serveur, prise par
/// l'autre bout : lui divise le perçu par le taux, on multiplie l'imputé. La
/// différence n'est pas cosmétique — la tolérance est définie dans la devise
/// **reçue** (« une unité d'affichage »), et comparer côté pivot obligerait à
/// convertir la tolérance elle-même.
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
abstract final class PaymentTenderComposition {
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

    for (final entry in receivedByPair.entries) {
      final tender = rateOfPair[entry.key]!;
      final pivot = CurrencyCode.normalize(tender.pivotCurrency);
      final received = CurrencyCode.normalize(tender.currency);
      final imputed = imputedByPivot[pivot] ?? 0;
      final expected = ExchangeRates.convertCents(imputed, tender.rate);
      final gap = (entry.value - expected).abs();
      final tolerance = MoneyFormat.displayUnitInCents(received);
      if (gap > tolerance) {
        return TenderInvariantViolation(
          'Perçu (${entry.value} $received) ≠ imputé converti '
          '($expected $received) au taux ${tender.rate.rateForDisplay} : '
          'écart de $gap centimes, au-delà de la tolérance de $tolerance.',
        );
      }
    }

    return null;
  }
}
