/// Ce que le guichet **lit** d'un règlement : des chiffres, jamais un geste.
///
/// Lot R4 du chantier de refonte. Ces fonctions vivaient dans la classe `State`
/// de la page d'encaissement alors qu'elles ne touchent à rien : on leur donne
/// un règlement et les lignes de saisie, elles rendent un montant, un sac de
/// devises ou un booléen.
///
/// **Aucun comportement n'a changé en les déplaçant** — y compris le fait que
/// les lignes soient recalculées à chaque appel. C'était vrai avant, ça reste
/// vrai : optimiser en passant des lignes déjà calculées serait un changement de
/// comportement glissé dans un lot de déplacement, et on ne saurait plus
/// attribuer un test rouge.
library;

import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';

/// Le règlement d'une ligne : ce qu'elle éteint, ce que le tiroir garde, et ce
/// qui repart avec le parent.
///
/// **Le champ que le caissier vient de taper fait foi.** S'il a saisi le montant
/// posé sur le comptoir, l'imputation se déduit vers le bas et l'excédent
/// devient de la monnaie à rendre ; s'il a saisi l'imputation, le comptoir en
/// découle exactement.
SettlementLine lineOf(
  TenderSettlement settlement,
  FacturationChargeEntry entry,
) {
  final target = entry.effectiveTenderCurrency;
  if (entry.isConverted && entry.tenderIsSource) {
    final line = settlement.fromTender(
      settledCurrency: entry.charge.currency,
      tenderCurrency: target,
      tenderedCents: entry.tenderedCents,
    );
    if (line.settledCents <= entry.remainingInCents) return line;
    // Le parent a posé plus que ce que ce frais doit : on n'impute pas au-delà
    // du restant, et le surplus repart avec lui. Le porter en imputation
    // fabriquerait un trop-perçu que personne n'a décidé.
    final capped = settlement.fromSettled(
      settledCurrency: entry.charge.currency,
      tenderCurrency: target,
      settledCents: entry.remainingInCents,
    );
    return SettlementLine(
      settledCurrency: capped.settledCurrency,
      tenderCurrency: capped.tenderCurrency,
      rate: capped.rate,
      settledCents: capped.settledCents,
      tenderCents: capped.tenderCents,
      changeCents: entry.tenderedCents - capped.tenderCents,
    );
  }
  return settlement.fromSettled(
    settledCurrency: entry.charge.currency,
    tenderCurrency: target,
    settledCents: entry.effectiveCents,
  );
}

/// Les lignes retenues — celles qui portent un montant d'un côté ou de l'autre.
List<SettlementLine> linesOf(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) => [
  for (final entry in entries)
    if (entry.selected && (entry.effectiveCents > 0 || entry.tenderedCents > 0))
      lineOf(settlement, entry),
];

/// Le total **imputé**, par devise de créance — ce que ce versement éteint.
///
/// C'était un entier unique, sommé sur toutes les lignes retenues, étiqueté avec
/// la première devise non vide rencontrée. Un versement soldant 425,00 \$ et
/// 90 000 FC s'affichait « 9 042 500 USD » — sur le bandeau or, sur le ticket
/// remis au parent, et dans le payload envoyé au serveur.
MoneyBag settledBagOf(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) => settlement.settledBag(linesOf(settlement, entries));

/// Ce que le tiroir prend, par devise **reçue**.
MoneyBag tenderBagOf(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) => settlement.tenderBag(linesOf(settlement, entries));

/// Vrai quand au moins une ligne convertit : c'est ce qui décide d'annoncer le
/// perçu en tête de la barre.
///
/// « Converti » n'est pas « une devise a été choisie » : régler en dollars des
/// créances en dollars n'est pas une conversion.
bool hasConversion(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) => linesOf(settlement, entries).any((line) => line.isConverted);

/// Ce que le tiroir conserve pour cette nature : la somme de ce que ses tranches
/// y font entrer — donc exactement ce que `tendersFor` agrégera.
int groupTenderCents(
  TenderSettlement settlement,
  FacturationChargeGroupEntry group,
) {
  if (!group.isConverted) return 0;
  var total = 0;
  for (final tranche in group.tranches) {
    if (tranche.effectiveCents <= 0) continue;
    total += lineOf(settlement, tranche).tenderCents;
  }
  return total;
}

/// Vrai quand le couple perçu/imputé ne tient pas — le CTA s'éteint alors.
///
/// La garde est celle du chemin d'écriture, éprouvée pendant la SAISIE : un
/// refus après le geste se lit comme une panne alors que c'est une saisie à
/// corriger.
bool tenderInvariantBroken(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) {
  final lines = linesOf(settlement, entries);
  if (lines.isEmpty) return false;
  return TenderComposition.check(
        allocations: settlement.settledBag(lines).entries,
        tenders: settlement.tendersFor(lines),
      ) !=
      null;
}

/// Vrai quand un frais est retenu et qu'AUCUN ne peut se régler dans une autre
/// monnaie.
///
/// C'est la seule situation où « aucun taux paramétré » est vrai : sans frais
/// coché il n'y a pas encore de question, et avec une devise proposable la
/// bascule est là, sur la ligne.
bool hasNoConvertibleCharge(
  TenderSettlement settlement,
  Iterable<FacturationChargeEntry> entries,
) {
  final retained = entries.where((entry) => entry.selected);
  if (retained.isEmpty) return false;
  return retained.every(
    (entry) => settlement.optionsFor(entry.charge.currency).length < 2,
  );
}
