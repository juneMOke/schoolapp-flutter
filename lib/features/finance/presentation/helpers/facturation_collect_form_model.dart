/// L'état de saisie d'un encaissement, hors rendu : ce que le caissier a coché,
/// tapé, converti — et les règles qui font évoluer tout cela.
///
/// Lot R5 du chantier de refonte, et le seul qualifié de délicat. Ces gestes
/// vivaient dans la classe `State` de la page, mêlés au cycle de vie d'un
/// widget ; ils n'en avaient jamais eu besoin.
///
/// ## Le règlement n'est PAS mémorisé — piège P1
///
/// [settlementOf] est un **rappel**, pas un champ. Le modèle demande le
/// règlement chaque fois qu'il en a besoin, et ne le garde jamais.
///
/// Ce n'est pas un scrupule de style : `ExchangeRatesCubit` charge la série de
/// taux en **asynchrone** et reconstruit la vue. Un modèle qui capterait les taux
/// à sa construction convertirait de l'argent au taux d'une série périmée, sans
/// que rien ne le signale. La dépendance n'existe pas, il n'y a donc rien à se
/// rappeler de ne pas faire.
///
/// ## Le rendu appartient à la page — piège P2
///
/// Aucune méthode d'ici n'appelle `setState`. Les gestes mutent, la page
/// enveloppe. C'est elle qui sait quand se redessiner ; le modèle sait seulement
/// ce qui a changé.
library;

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_rate_board.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_settlement_reads.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';

/// Ce que le guichet s'apprête à encaisser — **en types de domaine seulement**.
///
/// Ni widget, ni BLoC : `PaymentsCreateRequested` est déclarée dans un `part` de
/// `payments_bloc.dart` et n'est pas importable seule. La faire entrer ici
/// ferait entrer le BLoC entier dans un modèle qui n'en a pas besoin, et
/// alourdirait des tests qui s'exécutent aujourd'hui en quelques millisecondes.
///
/// C'est donc la page qui assemble l'événement à partir de ceci : la dépendance
/// au BLoC reste là où elle appartient.
class FacturationCollectDraft {
  /// Ce qui est **imputé**, par devise de créance.
  final MoneyBag amounts;

  /// Ce qui **entre dans le tiroir**, une entrée par couple de devises.
  final List<TenderDraft> tenders;

  final List<CreatePaymentAllocationInput> allocations;

  /// Le **jour** désigné. L'heure du geste lui sera rendue au moment d'écrire,
  /// dans le fuseau de l'école.
  final DateTime paidAt;

  const FacturationCollectDraft({
    required this.amounts,
    required this.tenders,
    required this.allocations,
    required this.paidAt,
  });
}

class FacturationCollectFormModel {
  /// Les lignes payables — ce qui porte les contrôleurs, ce qui est disposé, et
  /// surtout ce qui produit les imputations envoyées au serveur.
  final List<FacturationChargeEntry> entries;

  /// Les natures, repliées sur les mêmes entrées.
  ///
  /// ⚠️ **Une vue, pas une seconde liste de vérité.** La requête sortante d'une
  /// saisie groupée est identique à celle d'une saisie tranche par tranche.
  final List<FacturationChargeGroupEntry> groups;

  /// Les taux corrigés à la main. Injecté : il est né en R3 et la page le
  /// construit.
  final FacturationRateBoard rates;

  /// Le règlement courant, **demandé à chaque usage** (cf. P1 ci-dessus).
  final TenderSettlement Function() settlementOf;

  /// L'horloge. Injectée pour que les tests puissent fixer le jour.
  final DateTime Function() nowOf;

  FacturationCollectFormModel({
    required this.entries,
    required this.groups,
    required this.rates,
    required this.settlementOf,
    required this.nowOf,
  });

  /// Construit le modèle à partir des créances de l'élève : seules celles qui
  /// restent dues entrent dans la saisie.
  factory FacturationCollectFormModel.fromCharges({
    required Iterable<StudentCharge> charges,
    required FacturationRateBoard rates,
    required TenderSettlement Function() settlementOf,
    required DateTime Function() nowOf,
  }) {
    final entries = [
      for (final charge in charges)
        if (chargeRemainingInCents(charge) > 0) FacturationChargeEntry(charge),
    ];
    return FacturationCollectFormModel(
      entries: entries,
      groups: groupPayableEntries(entries),
      rates: rates,
      settlementOf: settlementOf,
      nowOf: nowOf,
    );
  }

  // ── Le jour du versement (A1) ──────────────────────────────────────────────

  DateTime? _paidDayOverride;

  /// Le jour courant de l'ÉCOLE — et non celui de la tablette : c'est le fuseau
  /// de Kinshasa qui découpe les journées de caisse.
  DateTime get today => SchoolTime.today(nowOf());

  /// Le **jour** porté par le versement : aujourd'hui tant que le caissier n'a
  /// rien changé.
  ///
  /// ⚠️ C'est un aujourd'hui **vivant** — il se recalcule à chaque lecture.
  /// Figer la valeur à l'ouverture daterait de la veille un versement encaissé
  /// après minuit sur une tablette restée allumée.
  DateTime get paidDay => _paidDayOverride ?? today;

  // ── Cycle de vie ───────────────────────────────────────────────────────────

  /// Pose l'écoute de rafraîchissement sur tous les champs de saisie.
  void addListener(VoidCallback onChanged) {
    for (final entry in entries) {
      entry.controller.addListener(onChanged);
      entry.tenderController.addListener(onChanged);
    }
    for (final group in groups) {
      group.controller.addListener(onChanged);
      group.tenderController.addListener(onChanged);
    }
  }

  void dispose() {
    // Les groupes d'abord : ils ne possèdent que leurs propres contrôleurs, et
    // les tranches leur survivent le temps de cette boucle.
    for (final group in groups) {
      group.dispose();
    }
    for (final entry in entries) {
      entry.dispose();
    }
  }

  // ── Les gestes d'une TRANCHE ───────────────────────────────────────────────

  void toggle(FacturationChargeEntry entry, bool value) {
    entry.selected = value;
    if (value) {
      entry.tenderStopsBeingSource();
      entry.writeDerived(
        entry.controller,
        formatPlainAmount(entry.remainingInCents),
      );
      reflectTender(entry);
    } else {
      entry.controller.clear();
      entry.tenderController.clear();
      entry.tenderStopsBeingSource();
    }
    handOverToTranches(entry);
  }

  void settleAll(FacturationChargeEntry entry) {
    entry.tenderStopsBeingSource();
    entry.writeDerived(
      entry.controller,
      formatPlainAmount(entry.remainingInCents),
    );
    reflectTender(entry);
  }

  /// Le caissier a tapé l'imputation : le comptoir en découle.
  void allocationEdited(FacturationChargeEntry entry) {
    entry.tenderStopsBeingSource();
    reflectTender(entry);
    // La source bascule : le caissier a désigné UNE tranche, le montant de la
    // nature n'est plus qu'un total affiché. Sans cette bascule, la prochaine
    // ventilation écraserait la saisie qu'il vient de faire.
    handOverToTranches(entry);
  }

  /// Le caissier a tapé ce qui est posé sur le comptoir : l'imputation en
  /// découle, vers le bas.
  void tenderEdited(FacturationChargeEntry entry) {
    if (!entry.isConverted) return;
    entry.tenderBecomesSource();
    final line = lineOf(settlementOf(), entry);
    entry.writeDerived(entry.controller, formatPlainAmount(line.settledCents));
    handOverToTranches(entry);
  }

  /// Changer de devise sur une ligne : le montant imputé reste, le comptoir se
  /// recalcule.
  ///
  /// L'imputation est ce que le caissier a décidé d'éteindre ; elle n'a aucune
  /// raison de bouger parce que le parent sort d'autres billets.
  void tenderCurrencyChanged(FacturationChargeEntry entry, String currency) {
    entry.tenderCurrency = currency == entry.charge.currency ? null : currency;
    entry.tenderStopsBeingSource();
    reflectTender(entry);
    // La devise d'une tranche est un geste ciblé : la nature cesse d'être
    // l'unité de règlement, et son sélecteur disparaît.
    handOverToTranches(entry);
  }

  /// Recopie dans le champ du comptoir ce que l'imputation vaut, sans jamais
  /// toucher au champ qui a le curseur.
  void reflectTender(FacturationChargeEntry entry) {
    if (!entry.isConverted) {
      entry.writeDerived(entry.tenderController, '');
      return;
    }
    final line = lineOf(settlementOf(), entry);
    entry.writeDerived(
      entry.tenderController,
      formatPlainAmount(line.tenderCents),
    );
  }

  // ── Les gestes d'une NATURE (GE-3) ─────────────────────────────────────────

  /// Le groupe qui porte cette tranche.
  ///
  /// Résolu par recherche, et non par un pointeur remontant depuis la tranche :
  /// un lien de l'enfant vers le parent créerait un cycle de propriété entre
  /// deux objets dont l'un ne possède déjà pas l'autre, et ce genre de lien
  /// survit à un `dispose()`.
  FacturationChargeGroupEntry? groupOf(FacturationChargeEntry entry) {
    for (final group in groups) {
      if (group.tranches.contains(entry)) return group;
    }
    return null;
  }

  /// Rend la main aux tranches sur la nature qui porte [entry].
  void handOverToTranches(FacturationChargeEntry entry) {
    final group = groupOf(entry);
    if (group == null) return;
    group.handsOverToTranches();
    group.reflectFromTranches();
    reflectGroupTender(group);
  }

  void groupToggle(FacturationChargeGroupEntry group, bool value) {
    group.groupCommands();
    if (!value) {
      group.clear();
      return;
    }
    // Cocher une nature la solde : c'est ce que fait déjà la case d'une ligne,
    // et le caissier corrige ensuite s'il encaisse moins.
    group.controller.text = formatPlainAmount(group.capInCents);
    group.applyCascade(group.controller.text);
    reflectGroupTender(group);
  }

  void groupSettleAll(FacturationChargeGroupEntry group) {
    group.groupCommands();
    group.controller.text = formatPlainAmount(group.capInCents);
    group.applyCascade(group.controller.text);
    reflectGroupTender(group);
  }

  /// Le caissier a tapé le montant de la nature : la cascade écrit les tranches.
  void groupAmountEdited(FacturationChargeGroupEntry group) {
    group.amountBecomesSource();
    group.applyCascade(group.controller.text);
    reflectGroupTender(group);
  }

  /// Le caissier a tapé ce qui est posé sur le comptoir.
  ///
  /// **Une seule conversion, au niveau de la nature**, puis la cascade en devise
  /// de créance. Convertir tranche par tranche tronquerait N fois là où une
  /// seule troncature suffit — et le parent verrait un total qui ne retombe pas
  /// sur ce qu'il a posé.
  void groupTenderEdited(FacturationChargeGroupEntry group) {
    group.tenderBecomesSource();
    final line = settlementOf().fromTender(
      settledCurrency: group.currency,
      tenderCurrency: group.effectiveTenderCurrency,
      tenderedCents: group.tenderedCents,
    );
    // Borné au restant de la nature : le surplus repart avec le parent, il ne
    // s'impute pas. Le porter en imputation fabriquerait un trop-perçu que
    // personne n'a décidé.
    final settled = line.settledCents > group.capInCents
        ? group.capInCents
        : line.settledCents;
    group.applyCascadeCents(settled);
    group.writeGroupAmount(settled);
  }

  void groupTenderCurrencyChanged(
    FacturationChargeGroupEntry group,
    String currency,
  ) {
    group.setTenderCurrency(currency);
    group.tenderStopsBeingSource();
    reflectGroupTender(group);
  }

  void groupToggleExpanded(FacturationChargeGroupEntry group) =>
      group.expanded = !group.expanded;

  /// Recopie dans le comptoir de la nature ce que ses tranches font entrer.
  ///
  /// Somme des `tenderCents` des lignes — donc exactement ce que `tendersFor`
  /// agrégera pour le serveur. Recalculer autrement afficherait un chiffre que
  /// le versement ne portera pas.
  void reflectGroupTender(FacturationChargeGroupEntry group) {
    if (!group.isConverted) {
      group.writeTenderAmount(null);
      return;
    }
    group.writeTenderAmount(groupTenderCents(settlementOf(), group));
  }

  // ── Ce qui part au serveur ─────────────────────────────────────────────────

  /// Ce que ce versement encaisse — `null` quand il n'y a **rien** à encaisser.
  ///
  /// Un versement mixte est un cas NOMINAL depuis que le contrat porte
  /// `amounts[]` : c'est un acte de guichet, donc un versement, un reçu. Reste à
  /// refuser le versement vide, et c'est le seul refus que ce modèle prononce —
  /// « ai-je le droit d'encaisser maintenant » (payeur valide, geste déjà en
  /// vol) regarde la page, pas lui.
  FacturationCollectDraft? buildDraft() {
    final settlement = settlementOf();
    final amounts = settledBagOf(settlement, entries);
    if (amounts.isEmpty || amounts.isAllZero) return null;

    return FacturationCollectDraft(
      amounts: amounts,
      // Ce que le tiroir reçoit voyage à part : rien ne relie l'imputé au perçu
      // sans le taux, et c'est tout l'objet de ces deux listes distinctes.
      tenders: settlement.tendersFor(linesOf(settlement, entries)),
      allocations: [
        for (final entry in entries)
          if (entry.effectiveCents > 0)
            CreatePaymentAllocationInput(
              studentChargeId: entry.charge.id,
              // La ligne de grille, pas seulement la nature du frais : le
              // serveur ne départage plus deux tranches d'un même minerval sans
              // elle.
              feeTariffId: designatedFeeTariffId(entry.charge),
              feeCode: entry.charge.feeCode,
              studentChargeLabel: entry.charge.label,
              amountInCents: entry.effectiveCents,
              currency: entry.charge.currency,
            ),
      ],
      paidAt: paidDay,
    );
  }

  // ── Le changement de date (A4) ─────────────────────────────────────────────

  /// Désigne un nouveau jour, et re-dérive ce qui en découle.
  ///
  /// Rend `false` quand rien ne change — le sélecteur rappelle `onChanged` dès
  /// qu'on valide, même sans avoir rien bougé, et un aller-retour
  /// imputation→comptoir→imputation ne rend pas toujours le même centime.
  ///
  /// ⚠️ **Il ne suffit pas de mémoriser le jour.** Les montants convertis déjà
  /// affichés ont été dérivés au taux de l'ancienne date ; la soumission, elle,
  /// recompose les `tenders` sur le règlement COURANT. Sans re-dérivation,
  /// l'écran annoncerait un chiffre et le versement en porterait un autre.
  ///
  /// ⚠️ **Les natures d'abord, les tranches ensuite.** Une nature convertie
  /// propage sa devise à ses tranches, donc les deux boucles passent sur les
  /// mêmes créances : re-dériver les tranches avant la cascade de leur nature
  /// laisserait des comptoirs calculés sur des imputations périmées.
  bool paidDayChanged(DateTime day) {
    final chosen = DateTime(day.year, day.month, day.day);
    if (chosen == paidDay) return false;

    _paidDayOverride = chosen;
    rates.closeUntouched();

    for (final group in groups) {
      if (!group.isConverted) continue;
      // `groupIsSource` AUTANT que `tenderIsSource` : une nature qui a rendu la
      // main à ses tranches n'est plus l'unité de règlement, et rejouer sa
      // cascade écraserait la ventilation saisie à la main.
      if (group.groupIsSource && group.tenderIsSource) {
        groupTenderEdited(group);
      } else {
        reflectGroupTender(group);
      }
    }

    for (final entry in entries) {
      if (!entry.isConverted) continue;
      if (entry.tenderIsSource) {
        tenderEdited(entry);
      } else {
        reflectTender(entry);
      }
    }
    return true;
  }
}
