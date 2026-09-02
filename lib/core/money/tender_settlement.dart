import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';

/// Le règlement d'**une** ligne : ce qu'elle règle, et ce que le tiroir prend
/// en échange.
///
/// Une ligne est un frais au guichet, une devise de catalogue à la boutique —
/// dans les deux cas, un montant dû dans une unité, et une question : « le
/// client règle en quoi ? ». Elle se pose là, parce que c'est là qu'elle a une
/// réponse : l'unité due est le point de départ.
///
/// Un encaissement peut donc porter deux devises reçues — le modèle le sait
/// (une ligne par couple pivot/devise reçue), et aucun des deux contrats ne
/// l'interdit.
class SettlementLine {
  /// La devise de ce qui est dû — le **pivot** : celle de la créance au
  /// guichet, celle du catalogue à la boutique.
  final String settledCurrency;

  /// La devise réellement posée au comptoir.
  final String tenderCurrency;

  /// Le taux gelé, `null` quand les deux devises sont la même.
  final ExchangeRate? rate;

  /// Ce que cette ligne éteint, en centimes de [settledCurrency].
  final int settledCents;

  /// Ce que le tiroir **conserve**, en centimes de [tenderCurrency] : jamais le
  /// montant présenté. C'est exactement `réglé × taux`, sans quoi le couple
  /// perçu/réglé ne se vérifierait plus.
  final int tenderCents;

  /// Ce qui a été tendu en trop et doit être **rendu**, en centimes de
  /// [tenderCurrency]. Zéro dans le cas courant.
  final int changeCents;

  const SettlementLine({
    required this.settledCurrency,
    required this.tenderCurrency,
    required this.rate,
    required this.settledCents,
    required this.tenderCents,
    this.changeCents = 0,
  });

  /// Vrai quand une conversion s'applique — le seul cas où la ligne montre deux
  /// champs.
  bool get isConverted => rate != null;

  Money get settled => Money.parse(settledCents, settledCurrency);
  Money get tender => Money.parse(tenderCents, tenderCurrency);
}

/// Dans quelle monnaie chaque ligne est réglée, et à quel taux.
///
/// Sert les **deux caisses** : le guichet de facturation, où le pivot est la
/// devise de la créance, et la boutique, où c'est celle du catalogue. Les faire
/// vivre deux fois les ferait diverger une fois, sur de l'argent.
///
/// ## Le choix se pose sur la ligne, pas sur l'encaissement
///
/// « Le client règle comment ? » n'a de sens qu'une fois la ligne désignée : la
/// réponse dépend de la devise de CETTE ligne. Poser la question une fois pour
/// tout l'encaissement obligeait à un repli « chacun dans sa devise » que
/// personne n'a jamais demandé, et interdisait le cas réel — un minerval réglé
/// en francs, des frais d'inscription réglés en dollars, au même guichet.
///
/// ## Le cas courant ne coûte rien
///
/// Une ligne dont la devise de règlement est celle de sa créance n'a ni taux,
/// ni second champ, ni ligne de plus. C'est le défaut, et il produit exactement
/// l'écran d'avant.
///
/// ## Le guichet propose, le caissier n'invente pas
///
/// Une devise n'est proposable pour un frais que si le référentiel sait
/// convertir la devise de ce frais vers elle, à l'heure du versement. Sans
/// quoi rien ne s'affiche — plutôt qu'un champ vide où un chiffre se fabrique.
class TenderSettlement {
  /// La série de taux de l'école, telle que le référentiel la sert.
  final List<ExchangeRate> rates;

  /// L'heure métier du versement — on lit le taux qui valait alors, pas celui
  /// d'aujourd'hui.
  final DateTime at;

  /// Les taux corrigés à la main, par paire (`USD>CDF`), en micro-unités.
  ///
  /// Par paire et non global : deux lignes de devises de créance différentes
  /// n'ont pas « le » même taux, et corriger l'une ne doit rien changer à
  /// l'autre.
  final Map<String, int> overriddenRates;

  const TenderSettlement({
    this.rates = const [],
    required this.at,
    this.overriddenRates = const {},
  });

  TenderSettlement copyWith({Map<String, int>? overriddenRates}) =>
      TenderSettlement(
        rates: rates,
        at: at,
        overriddenRates: overriddenRates ?? this.overriddenRates,
      );

  /// Les devises dans lesquelles CE frais peut être réglé, la sienne d'abord.
  ///
  /// Une seule entrée ⇒ il n'y a pas de choix à offrir, et la ligne n'affiche
  /// aucun sélecteur.
  List<String> optionsFor(String settledCurrency) {
    final pivot = CurrencyCode.normalize(settledCurrency);
    if (pivot.isEmpty) return const [];
    final others = <String>{
      for (final rate in rates)
        if (rate.base == pivot && _rateFrom(pivot, rate.quote) != null)
          rate.quote,
    }.toList()..sort();
    return [pivot, ...others.where((currency) => currency != pivot)];
  }

  /// La clé d'une paire, telle qu'elle indexe [overriddenRates].
  static String pairKey(String settledCurrency, String tenderCurrency) =>
      '${CurrencyCode.normalize(settledCurrency)}>'
      '${CurrencyCode.normalize(tenderCurrency)}';

  /// Le taux appliqué à cette paire — celui du caissier s'il en a saisi un,
  /// celui de l'école sinon. `null` quand il n'y a rien à convertir ou que le
  /// référentiel ne sait pas le faire.
  ExchangeRate? rateFor(String settledCurrency, String tenderCurrency) {
    final from = CurrencyCode.normalize(settledCurrency);
    final to = CurrencyCode.normalize(tenderCurrency);
    if (from.isEmpty || to.isEmpty || from == to) return null;

    final reference = _rateFrom(from, to);
    if (reference == null) return null;

    final override = overriddenRates[pairKey(from, to)];
    if (override == null || override <= 0) return reference;
    return ExchangeRate(
      base: from,
      quote: to,
      rateMicros: override,
      effectiveFrom: reference.effectiveFrom,
      divergenceBandBp: reference.divergenceBandBp,
    );
  }

  /// Le taux **de référence** de cette paire, celui que l'école a paramétré —
  /// même quand le caissier en a saisi un autre. Second terme du contrôle de
  /// divergence.
  ExchangeRate? referenceRateFor(
    String settledCurrency,
    String tenderCurrency,
  ) => _rateFrom(
    CurrencyCode.normalize(settledCurrency),
    CurrencyCode.normalize(tenderCurrency),
  );

  /// Le règlement d'une ligne, à partir de ce qui est **imputé**.
  ///
  /// Le sens naturel du formulaire : le caissier dit quelle part de la dette il
  /// éteint, et l'écran annonce ce qu'il faut compter.
  SettlementLine fromSettled({
    required String settledCurrency,
    required String tenderCurrency,
    required int settledCents,
  }) {
    final rate = rateFor(settledCurrency, tenderCurrency);
    if (rate == null) {
      return SettlementLine(
        settledCurrency: CurrencyCode.normalize(settledCurrency),
        tenderCurrency: CurrencyCode.normalize(settledCurrency),
        rate: null,
        settledCents: settledCents,
        tenderCents: settledCents,
      );
    }
    return SettlementLine(
      settledCurrency: rate.base,
      tenderCurrency: rate.quote,
      rate: rate,
      settledCents: settledCents,
      tenderCents: ExchangeRates.convertCents(settledCents, rate),
    );
  }

  /// Le règlement d'une ligne, à partir de ce qui est **posé sur le comptoir**.
  ///
  /// L'imputation se cale au centime **inférieur** et l'excédent devient de la
  /// monnaie à rendre : 50 000 FC à 2 800 éteignent 17,85 \$ — soit 49 980 FC —
  /// et 20 FC repartent. Arrondir au plus proche éteindrait huit centimes que
  /// personne n'a posés, et le serveur refuserait le couple.
  SettlementLine fromTender({
    required String settledCurrency,
    required String tenderCurrency,
    required int tenderedCents,
  }) {
    final rate = rateFor(settledCurrency, tenderCurrency);
    if (rate == null) {
      return SettlementLine(
        settledCurrency: CurrencyCode.normalize(settledCurrency),
        tenderCurrency: CurrencyCode.normalize(settledCurrency),
        rate: null,
        settledCents: tenderedCents,
        tenderCents: tenderedCents,
      );
    }
    final allocation = ExchangeRates.settledCentsFrom(tenderedCents, rate);
    final kept = ExchangeRates.convertCents(allocation, rate);
    return SettlementLine(
      settledCurrency: rate.base,
      tenderCurrency: rate.quote,
      rate: rate,
      settledCents: allocation,
      tenderCents: kept,
      changeCents: tenderedCents - kept,
    );
  }

  /// Ce que le tiroir prend, une entrée par devise **reçue**.
  MoneyBag tenderBag(Iterable<SettlementLine> lines) =>
      MoneyBag.sumBy(lines, (line) => line.tender);

  /// Ce que ce versement éteint, une entrée par devise de **créance**.
  MoneyBag settledBag(Iterable<SettlementLine> lines) =>
      MoneyBag.sumBy(lines, (line) => line.settled);

  /// La monnaie à rendre, une entrée par devise. Vide dans le cas courant.
  MoneyBag changeBag(Iterable<SettlementLine> lines) => MoneyBag.sumBy(
    lines.where((line) => line.changeCents > 0),
    (line) => Money.parse(line.changeCents, line.tenderCurrency),
  );

  /// Les lignes de perçu à écrire — une par couple (pivot, devise reçue).
  ///
  /// Deux frais en dollars réglés tous deux en francs ne font qu'**une** ligne :
  /// on découpe quand l'unité ou le taux change, jamais quand seul le geste
  /// change. Deux frais réglés l'un en francs l'autre en dollars en font deux,
  /// parce que les unités diffèrent.
  List<TenderDraft> tendersFor(Iterable<SettlementLine> lines) {
    final byPair = <String, TenderDraft>{};
    for (final line in lines) {
      if (line.tenderCents == 0 && line.settledCents == 0) continue;
      final key = pairKey(line.settledCurrency, line.tenderCurrency);
      final known = byPair[key];
      byPair[key] = TenderDraft(
        amountInCents: (known?.amountInCents ?? 0) + line.tenderCents,
        currency: line.tenderCurrency,
        rateMicros: line.rate?.rateMicros ?? ExchangeRate.scale,
        pivotCurrency: line.settledCurrency,
      );
    }
    final keys = byPair.keys.toList()..sort();
    return [for (final key in keys) byPair[key]!];
  }

  /// Vrai quand le taux saisi pour cette paire s'écarte de celui de l'école
  /// au-delà de la bande qu'elle a paramétrée.
  ///
  /// **N'empêche rien.** L'argent est sur le comptoir ; on signale, on ne refuse
  /// pas. Mais on le signale AVANT le geste, où il se corrige encore devant le
  /// parent, plutôt qu'après, où l'arbitrage ne fait plus que constater.
  bool divergesFor(
    String settledCurrency,
    String tenderCurrency, {
    int defaultBandBp = 200,
  }) {
    final reference = referenceRateFor(settledCurrency, tenderCurrency);
    final override = overriddenRates[pairKey(settledCurrency, tenderCurrency)];
    if (reference == null || override == null || override <= 0) return false;
    final band = reference.divergenceBandBp ?? defaultBandBp;
    final gap = (override - reference.rateMicros).abs();
    return gap * 10000 > reference.rateMicros * band;
  }

  ExchangeRate? _rateFrom(String base, String quote) {
    if (base == quote) return ExchangeRate.identity(base, effectiveFrom: at);
    // Repli sur le plus ancien quand aucun point n'a commencé : c'est la règle
    // de résolution que le bundle serveur demande au client, et elle existe pour
    // l'horloge qui retarde — un guichet sans taux invente.
    return ExchangeRates.at(
      rates,
      base: base,
      quote: quote,
      moment: at,
      fallbackToEarliest: true,
    );
  }
}
