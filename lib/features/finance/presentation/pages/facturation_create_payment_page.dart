import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/core/money/tender_composition.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_settlement_section.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_entry.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_payer_form_controller.dart';
import 'package:school_app_flutter/features/finance/presentation/utils/facturation_collect_payment_utils.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_action_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_payer_search_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Page d'encaissement (ex-popin MODALE-12) : identité du payeur, frais à
/// régler, total en direct et CTA ancré au bas de l'écran.
///
/// Écran plein, et non plus une popin posée sur la fiche : un encaissement se
/// saisit à quatre champs et autant de lignes de frais qu'en compte l'année. Il
/// porte donc la charte des autres écrans du dossier élève — barre sombre à
/// initiales, cartes de section, liseré or-doux.
///
/// Elle fournit son propre [FinanceOfflineBloc] (chemin d'écriture
/// offline-first) : la page vit sur sa propre route, hors de l'arbre de la
/// fiche. Au succès, elle se referme en rendant `true` — c'est la fiche qui
/// resynchronise ses listes une fois revenue à l'écran.
class FacturationCreatePaymentPage extends StatelessWidget {
  final FacturationCreatePaymentIntent intent;

  const FacturationCreatePaymentPage({super.key, required this.intent});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FinanceOfflineBloc>(
          create: (_) => getIt<FinanceOfflineBloc>(),
        ),
        // La série de taux de l'école, chargée au montage. Vide tant que rien
        // n'est paramétré : la bascule de devise n'apparaît alors pas, et
        // l'écran est celui d'avant.
        BlocProvider<ExchangeRatesCubit>(
          create: (_) => getIt<ExchangeRatesCubit>()..load(),
        ),
        // Les titres de sections écrits par l'école, pour nommer les natures
        // comme la fiche les nomme. Lecture locale, sans état d'erreur : un
        // catalogue absent laisse la nature localisée.
        BlocProvider<FeeSectionTitlesCubit>(
          create: (_) => getIt<FeeSectionTitlesCubit>()..load(),
        ),
      ],
      // La vue ne lit pas le cubit elle-même : elle reçoit la série. C'est ce
      // qui la garde montable seule — et sans taux, c'est-à-dire dans le cas
      // courant, elle rend exactement l'écran d'avant.
      child: BlocBuilder<ExchangeRatesCubit, ExchangeRatesState>(
        buildWhen: (previous, current) => previous.rates != current.rates,
        builder: (context, rates) =>
            BlocBuilder<FeeSectionTitlesCubit, FeeSectionTitlesState>(
              buildWhen: (previous, current) =>
                  previous.titles != current.titles,
              builder: (context, titles) => FacturationCreatePaymentView(
                intent: intent,
                rates: rates.rates,
                sectionTitles: titles,
              ),
            ),
      ),
    );
  }
}

/// Contenu de la page d'encaissement (état du formulaire + soumission).
class FacturationCreatePaymentView extends StatefulWidget {
  final FacturationCreatePaymentIntent intent;

  /// La série de taux de l'école. Vide = aucun taux paramétré : la bascule de
  /// devise ne s'affiche pas, et l'écran est celui d'avant la V2.
  final List<ExchangeRate> rates;

  /// Les titres de sections écrits par l'école. Vide = on nomme par la nature
  /// localisée, c'est-à-dire l'écran d'avant.
  final FeeSectionTitlesState sectionTitles;

  const FacturationCreatePaymentView({
    super.key,
    required this.intent,
    this.rates = const [],
    this.sectionTitles = const FeeSectionTitlesState(),
  });

  @override
  State<FacturationCreatePaymentView> createState() =>
      _FacturationCreatePaymentViewState();
}

class _FacturationCreatePaymentViewState
    extends State<FacturationCreatePaymentView> {
  final _payer = FacturationPayerFormController();

  late final List<FacturationChargeEntry> _entries;

  /// Les natures, repliées sur les mêmes entrées.
  ///
  /// ⚠️ **Une vue, pas une seconde liste de vérité.** `_entries` reste ce qui
  /// porte les contrôleurs, ce qui est disposé, et surtout ce qui produit les
  /// imputations envoyées au serveur : la requête sortante est identique à
  /// celle d'une saisie tranche par tranche.
  late final List<FacturationChargeGroupEntry> _groups;

  /// Anti double-dialogue : un second déclencheur (retour système pendant que
  /// la flèche a déjà ouvert la confirmation) est ignoré.
  bool _closeConfirmationOpen = false;

  /// Confirmation d'encaissement en vol. Fige le formulaire et éteint le CTA :
  /// deux taps rapides ouvriraient deux confirmations, donc deux versements
  /// pour un seul acte de guichet.
  bool _collectInFlight = false;

  /// Les taux corrigés à la main, **par paire** (`USD>CDF`) : un contrôleur et
  /// un état d'édition chacun.
  ///
  /// Par paire, parce que deux frais de devises différentes n'ont pas « le »
  /// même taux — mais jamais par ligne : deux lignes d'une même paire partagent
  /// leur taux, et en écrire deux dans un seul versement est précisément ce que
  /// la garde locale refuse.
  final Map<String, TextEditingController> _rateControllers = {};
  final Set<String> _editingRates = {};

  /// Le texte que « Modifier » a **pré-rempli**, par paire.
  ///
  /// Sert à distinguer « le caissier a ouvert le champ » de « le caissier a
  /// corrigé le taux ». Sans cette distinction, ouvrir le champ sans rien taper
  /// appliquerait la valeur affichée — arrondie au centième — à la place du taux
  /// du référentiel, qui en porte six. Un geste sans intention changerait le
  /// montant encaissé.
  final Map<String, String> _rateSeeds = {};

  @override
  void initState() {
    super.initState();
    _entries = [
      for (final charge in widget.intent.unpaidCharges)
        if (chargeRemainingInCents(charge) > 0) FacturationChargeEntry(charge),
    ];
    _groups = groupPayableEntries(_entries);
    for (final entry in _entries) {
      entry.controller.addListener(_onChanged);
      entry.tenderController.addListener(_onChanged);
    }
    for (final group in _groups) {
      group.controller.addListener(_onChanged);
      group.tenderController.addListener(_onChanged);
    }
    _payer.addListener(_onChanged);
  }

  @override
  void dispose() {
    for (final controller in _rateControllers.values) {
      controller.dispose();
    }
    _payer.dispose();
    // Les groupes d'abord : ils ne possèdent que leurs propres contrôleurs, et
    // les tranches leur survivent le temps de cette boucle.
    for (final group in _groups) {
      group.dispose();
    }
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  /// Le contrôleur de taux de cette paire, créé à la demande.
  TextEditingController _rateControllerOf(String pairKey) =>
      _rateControllers.putIfAbsent(pairKey, () {
        final controller = TextEditingController();
        // Sans écoute, corriger un taux ne rafraîchirait ni les montants
        // dérivés, ni le total de la barre, ni le CTA : le caissier taperait
        // dans un champ sans effet visible.
        controller.addListener(_onChanged);
        return controller;
      });

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Demande de sortie (flèche de la barre, retour système) : passe toujours
  /// par une confirmation, contrairement au succès d'encaissement qui referme
  /// directement (cf. [_onCollect]). `Navigator.pop()` ci-dessous quitte
  /// réellement la page : contrairement à `maybePop`/au retour système, il
  /// n'est pas soumis au [PopScope] et n'est donc pas re-intercepté.
  Future<void> _requestClose() async {
    if (_closeConfirmationOpen) return;
    _closeConfirmationOpen = true;
    try {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showAppConfirmationDialog(
        context: context,
        title: l10n.facturationCreatePaymentCloseConfirmTitle,
        message: l10n.facturationCreatePaymentCloseConfirmMessage,
        confirmLabel: l10n.facturationCreatePaymentCloseConfirmAction,
        cancelLabel: l10n.facturationCreatePaymentCloseConfirmCancel,
        isDestructive: true,
      );
      if (!mounted || !confirmed) return;
      Navigator.of(context).pop();
    } finally {
      _closeConfirmationOpen = false;
    }
  }

  String _formatWithCurrency(int cents, String currency) =>
      formatMonetaryAmountWithCurrency(amount: cents / 100, currency: currency);

  void _onToggle(FacturationChargeEntry entry, bool value) {
    setState(() {
      entry.selected = value;
      if (value) {
        entry.tenderIsSource = false;
        entry.writeDerived(
          entry.controller,
          formatPlainAmount(entry.remainingInCents),
        );
        _reflectTender(entry);
      } else {
        entry.controller.clear();
        entry.tenderController.clear();
        entry.tenderIsSource = false;
      }
      _handOverToTranches(entry);
    });
  }

  void _onSettleAll(FacturationChargeEntry entry) {
    setState(() {
      entry.tenderIsSource = false;
      entry.writeDerived(
        entry.controller,
        formatPlainAmount(entry.remainingInCents),
      );
      _reflectTender(entry);
    });
  }

  // ── Les gestes d'une NATURE (GE-3) ─────────────────────────────────────────

  /// Le groupe qui porte cette tranche.
  ///
  /// Résolu par recherche, et non par un pointeur remontant depuis la tranche :
  /// un lien de l'enfant vers le parent créerait un cycle de propriété entre
  /// deux objets dont l'un ne possède déjà pas l'autre, et ce genre de lien
  /// survit à un `dispose()`. La liste tient au plus une vingtaine d'entrées.
  FacturationChargeGroupEntry? _groupOf(FacturationChargeEntry entry) {
    for (final group in _groups) {
      if (group.tranches.contains(entry)) return group;
    }
    return null;
  }

  void _onGroupToggle(FacturationChargeGroupEntry group, bool value) {
    setState(() {
      group.groupIsSource = true;
      if (!value) {
        group.clear();
        return;
      }
      // Cocher une nature la solde : c'est ce que fait déjà la case d'une
      // ligne, et le caissier corrige ensuite s'il encaisse moins.
      group.controller.text = formatPlainAmount(group.capInCents);
      group.applyCascade(group.controller.text);
      _reflectGroupTender(group);
    });
  }

  void _onGroupSettleAll(FacturationChargeGroupEntry group) {
    setState(() {
      group.groupIsSource = true;
      group.controller.text = formatPlainAmount(group.capInCents);
      group.applyCascade(group.controller.text);
      _reflectGroupTender(group);
    });
  }

  /// Le caissier a tapé le montant de la nature : la cascade écrit les tranches.
  void _onGroupAmountEdited(FacturationChargeGroupEntry group) {
    setState(() {
      group.groupIsSource = true;
      group.tenderIsSource = false;
      group.applyCascade(group.controller.text);
      _reflectGroupTender(group);
    });
  }

  /// Le caissier a tapé ce qui est posé sur le comptoir.
  ///
  /// **Une seule conversion, au niveau de la nature**, puis la cascade en devise
  /// de créance. Convertir tranche par tranche tronquerait N fois là où une
  /// seule troncature suffit — et le parent verrait un total qui ne retombe pas
  /// sur ce qu'il a posé.
  void _onGroupTenderEdited(FacturationChargeGroupEntry group) {
    setState(() {
      group.groupIsSource = true;
      group.tenderIsSource = true;
      final settlement = _settlement();
      final line = settlement.fromTender(
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
    });
  }

  void _onGroupTenderCurrencyChanged(
    FacturationChargeGroupEntry group,
    String currency,
  ) {
    setState(() {
      group.setTenderCurrency(currency);
      group.tenderIsSource = false;
      _reflectGroupTender(group);
    });
  }

  void _onGroupToggleExpanded(FacturationChargeGroupEntry group) {
    setState(() => group.expanded = !group.expanded);
  }

  /// Recopie dans le comptoir de la nature ce que ses tranches font entrer.
  ///
  /// Somme des `tenderCents` des lignes — donc exactement ce que
  /// `tendersFor` agrégera pour le serveur. Recalculer autrement afficherait un
  /// chiffre que le versement ne portera pas.
  void _reflectGroupTender(FacturationChargeGroupEntry group) {
    if (!group.isConverted) {
      group.writeTenderAmount(null);
      return;
    }
    group.writeTenderAmount(_groupTenderCents(_settlement(), group));
  }

  /// L'état du règlement : les taux du référentiel, plus ceux corrigés.
  ///
  /// Reconstruit à chaque rendu — il n'y a pas d'état à synchroniser, seulement
  /// une devise par ligne et des taux par paire.
  TenderSettlement _settlement() => TenderSettlement(
    rates: widget.rates,
    // Le taux qui vaut à l'heure du versement, pas celui d'aujourd'hui : un
    // encaissement hors ligne remonte parfois trois jours plus tard.
    at: DateTime.now(),
    overriddenRates: {
      for (final key in _editingRates) key: ?_rateMicrosOf(key),
    },
  );

  /// Le taux saisi pour cette paire, en micro-unités. `null` tant que rien n'a
  /// été corrigé, ou quand la saisie n'est pas un nombre.
  int? _rateMicrosOf(String pairKey) {
    final raw = _rateControllers[pairKey]?.text ?? '';
    // Champ ouvert mais intact : le référentiel garde la main.
    if (raw == _rateSeeds[pairKey]) return null;
    final parsed = parseMonetaryAmount(raw);
    if (parsed == null || parsed <= 0) return null;
    // Deux décimales, celles qui seront stockées : ce qui s'affiche, ce qui
    // s'imprime et ce qui part sur le fil sont le même nombre.
    return (parsed * 100).round() * (ExchangeRate.scale ~/ 100);
  }

  /// Le règlement d'une ligne : ce qu'elle éteint, ce que le tiroir garde, et
  /// ce qui repart avec le parent.
  ///
  /// **Le champ que le caissier vient de taper fait foi.** S'il a saisi le
  /// montant posé sur le comptoir, l'imputation se déduit vers le bas et
  /// l'excédent devient de la monnaie à rendre ; s'il a saisi l'imputation, le
  /// comptoir en découle exactement.
  SettlementLine _lineOf(
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

  /// Les lignes retenues — celles qui portent un montant d'un côté ou de
  /// l'autre.
  List<SettlementLine> _lines(TenderSettlement settlement) => [
    for (final entry in _entries)
      if (entry.selected &&
          (entry.effectiveCents > 0 || entry.tenderedCents > 0))
        _lineOf(settlement, entry),
  ];

  /// Recopie dans le champ du comptoir ce que l'imputation vaut, sans jamais
  /// toucher au champ qui a le curseur.
  void _reflectTender(FacturationChargeEntry entry) {
    if (!entry.isConverted) {
      entry.writeDerived(entry.tenderController, '');
      return;
    }
    final line = _lineOf(_settlement(), entry);
    entry.writeDerived(
      entry.tenderController,
      formatPlainAmount(line.tenderCents),
    );
  }

  /// Le caissier a tapé l'imputation : le comptoir en découle.
  void _onAllocationEdited(FacturationChargeEntry entry) {
    setState(() {
      entry.tenderIsSource = false;
      _reflectTender(entry);
      // La source bascule : le caissier a désigné UNE tranche, le montant de la
      // nature n'est plus qu'un total affiché. Sans cette bascule, la prochaine
      // ventilation écraserait la saisie qu'il vient de faire.
      _handOverToTranches(entry);
    });
  }

  /// Rend la main aux tranches sur la nature qui porte [entry].
  void _handOverToTranches(FacturationChargeEntry entry) {
    final group = _groupOf(entry);
    if (group == null) return;
    group.groupIsSource = false;
    group.reflectFromTranches();
    _reflectGroupTender(group);
  }

  /// Le caissier a tapé ce qui est posé sur le comptoir : l'imputation en
  /// découle, vers le bas.
  void _onTenderEdited(FacturationChargeEntry entry) {
    if (!entry.isConverted) return;
    setState(() {
      entry.tenderIsSource = true;
      final line = _lineOf(_settlement(), entry);
      entry.writeDerived(
        entry.controller,
        formatPlainAmount(line.settledCents),
      );
      _handOverToTranches(entry);
    });
  }

  /// Changer de devise sur une ligne : le montant imputé reste, le comptoir se
  /// recalcule.
  ///
  /// L'imputation est ce que le caissier a décidé d'éteindre ; elle n'a aucune
  /// raison de bouger parce que le parent sort d'autres billets.
  void _onTenderCurrencyChanged(FacturationChargeEntry entry, String currency) {
    setState(() {
      entry.tenderCurrency = currency == entry.charge.currency
          ? null
          : currency;
      entry.tenderIsSource = false;
      _reflectTender(entry);
      // La devise d'une tranche est un geste ciblé : la nature cesse d'être
      // l'unité de règlement, et son sélecteur disparaît. Deux devises
      // concurrentes pour un même versement ne se lisent pas.
      _handOverToTranches(entry);
    });
  }

  /// Le total **imputé**, par devise de créance — ce que ce versement éteint.
  ///
  /// C'était un entier unique, sommé sur toutes les lignes retenues, étiqueté
  /// avec la première devise non vide rencontrée. Un versement soldant 425,00 \$
  /// et 90 000 FC s'affichait « 9 042 500 USD » — sur le bandeau or, sur le
  /// ticket remis au parent, et dans le payload envoyé au serveur.
  MoneyBag _settledBag(TenderSettlement settlement) =>
      settlement.settledBag(_lines(settlement));

  /// Ce que le tiroir prend, par devise **reçue**.
  MoneyBag _tenderBag(TenderSettlement settlement) =>
      settlement.tenderBag(_lines(settlement));

  /// Un total rendu sur une ligne — les devises séparées, jamais sommées.
  String _bagLabel(MoneyBag bag) =>
      bag.entries.map(MoneyFormat.format).join(' · ');

  /// Vrai quand au moins une ligne convertit : c'est ce qui décide d'annoncer
  /// le perçu en tête de la barre.
  ///
  /// « Converti » n'est pas « une devise a été choisie » : régler en dollars des
  /// créances en dollars n'est pas une conversion.
  bool _hasConversion(TenderSettlement settlement) =>
      _lines(settlement).any((line) => line.isConverted);

  /// Les taux à afficher — un par paire réellement convertie.
  List<FacturationRatePair> _ratePairs(TenderSettlement settlement) {
    final seen = <String>{};
    final pairs = <FacturationRatePair>[];
    for (final line in _lines(settlement)) {
      final rate = line.rate;
      if (rate == null) continue;
      final key = TenderSettlement.pairKey(rate.base, rate.quote);
      if (!seen.add(key)) continue;
      pairs.add(
        FacturationRatePair(
          rate: rate,
          referenceRate: settlement.referenceRateFor(rate.base, rate.quote),
          controller: _rateControllerOf(key),
          editing: _editingRates.contains(key),
          onEdit: () => setState(() {
            _editingRates.add(key);
            final controller = _rateControllerOf(key);
            if (controller.text.isEmpty) {
              final seed = rate.formatted(space: '');
              controller.text = seed;
              _rateSeeds[key] = seed;
            }
          }),
          diverges: settlement.divergesFor(rate.base, rate.quote),
        ),
      );
    }
    return pairs;
  }

  /// Le taux de cette ligne, rendu « 2 800 FC / \$ ».
  String? _lineRateLabel(
    TenderSettlement settlement,
    FacturationChargeEntry entry,
  ) {
    final rate = _lineOf(settlement, entry).rate;
    if (rate == null) return null;
    return '${rate.formatted()} ${MoneyFormat.symbolOf(rate.quote)} / '
        '${MoneyFormat.symbolOf(rate.base)}';
  }

  /// Ce qui repart avec le parent sur cette ligne, ou `null`.
  String? _lineChangeLabel(
    TenderSettlement settlement,
    FacturationChargeEntry entry,
    AppLocalizations l10n,
  ) {
    final line = _lineOf(settlement, entry);
    if (line.changeCents <= 0) return null;
    return l10n.facturationCreatePaymentChangeDue(
      _formatWithCurrency(line.changeCents, line.tenderCurrency),
    );
  }

  /// Le récapitulatif à valider : une entrée par nature réglée, ses tranches
  /// dessous.
  ///
  /// Une nature qui ne règle qu'une tranche n'expose pas d'enfant : la ligne EST
  /// la tranche, et la redoubler n'apprendrait rien.
  List<FacturationConfirmAllocationGroup> _confirmGroups(
    TenderSettlement settlement,
    AppLocalizations l10n,
  ) => [
    for (final group in _groups)
      if (group.allocatedCents > 0)
        FacturationConfirmAllocationGroup(
          label: group.isSingleTranche
              ? chargeDesignation(group.tranches.single.charge, l10n)
              : chargeGroupDesignation(
                  group.asChargeGroup,
                  l10n,
                  schoolTitle: widget.sectionTitles.titleOf(group.feeCode),
                ),
          amount: _formatWithCurrency(group.allocatedCents, group.currency),
          derivedAmount: _groupTenderLabel(settlement, group),
          items: group.isSingleTranche
              ? const []
              : [
                  for (final tranche in group.tranches)
                    if (tranche.effectiveCents > 0)
                      FacturationConfirmAllocationItem(
                        label: chargeDesignation(tranche.charge, l10n),
                        amount: _formatWithCurrency(
                          tranche.effectiveCents,
                          tranche.charge.currency,
                        ),
                        derivedAmount: _tenderLabelOf(settlement, tranche),
                      ),
                ],
        ),
  ];

  /// Ce qu'une nature fait entrer dans le tiroir, rendu — `null` sans
  /// conversion.
  String? _groupTenderLabel(
    TenderSettlement settlement,
    FacturationChargeGroupEntry group,
  ) {
    final kept = _groupTenderCents(settlement, group);
    if (kept <= 0) return null;
    return _formatWithCurrency(kept, group.effectiveTenderCurrency);
  }

  /// Ce que le tiroir conserve pour cette nature : la somme de ce que ses
  /// tranches y font entrer — donc exactement ce que `tendersFor` agrégera.
  int _groupTenderCents(
    TenderSettlement settlement,
    FacturationChargeGroupEntry group,
  ) {
    if (!group.isConverted) return 0;
    var total = 0;
    for (final tranche in group.tranches) {
      if (tranche.effectiveCents <= 0) continue;
      total += _lineOf(settlement, tranche).tenderCents;
    }
    return total;
  }

  /// Le taux d'une NATURE, rendu « 2 800 FC / $ ».
  ///
  /// Un seul taux pour tout le groupe : ses tranches partagent la devise de
  /// créance, donc la paire. C'est ce qui remplace les N taux identiques que
  /// l'écran affichait, une fois par tranche.
  String? _groupRateLabel(
    TenderSettlement settlement,
    FacturationChargeGroupEntry group,
  ) {
    if (!group.isConverted) return null;
    final rate = settlement.rateFor(
      group.currency,
      group.effectiveTenderCurrency,
    );
    if (rate == null) return null;
    return '${rate.formatted()} ${MoneyFormat.symbolOf(rate.quote)} / '
        '${MoneyFormat.symbolOf(rate.base)}';
  }

  /// Ce qui repart avec le parent sur cette nature, ou `null`.
  ///
  /// **Calculée au groupe**, et pas comme la somme des monnaies de ses
  /// tranches : les tranches ne rendent rien quand c'est le groupe qui porte le
  /// comptoir. L'excédent est ce que le parent a posé moins ce que le tiroir
  /// conserve.
  String? _groupChangeLabel(
    TenderSettlement settlement,
    FacturationChargeGroupEntry group,
    AppLocalizations l10n,
  ) {
    if (!group.isConverted || !group.tenderIsSource) return null;
    final change = group.tenderedCents - _groupTenderCents(settlement, group);
    if (change <= 0) return null;
    return l10n.facturationCreatePaymentChangeDue(
      _formatWithCurrency(change, group.effectiveTenderCurrency),
    );
  }

  /// Vrai quand le couple perçu/imputé ne tient pas — le CTA s'éteint alors.
  ///
  /// La garde est celle du chemin d'écriture, éprouvée ICI, pendant la saisie :
  /// un refus après le geste se lit comme une panne alors que c'est une saisie
  /// à corriger.
  bool _tenderInvariantBroken(TenderSettlement settlement) {
    final lines = _lines(settlement);
    if (lines.isEmpty) return false;
    return TenderComposition.check(
          allocations: settlement.settledBag(lines).entries,
          tenders: settlement.tendersFor(lines),
        ) !=
        null;
  }

  /// Vrai quand un frais est retenu et qu'AUCUN ne peut se régler dans une
  /// autre monnaie.
  ///
  /// C'est la seule situation où « aucun taux paramétré » est vrai : sans frais
  /// coché il n'y a pas encore de question, et avec une devise proposable la
  /// bascule est là, sur la ligne.
  bool _hasNoConvertibleCharge(TenderSettlement settlement) {
    final retained = _entries.where((entry) => entry.selected);
    if (retained.isEmpty) return false;
    return retained.every(
      (entry) => settlement.optionsFor(entry.charge.currency).length < 2,
    );
  }

  /// Le taux du versement, rendu — `null` dès qu'il y en a plusieurs.
  ///
  /// La popin valide UN montant : y poser deux taux les ferait lire comme un
  /// seul. Chaque ligne porte le sien, là où il s'applique.
  String? _singleRateLabel(TenderSettlement settlement) {
    final rates = <String>{
      for (final line in _lines(settlement))
        if (line.rate case final rate?)
          '${rate.formatted()} ${MoneyFormat.symbolOf(rate.quote)} / '
              '${MoneyFormat.symbolOf(rate.base)}',
    };
    return rates.length == 1 ? rates.single : null;
  }

  /// Ce qu'une ligne fait entrer dans le tiroir, rendu — `null` quand elle ne
  /// convertit pas.
  String? _tenderLabelOf(
    TenderSettlement settlement,
    FacturationChargeEntry entry,
  ) {
    final line = _lineOf(settlement, entry);
    if (!line.isConverted || line.tenderCents <= 0) return null;
    return _formatWithCurrency(line.tenderCents, line.tenderCurrency);
  }

  /// Ouvre l'annuaire local des payeurs et reprend celui qui en revient.
  Future<void> _pickPayer() async {
    final payer = await showFacturationPayerSearchDialog(
      context: context,
      studentId: widget.intent.studentId,
    );
    if (!mounted || payer == null) return;
    _payer.applyPayer(payer);
  }

  String _studentFullName(AppLocalizations l10n) {
    final name = [
      widget.intent.lastName,
      widget.intent.surname,
      widget.intent.firstName,
    ].map((v) => v.trim()).where((v) => v.isNotEmpty).join(' ');
    return name.isEmpty ? l10n.facturationDetailUnknownValue : name;
  }

  /// Classe affichée dans le sur-titre « Encaissement · {classe} », comme sur
  /// la fiche d'où l'on vient.
  String _classLabel(AppLocalizations l10n) {
    final value = widget.intent.levelName.trim().isNotEmpty
        ? widget.intent.levelName.trim()
        : widget.intent.levelGroupName.trim();
    return value.isEmpty ? l10n.facturationDetailUnknownValue : value;
  }

  Future<void> _onCollect(AppLocalizations l10n) async {
    final settlement = _settlement();
    final bag = _settledBag(settlement);
    final converted = _hasConversion(settlement);
    // Ce qu'on valide est ce que le parent va poser sur le comptoir : la popin
    // annonce le PERÇU, et détaille dessous ce que ce versement éteint.
    final totalLabel = converted
        ? _bagLabel(_tenderBag(settlement))
        : _bagLabel(bag);
    // Un versement mixte est un cas NOMINAL depuis que le contrat porte
    // `amounts[]` : c'est un acte de guichet, donc un versement, un reçu.
    // Reste à refuser le versement vide — rien à encaisser n'est pas un
    // encaissement.
    if (!_payer.isValid || bag.isEmpty || bag.isAllZero || _collectInFlight) {
      return;
    }

    final retained = _entries.where((e) => e.effectiveCents > 0).toList();
    final offlineBloc = context.read<FinanceOfflineBloc>();
    final phone = _payer.phone.text.trim();

    final request = PaymentsCreateRequested(
      studentId: widget.intent.studentId,
      academicYearId: widget.intent.academicYearId,
      // `amounts` reste l'IMPUTÉ — la devise de chaque créance. Ce que le
      // tiroir reçoit voyage dans `tenders`, et rien ne relie les deux sans le
      // taux.
      amounts: bag,
      tenders: settlement.tendersFor(_lines(settlement)),
      // Les quatre partent en `null` quand rien n'a été saisi — jamais en `''`.
      // « Pas de payeur » est un fait, pas un nom de longueur zéro : c'est la
      // distinction que le serveur s'est donnée en V114, et une chaîne vide la
      // ferait disparaître dès la première écriture.
      payerFirstName: _payer.valueOf(_payer.firstName),
      payerLastName: _payer.valueOf(_payer.lastName),
      payerMiddleName: _payer.valueOf(_payer.middleName),
      payerPhoneNumber: _payer.valueOf(_payer.phone),
      allocations: [
        for (final entry in retained)
          CreatePaymentAllocationInput(
            studentChargeId: entry.charge.id,
            // La ligne de grille, pas seulement la nature du frais : le serveur
            // ne départage plus deux tranches d'un même minerval sans elle.
            feeTariffId: designatedFeeTariffId(entry.charge),
            feeCode: entry.charge.feeCode,
            studentChargeLabel: entry.charge.label,
            amountInCents: entry.effectiveCents,
            currency: entry.charge.currency,
          ),
      ],
    );

    setState(() => _collectInFlight = true);
    // La sur-couche 2 étapes porte la confirmation PUIS le résultat
    // (processing → succès | échec) : le paiement n'est créé qu'à l'étape
    // résultat et le toast est remplacé par la popin. Elle RESTE une popin —
    // un récapitulatif se lit par-dessus la saisie qu'il résume.
    final outcome = await showFacturationCreatePaymentConfirmDialog(
      context,
      financeOfflineBloc: offlineBloc,
      totalLabel: totalLabel,
      // Le taux, sous le montant validé — et seulement quand il y en a UN à
      // dire. Deux taux sur une ligne se liraient comme un seul, et le parent
      // conteste au guichet le chiffre qu'il a lu.
      rateLabel: _singleRateLabel(settlement),
      studentName: _studentFullName(l10n),
      // `null` quand rien n'a été saisi : le récapitulatif escamote alors son
      // bloc payeur au lieu d'y afficher un tiret. On valide ce qu'on a saisi,
      // et un tiret dans un récapitulatif de validation se lit comme une donnée
      // qu'on aurait perdue en route.
      payerName: _payer.composedName,
      payerPhone: phone,
      // Les tranches, SOUS le nom de leur nature (GE-5). Le caissier valide une
      // répartition : ne montrer que « Minerval 120 000 » lui ferait signer une
      // ventilation qu'il n'a pas vue, et c'est elle — pas le total — qui
      // figurera sur la note de perception.
      allocations: _confirmGroups(settlement, l10n),
      request: request,
    );

    if (!mounted) {
      return;
    }
    setState(() => _collectInFlight = false);
    // Succès rendu par la popin résultat → on quitte la page en rendant `true`.
    // C'est la fiche qui resynchronise ses listes au retour : faire le refresh
    // là-bas évite qu'un éventuel échec de rechargement ne contredise l'écran
    // de succès.
    if (outcome == FacturationCollectOutcome.succeeded) {
      // `pop()` (pas `maybePop`) pour ne pas déclencher la confirmation de
      // sortie : il n'y a plus rien à perdre.
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settlement = _settlement();
    // Un montant compté hors tolérance éteint le CTA : la garde locale le
    // refuserait de toute façon, et un refus après le geste se lit comme une
    // panne alors que c'est une saisie à corriger.
    final allocations = _settledBag(settlement);
    final canCollect =
        _payer.isValid &&
        !allocations.isAllZero &&
        !_collectInFlight &&
        !_tenderInvariantBroken(settlement);
    // « Converti » n'est pas « une devise a été choisie » : régler en dollars
    // des créances en dollars n'est pas une conversion. Ce qui compte est qu'un
    // taux s'applique réellement quelque part — sinon la barre annoncerait « À
    // percevoir » sur un versement où rien n'a bougé d'unité.
    final converted = _hasConversion(settlement);

    return PopScope(
      // Bloque le retour système / `maybePop` : toute sortie passe par
      // `_requestClose`. `Navigator.pop()` direct (succès d'encaissement) n'est
      // pas concerné par ce garde-fou.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _requestClose();
      },
      child: AppPageBackground(
        appBar: StudentDetailAppBar(
          fullName: _studentFullName(l10n),
          eyebrow:
              '${l10n.facturationCreatePaymentEyebrow} · ${_classLabel(l10n)}',
          firstName: widget.intent.firstName,
          lastName: widget.intent.lastName,
          fallbackRoute: AppRoutesNames.facturationDetailPath(
            studentId: widget.intent.studentId,
            academicYearId: widget.intent.academicYearId,
          ),
          // Une saisie en cours ne se perd pas sur un tap : la flèche passe par
          // la même confirmation que le retour système.
          onExit: _requestClose,
        ),
        // Sans contexte d'affichage il n'y a pas de saisie sous la barre :
        // proposer d'encaisser sous une carte d'erreur n'a aucun sens.
        bottomNavigationBar: widget.intent.hasDisplayContext
            ? FacturationCollectActionBar(
                totalLabel: converted
                    ? _bagLabel(_tenderBag(settlement))
                    : _bagLabel(allocations),
                settledLabel: converted ? _bagLabel(allocations) : null,
                onCollect: canCollect ? () => _onCollect(l10n) : null,
              )
            : null,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            // Largeur de lecture de la Facturation : un formulaire étalé sur
            // 1180 dp éloigne les libellés de leurs champs.
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.facturationContentMaxWidth,
            ),
            child: _body(l10n, settlement),
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, TenderSettlement settlement) {
    // Lien profond ouvert sans contexte : on n'encaisse pas au nom de quelqu'un
    // qu'on ne sait pas nommer. La fiche pose la même garde sur son propre
    // contexte.
    if (!widget.intent.hasDisplayContext) {
      return FinanceContextErrorCard(
        title: l10n.facturationCreatePaymentContextErrorTitle,
        message: l10n.facturationCreatePaymentContextErrorMessage,
        icon: Icons.report_problem_outlined,
        accent: AppColors.warning,
        accentSoft: AppColors.warning.withValues(alpha: 0.14),
        borderColor: AppColors.warning.withValues(alpha: 0.2),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FinanceSectionCard(
          backgroundColor: AppColors.surfaceRaised,
          borderColor: AppColors.border,
          child: FacturationCreatePaymentPayerSection(
            lastNameController: _payer.lastName,
            firstNameController: _payer.firstName,
            middleNameController: _payer.middleName,
            phoneController: _payer.phone,
            onPickPayer: _pickPayer,
            phoneErrorText: _payer.phoneErrorText(l10n),
            readOnly: _collectInFlight,
          ),
        ),
        const SizedBox(height: AppDimensions.detailSectionSpacing),
        FacturationCreatePaymentChargesSection(
          groups: _groups,
          schoolTitleOf: widget.sectionTitles.titleOf,
          onGroupToggle: _collectInFlight ? null : _onGroupToggle,
          onGroupSettleAll: _collectInFlight ? null : _onGroupSettleAll,
          onGroupAmountEdited: _collectInFlight ? null : _onGroupAmountEdited,
          onGroupTenderEdited: _collectInFlight ? null : _onGroupTenderEdited,
          onGroupToggleExpanded: _collectInFlight
              ? null
              : _onGroupToggleExpanded,
          onGroupTenderCurrencyChanged: _collectInFlight
              ? null
              : _onGroupTenderCurrencyChanged,
          groupCurrencyOptionsOf: (group) =>
              settlement.optionsFor(group.currency),
          groupRateLabelOf: (group) => _groupRateLabel(settlement, group),
          groupChangeLabelOf: (group) =>
              _groupChangeLabel(settlement, group, l10n),
          onToggle: _collectInFlight ? null : _onToggle,
          onSettleAll: _collectInFlight ? null : _onSettleAll,
          // Le taux vit au-dessus des lignes : il est le même pour toutes
          // celles d'une même paire, et l'écrire deux fois en ferait deux.
          settlement: TenderSettlementSection(
            pairs: _ratePairs(settlement),
            enabled: !_collectInFlight,
            // ⚠️ L'absence de taux se dit **quand elle est vraie**, jamais
            // parce qu'aucune conversion n'est encore choisie. Le mesurer sur
            // les paires converties faisait annoncer « aucun taux paramétré »
            // sur un guichet qui venait d'en recevoir deux — le message le plus
            // trompeur possible, puisqu'il désigne le paramétrage alors que
            // tout est en place.
            explainWhenUnavailable: _hasNoConvertibleCharge(settlement),
          ),
          currencyOptionsOf: (entry) =>
              settlement.optionsFor(entry.charge.currency),
          onTenderCurrencyChanged: _collectInFlight
              ? null
              : _onTenderCurrencyChanged,
          onAllocationEdited: _collectInFlight ? null : _onAllocationEdited,
          onTenderEdited: _collectInFlight ? null : _onTenderEdited,
          rateLabelOf: (entry) => _lineRateLabel(settlement, entry),
          changeLabelOf: (entry) => _lineChangeLabel(settlement, entry, l10n),
        ),
      ],
    );
  }
}
