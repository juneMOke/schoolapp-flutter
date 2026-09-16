/// Ce que la page d'encaissement **écrit à l'écran** — et rien d'autre.
///
/// Lot R1 du chantier de refonte : ces fonctions vivaient dans la classe `State`
/// de `facturation_create_payment_page.dart`, où elles ne faisaient qu'ajouter
/// des lignes à un fichier qui en portait déjà 1 208. Elles n'ont besoin
/// d'aucun état : on leur donne ce qu'il y a à rendre, elles rendent une chaîne.
///
/// **Aucun comportement n'a changé en les déplaçant.** Trois duplications ont en
/// revanche disparu au passage, et c'est le vrai gain :
///
/// - l'expression du taux était écrite **trois fois à l'identique** (ligne,
///   nature, récapitulatif) — c'est [rateLabel] ;
/// - la monnaie à rendre, **deux fois** (ligne, nature) — c'est [changeLabel] ;
/// - ce que le tiroir conserve, **deux fois** — c'est [tenderLabel].
///
/// Trois écritures d'un même nombre qui divergent, c'est le parent qui recompte
/// au guichet et ne retombe pas sur son total.
library;

import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
// `formatMonetaryAmountWithCurrency` vit avec le champ de saisie monétaire, et
// non dans les utilitaires de la facturation : c'est le socle qui sait écrire un
// montant dans sa devise.
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un montant en cents, rendu dans sa devise.
String moneyLabel(int cents, String currency) =>
    formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

/// Un total rendu sur une ligne — les devises séparées, **jamais sommées**.
///
/// Un versement soldant 425,00 \$ et 90 000 FC se lit « 425,00 $ · 90 000 FC ».
/// Les additionner donnerait un nombre qui n'existe pas.
String bagLabel(MoneyBag bag) =>
    bag.entries.map(MoneyFormat.format).join(' · ');

/// Un taux, rendu « 2 800 FC / \$ ».
///
/// **Une seule implémentation**, partagée par la ligne, la nature et le
/// récapitulatif : c'est le chiffre que le parent conteste au comptoir, il doit
/// s'écrire pareil partout.
String rateLabel(ExchangeRate rate) =>
    '${rate.formatted()} ${MoneyFormat.symbolOf(rate.quote)} / '
    '${MoneyFormat.symbolOf(rate.base)}';

/// Le taux appliqué à cette ligne — `null` quand elle ne convertit pas.
String? lineRateLabel(SettlementLine line) {
  final rate = line.rate;
  return rate == null ? null : rateLabel(rate);
}

/// Ce qui repart avec le parent **sur cette ligne** — `null` quand la conversion
/// tombe juste.
///
/// Pendant du couple [lineRateLabel] : une ligne porte déjà sa monnaie à rendre
/// dans `changeCents`, là où une nature doit la calculer. Les deux finissent
/// dans [changeLabel], qui écrit la phrase une seule fois.
String? lineChangeLabel(SettlementLine line, AppLocalizations l10n) =>
    changeLabel(line.changeCents, line.tenderCurrency, l10n);

/// Le taux du versement entier — `null` **dès qu'il y en a plusieurs**.
///
/// Le récapitulatif valide UN montant : y poser deux taux les ferait lire comme
/// un seul. Chaque ligne porte alors le sien, là où il s'applique.
String? singleRateLabel(Iterable<SettlementLine> lines) {
  final rates = <String>{
    for (final line in lines)
      if (line.rate case final rate?) rateLabel(rate),
  };
  return rates.length == 1 ? rates.single : null;
}

/// Ce que le tiroir conserve, rendu — `null` quand il n'y a rien à annoncer.
String? tenderLabel(int keptCents, String tenderCurrency) =>
    keptCents <= 0 ? null : moneyLabel(keptCents, tenderCurrency);

/// Ce qu'une ligne fait entrer dans le tiroir — `null` si elle ne convertit pas.
String? tenderLabelOf(SettlementLine line) => line.isConverted
    ? tenderLabel(line.tenderCents, line.tenderCurrency)
    : null;

/// Ce qui repart avec le parent, rendu — `null` quand la conversion tombe juste.
///
/// Prend des **cents déjà calculés** : une ligne les tient dans
/// `changeCents`, une nature les obtient en retranchant ce que le tiroir garde
/// de ce que le parent a posé. Les deux sources diffèrent, la phrase non.
String? changeLabel(
  int changeCents,
  String tenderCurrency,
  AppLocalizations l10n,
) => changeCents <= 0
    ? null
    : l10n.facturationCreatePaymentChangeDue(
        moneyLabel(changeCents, tenderCurrency),
      );

/// L'élève, nommé comme la fiche le nomme. Replié sur « inconnu » plutôt que sur
/// une chaîne vide : un encaissement sans nom d'élève se dit.
String studentFullName(
  FacturationCreatePaymentIntent intent,
  AppLocalizations l10n,
) {
  final name = [
    intent.lastName,
    intent.surname,
    intent.firstName,
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' ');
  return name.isEmpty ? l10n.facturationDetailUnknownValue : name;
}

/// La classe du sur-titre « Encaissement · {classe} », comme sur la fiche d'où
/// l'on vient : le niveau s'il est connu, le cycle sinon.
String classLabel(
  FacturationCreatePaymentIntent intent,
  AppLocalizations l10n,
) {
  final value = intent.levelName.trim().isNotEmpty
      ? intent.levelName.trim()
      : intent.levelGroupName.trim();
  return value.isEmpty ? l10n.facturationDetailUnknownValue : value;
}
