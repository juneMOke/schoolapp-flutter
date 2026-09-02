import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';

/// Le taux de guichet qui relie **ce qui est perçu** à **ce qui est imputé**.
///
/// ## Pourquoi un entier, et pas un `double`
///
/// Le serveur stocke `numeric(18,6)` : six décimales, c'est exactement une
/// **micro-unité**. On porte donc `rate × 1 000 000` en `int`, pour la raison
/// qui vaut déjà sur [Money] — un `double` qui traverse la couche métier finit
/// par arrondir de l'argent, et ici il l'arrondirait avant même de l'écrire.
///
/// ## Le sens du taux
///
/// [base] est la devise de la **créance** — le pivot, au sens de la colonne
/// `pivot_currency` du serveur. [quote] est la devise **reçue**. `1 666,67`
/// avec `base: USD, quote: CDF` se lit « un dollar de créance s'éteint contre
/// 1 666,67 francs reçus ».
///
/// Le pivot est la devise de la créance et non une référence unique de l'école
/// (arbitrage n° 5 du plan back) : c'est la seule orientation qui rende
/// l'invariant vérifiable sans table de passage.
///
/// ## Les centimes se convertissent tels quels
///
/// Les deux devises sont stockées en centimes, donc le facteur est le même que
/// sur les unités : `centsReçus = centsCréance × taux`. 30,00 $ valent `3000` ;
/// `3000 × 1 666,67 = 5 000 010` centimes de franc, soit **50 000,10 FC** — le
/// chiffre exact que cite l'arbitrage n° 3. Le franc s'affiche sans décimales
/// mais se stocke en centimes, et c'est pour cela que la tolérance existe.
final class ExchangeRate extends Equatable {
  /// Un taux exprimé en micro-unités : `1 666,67` s'écrit `1666670000`.
  static const int scale = 1000000;

  /// La devise de la créance — le pivot.
  final String base;

  /// La devise reçue au guichet.
  final String quote;

  /// `taux × 1 000 000`, jamais un flottant.
  final int rateMicros;

  /// Depuis quand ce taux vaut. Une **série**, jamais une valeur remplacée en
  /// place : une école qui change de taux à midi n'est pas un cas d'école, et
  /// un versement encaissé hors ligne remonte parfois trois jours plus tard.
  final DateTime effectiveFrom;

  /// Bande de divergence tolérée, en points de base (200 = 2 %), telle que
  /// l'école la paramètre. `null` quand le référentiel ne la porte pas — le
  /// contrôle retombe alors sur le défaut de l'appelant, jamais sur zéro, qui
  /// signalerait tout.
  final int? divergenceBandBp;

  const ExchangeRate({
    required this.base,
    required this.quote,
    required this.rateMicros,
    required this.effectiveFrom,
    this.divergenceBandBp,
  });

  /// Taux venu d'une frontière — JSON, SQL, saisie : les devises y sont
  /// normalisées, comme sur [Money.parse].
  factory ExchangeRate.parse({
    required String base,
    required String quote,
    required int rateMicros,
    required DateTime effectiveFrom,
    int? divergenceBandBp,
  }) => ExchangeRate(
    base: CurrencyCode.normalize(base),
    quote: CurrencyCode.normalize(quote),
    rateMicros: rateMicros,
    effectiveFrom: effectiveFrom,
    divergenceBandBp: divergenceBandBp,
  );

  /// Le taux du cas courant : perçu = imputé, donc `1`.
  ///
  /// C'est ce que porte chaque ligne d'encaissement d'avant la V2, et ce que le
  /// backfill écrit sur tout l'historique. Il n'y a **pas** de « pas de taux »
  /// dans la table : il y a un taux de 1.
  factory ExchangeRate.identity(String currency, {DateTime? effectiveFrom}) {
    final code = CurrencyCode.normalize(currency);
    return ExchangeRate(
      base: code,
      quote: code,
      rateMicros: scale,
      effectiveFrom: effectiveFrom ?? DateTime.utc(1970),
    );
  }

  /// Vrai quand perçu et imputé sont dans la même unité au même montant.
  bool get isIdentity => rateMicros == scale && base == quote;

  /// Le taux tel qu'il s'affiche et s'imprime — deux décimales.
  ///
  /// La saisie est contrainte au centième (décision d'interface n° 3) pour que
  /// l'imprimé et le stocké soient le **même** nombre : le parent recompte le
  /// ticket, et un taux arrondi à l'affichage ne le ferait pas retomber sur son
  /// total.
  double get rateForDisplay => rateMicros / scale;

  /// Le taux écrit : « 1 666,67 ».
  ///
  /// Passe par [MoneyFormat] pour le groupement des milliers et la virgule
  /// décimale, mais **sans devise** : un taux n'est pas un montant, il ne suit
  /// pas la règle d'écriture du franc, qui lui retirerait ses décimales.
  ///
  /// Une seule implémentation, parce que ce nombre s'affiche au guichet ET
  /// s'imprime sur le ticket : deux copies divergeraient au premier ajustement,
  /// et le parent lirait deux taux pour un seul versement.
  /// Le taux rendu au centième, **arrondi et non tronqué**.
  ///
  /// La colonne stocke six décimales ; l'écran et le ticket en montrent deux.
  /// Tronquer faisait imprimer 1 666,66 pour un taux de 1 666,666 7 — un
  /// centime SOUS ce qui a servi au calcul, et le parent qui recompte ne
  /// retombe pas sur son total. C'est précisément l'invariant que le ticket
  /// promet.
  String formatted({String space = MoneyFormat.nbsp}) => MoneyFormat.amountOnly(
    Money(((rateMicros / (scale ~/ 100)).round()), ''),
    space: space,
  );

  @override
  List<Object?> get props => [
    base,
    quote,
    rateMicros,
    effectiveFrom,
    divergenceBandBp,
  ];

  @override
  String toString() =>
      'ExchangeRate($base→$quote ${rateMicros / scale} @$effectiveFrom)';
}

/// Ce qu'on fait d'une série de taux : la lire à une date, et convertir.
abstract final class ExchangeRates {
  /// Le taux qui vaut **à cette date** pour cette paire, `null` s'il n'y en a
  /// aucun.
  ///
  /// `null` est un état normal, jamais une erreur : une lecture ne remonte
  /// jamais d'erreur, et l'écran taira la bascule de devise plutôt que
  /// d'appliquer un 1 par défaut, qui écrirait un tender faux.
  ///
  /// La borne est **inclusive** : un taux qui prend effet à 12:00 vaut pour un
  /// versement horodaté 12:00. La comparaison se fait en UTC — deux instants
  /// venus de fuseaux différents ne se comparent pas autrement.
  static ExchangeRate? at(
    Iterable<ExchangeRate> rates, {
    required String base,
    required String quote,
    required DateTime moment,
    bool fallbackToEarliest = false,
  }) {
    final wantedBase = CurrencyCode.normalize(base);
    final wantedQuote = CurrencyCode.normalize(quote);
    final instant = moment.toUtc();

    ExchangeRate? best;
    ExchangeRate? earliest;
    for (final rate in rates) {
      if (rate.base != wantedBase || rate.quote != wantedQuote) continue;
      final from = rate.effectiveFrom.toUtc();
      // Le plus ancien de la paire, retenu au cas où AUCUN point n'aurait
      // commencé — voir le repli ci-dessous.
      if (earliest == null || from.isBefore(earliest.effectiveFrom.toUtc())) {
        earliest = rate;
      }
      if (from.isAfter(instant)) continue;
      if (best == null || from.isAfter(best.effectiveFrom.toUtc())) {
        best = rate;
      }
    }
    // ⚠️ **Aucun point commencé ⇒ le plus ancien, mais seulement pour qui le
    // demande.**
    //
    // Le serveur ne descend que les points résolvables : celui en vigueur, et
    // ceux datés au-delà. Une tablette dont l'horloge RETARDE sur la sienne voit
    // donc tous les points dans son futur — et sans repli elle n'aurait plus
    // aucun taux, alors qu'elle vient d'en recevoir une série complète. Un
    // guichet sans taux invente, et un taux inventé est exactement ce que le
    // contrôle de divergence lui reprocherait.
    //
    // Le repli se **demande** et n'est pas le défaut : il a un revers — un
    // premier taux programmé pour demain s'applique dès aujourd'hui — que seul
    // le guichet a intérêt à payer. L'écran de direction, lui, doit dire la
    // vérité stricte : « aucun taux en vigueur » est une information juste.
    if (best != null || !fallbackToEarliest) return best;
    return earliest;
  }

  /// Ce que [pivotCents] — un montant dans la devise de la créance — vaut dans
  /// la devise reçue.
  ///
  /// Arrondi **au plus proche, la moitié s'éloignant de zéro**, et jamais la
  /// troncature implicite de `~/` : arrondir toujours vers le bas ferait perdre
  /// un centime au parent à chaque ligne, systématiquement dans le même sens.
  ///
  /// Le produit passe par [BigInt]. Un montant de dix millions de dollars en
  /// centimes multiplié par un taux en micro-unités approche les 2×10¹⁸ — sous
  /// le plafond d'un `int` 64 bits, mais de trop peu pour qu'on parie dessus
  /// sur de l'argent. Le coût est nul à l'échelle d'un écran.
  static int convertCents(int pivotCents, ExchangeRate rate) {
    if (rate.rateMicros == ExchangeRate.scale) return pivotCents;
    final negative = pivotCents < 0;
    final absolute = BigInt.from(negative ? -pivotCents : pivotCents);
    final scale = BigInt.from(ExchangeRate.scale);
    final product =
        absolute * BigInt.from(rate.rateMicros) + (scale ~/ BigInt.two);
    final result = (product ~/ scale).toInt();
    return negative ? -result : result;
  }

  /// Le montant [amount], exprimé dans la devise reçue de [rate].
  ///
  /// La devise du résultat est celle du taux, pas celle de l'entrée : c'est
  /// tout l'objet de l'opération.
  static Money convert(Money amount, ExchangeRate rate) =>
      Money(convertCents(amount.amountInCents, rate), rate.quote);

  /// Ce qu'un montant **tendu** peut éteindre, exprimé dans la devise de la
  /// créance — l'opération inverse de [convertCents].
  ///
  /// **Arrondi vers le bas, jamais au plus proche.** Une créance ne s'éteint
  /// que jusqu'où l'argent va : 50 000 FC à 2 800 valent 17,857… \$, on impute
  /// 17,85 et non 17,86 — arrondir au plus proche éteindrait huit centimes que
  /// personne n'a posés sur le comptoir, et le serveur refuserait le couple
  /// (l'écart dépasse l'unité d'affichage tolérée).
  ///
  /// Ce qui reste — ici 20 FC — est de la **monnaie à rendre**, pas un
  /// trop-perçu : le tender est le net conservé.
  static int settledCentsFrom(int tenderedCents, ExchangeRate rate) {
    if (rate.rateMicros <= 0) return 0;
    if (rate.rateMicros == ExchangeRate.scale) return tenderedCents;
    final negative = tenderedCents < 0;
    final absolute = BigInt.from(negative ? -tenderedCents : tenderedCents);
    final result =
        (absolute *
                BigInt.from(ExchangeRate.scale) ~/
                BigInt.from(rate.rateMicros))
            .toInt();
    return negative ? -result : result;
  }
}
