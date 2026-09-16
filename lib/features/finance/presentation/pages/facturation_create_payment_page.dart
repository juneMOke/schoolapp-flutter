import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/exchange_rates_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_charge_group_entry.dart';
import 'package:school_app_flutter/core/money/tender_settlement.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_settlement_section.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/student_charge_designation.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_collect_form_model.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_collect_labels.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_payer_form_controller.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_rate_board.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/facturation_settlement_reads.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_section_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_action_bar.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_confirm_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_date_section.dart';
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
    // Borne basse du sélecteur de date (A2) : la rentrée de l'année que ce
    // versement solde. Le contexte académique est fourni à la racine de
    // l'application, donc au-dessus de cette route.
    //
    // ⚠️ La date n'est retenue que si l'année portée par le contexte est bien
    // CELLE du versement. Encaisser sur l'année précédente depuis un poste calé
    // sur l'année courante prendrait sinon la borne à la mauvaise rentrée — et
    // interdirait précisément les saisies de rattrapage que ce champ existe pour
    // permettre.
    // `select` et non `watch` (règle n°9) : seule la rentrée nous intéresse, et
    // l'état porte aussi les drapeaux de session (401/403, provisioning) qui
    // reconstruiraient la page pour rien.
    final earliestPaidAt = context.select<AcademicYearContextBloc, DateTime?>((
      bloc,
    ) {
      final year = bloc.state.context?.academicYear;
      return year != null && year.id == intent.academicYearId
          ? year.startDate
          : null;
    });

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
                earliestPaidAt: earliestPaidAt,
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

  /// La rentrée de l'année que ce versement solde, quand le référentiel la
  /// connaît. Borne basse du sélecteur de date (A2) ; `null` retombe sur le même
  /// jour un an plus tôt.
  final DateTime? earliestPaidAt;

  /// Instant de référence — **injecté par les tests seulement**. `null` =
  /// l'horloge du poste.
  final DateTime? now;

  const FacturationCreatePaymentView({
    super.key,
    required this.intent,
    this.rates = const [],
    this.sectionTitles = const FeeSectionTitlesState(),
    this.earliestPaidAt,
    this.now,
  });

  @override
  State<FacturationCreatePaymentView> createState() =>
      _FacturationCreatePaymentViewState();
}

class _FacturationCreatePaymentViewState
    extends State<FacturationCreatePaymentView> {
  final _payer = FacturationPayerFormController();

  /// L'état de la saisie et les gestes qui le font évoluer.
  ///
  /// La page ne garde que ce qui relève du widget : les verrous de navigation,
  /// le rendu, et l'enveloppe `setState`. Tout le reste — lignes, natures, jour
  /// désigné, dérivations — vit dans [FacturationCollectFormModel], avec ses
  /// tests unitaires.
  late final FacturationCollectFormModel _model;

  /// Anti double-dialogue : un second déclencheur (retour système pendant que
  /// la flèche a déjà ouvert la confirmation) est ignoré.
  bool _closeConfirmationOpen = false;

  /// Confirmation d'encaissement en vol. Fige le formulaire et éteint le CTA :
  /// deux taps rapides ouvriraient deux confirmations, donc deux versements
  /// pour un seul acte de guichet.
  bool _collectInFlight = false;

  /// Les taux corrigés à la main, **par paire** (`USD>CDF`).
  ///
  /// Contrôleurs, boîtes ouvertes et amorces formaient trois champs de cette
  /// classe ; ils forment en réalité un objet — [FacturationRateBoard] — et les
  /// règles qui les lient y sont écrites, avec leurs tests.
  late final FacturationRateBoard _rates;

  DateTime get _now => widget.now ?? DateTime.now();

  /// Borne basse (A2) : la rentrée quand on la connaît, sinon le même jour un an
  /// plus tôt.
  DateTime get _firstSelectableDay {
    final start = widget.earliestPaidAt;
    // Rentrée inconnue — référentiel muet, ou versement porté par une AUTRE
    // année que celle du contexte, qui est justement le cas du rattrapage. Une
    // fenêtre d'un an partant d'aujourd'hui amputerait alors le début de l'année
    // précédente : on en ouvre deux. Cela écarte toujours une saisie absurde
    // sans fermer la porte au rattrapage.
    if (start == null) {
      return SchoolTime.oneYearBefore(SchoolTime.oneYearBefore(_model.today));
    }
    // ⚠️ Champs de calendrier lus BRUTS, et surtout pas via `SchoolTime` : une
    // date de rentrée est un jour, pas un instant. La faire traverser un fuseau
    // la reculerait d'un jour sur toute machine à l'est d'UTC+1.
    final day = DateTime(start.year, start.month, start.day);
    // Une rentrée postérieure à aujourd'hui (référentiel en avance d'une année)
    // fermerait le sélecteur sur une plage vide, et `showDatePicker` lève.
    return day.isAfter(_model.today) ? _model.today : day;
  }

  @override
  void initState() {
    super.initState();
    _rates = FacturationRateBoard(onChanged: _onChanged);
    _model = FacturationCollectFormModel.fromCharges(
      charges: widget.intent.unpaidCharges,
      rates: _rates,
      // ⚠️ Un RAPPEL, jamais une valeur : la série de taux arrive en asynchrone,
      // et un modèle qui l'aurait captée ici convertirait au taux d'une série
      // périmée (piège P1).
      settlementOf: _settlement,
      nowOf: () => _now,
    );
    _model.addListener(_onChanged);
    _payer.addListener(_onChanged);
  }

  @override
  void dispose() {
    _rates.dispose();
    _payer.dispose();
    _model.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Le seul endroit où un geste devient un rendu.
  ///
  /// Les gestes vivent dans le modèle et ne connaissent ni widget ni `setState`
  /// (piège P2). Tout passe par ici : oublier l'enveloppe donnerait un écran qui
  /// ne se rafraîchit pas, sans la moindre erreur pour le dire.
  void _act(void Function() gesture) => setState(gesture);

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

  /// Le caissier a tapé ce qui est posé sur le comptoir.
  ///
  /// **Une seule conversion, au niveau de la nature**, puis la cascade en devise
  /// de créance. Convertir tranche par tranche tronquerait N fois là où une
  /// seule troncature suffit — et le parent verrait un total qui ne retombe pas
  /// sur ce qu'il a posé.
  /// Recopie dans le comptoir de la nature ce que ses tranches font entrer.
  ///
  /// Somme des `tenderCents` des lignes — donc exactement ce que
  /// `tendersFor` agrégera pour le serveur. Recalculer autrement afficherait un
  /// chiffre que le versement ne portera pas.
  /// L'état du règlement : les taux du référentiel, plus ceux corrigés.
  ///
  /// Reconstruit à chaque rendu — il n'y a pas d'état à synchroniser, seulement
  /// une devise par ligne et des taux par paire.
  TenderSettlement _settlement() => TenderSettlement(
    rates: widget.rates,
    // Le taux qui vaut au jour DÉSIGNÉ, pas celui d'aujourd'hui : un
    // encaissement rattrapé trois jours plus tard se propose au taux de ce
    // jour-là — et c'est la même série, à la même date, que le serveur relira
    // pour juger d'un écart. Proposer le taux du jour ferait signaler comme
    // divergent un versement que personne n'a mal converti.
    at: SchoolTime.composeInstant(day: _model.paidDay, now: _now),
    overriddenRates: _rates.overrides,
  );

  /// Le règlement d'une ligne : ce qu'elle éteint, ce que le tiroir garde, et
  /// ce qui repart avec le parent.
  ///
  /// **Le champ que le caissier vient de taper fait foi.** S'il a saisi le
  /// montant posé sur le comptoir, l'imputation se déduit vers le bas et
  /// l'excédent devient de la monnaie à rendre ; s'il a saisi l'imputation, le
  /// comptoir en découle exactement.
  /// Recopie dans le champ du comptoir ce que l'imputation vaut, sans jamais
  /// toucher au champ qui a le curseur.
  /// Les taux à afficher — un par paire réellement convertie.
  List<FacturationRatePair> _ratePairs(TenderSettlement settlement) {
    final seen = <String>{};
    final pairs = <FacturationRatePair>[];
    for (final line in linesOf(settlement, _model.entries)) {
      final rate = line.rate;
      if (rate == null) continue;
      final key = TenderSettlement.pairKey(rate.base, rate.quote);
      if (!seen.add(key)) continue;
      pairs.add(
        FacturationRatePair(
          rate: rate,
          referenceRate: settlement.referenceRateFor(rate.base, rate.quote),
          controller: _rates.controllerOf(key),
          editing: _rates.isEditing(key),
          // `setState` reste ICI : le tableau des taux ne connaît ni widget ni
          // cycle de rendu, il reçoit un rappel et s'en tient là.
          onEdit: () => setState(() => _rates.open(key, rate)),
          diverges: settlement.divergesFor(rate.base, rate.quote),
        ),
      );
    }
    return pairs;
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
    for (final group in _model.groups)
      if (group.allocatedCents > 0)
        FacturationConfirmAllocationGroup(
          label: group.isSingleTranche
              ? chargeDesignation(group.tranches.single.charge, l10n)
              : chargeGroupDesignation(
                  group.asChargeGroup,
                  l10n,
                  schoolTitle: widget.sectionTitles.titleOf(group.feeCode),
                ),
          amount: moneyLabel(group.allocatedCents, group.currency),
          derivedAmount: tenderLabel(
            groupTenderCents(settlement, group),
            group.effectiveTenderCurrency,
          ),
          items: group.isSingleTranche
              ? const []
              : [
                  for (final tranche in group.tranches)
                    if (tranche.effectiveCents > 0)
                      FacturationConfirmAllocationItem(
                        label: chargeDesignation(tranche.charge, l10n),
                        amount: moneyLabel(
                          tranche.effectiveCents,
                          tranche.charge.currency,
                        ),
                        derivedAmount: tenderLabelOf(
                          lineOf(settlement, tranche),
                        ),
                      ),
                ],
        ),
  ];

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
    return rate == null ? null : rateLabel(rate);
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
    return changeLabel(
      group.tenderedCents - groupTenderCents(settlement, group),
      group.effectiveTenderCurrency,
      l10n,
    );
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

  Future<void> _onCollect(AppLocalizations l10n) async {
    // Deux refus, et ils ne disent pas la même chose. Celui-ci est un DROIT —
    // ai-je un payeur valide, un geste n'est-il pas déjà en vol — et il regarde
    // la page. Celui du modèle, juste en dessous, dit qu'il n'y a RIEN à
    // encaisser.
    //
    // Un versement mixte, lui, est un cas NOMINAL depuis que le contrat porte
    // `amounts[]` : c'est un acte de guichet, donc un versement, un reçu.
    if (!_payer.isValid || _collectInFlight) return;

    final draft = _model.buildDraft();
    if (draft == null) return;

    final settlement = _settlement();
    final converted = hasConversion(settlement, _model.entries);
    // Ce qu'on valide est ce que le parent va poser sur le comptoir : la popin
    // annonce le PERÇU, et détaille dessous ce que ce versement éteint.
    final totalLabel = converted
        ? bagLabel(tenderBagOf(settlement, _model.entries))
        : bagLabel(draft.amounts);

    final offlineBloc = context.read<FinanceOfflineBloc>();
    final phone = _payer.phone.text.trim();

    // L'événement est assemblé ICI, et non dans le modèle : `PaymentsCreateRequested`
    // est déclarée dans un `part` de `payments_bloc.dart` et n'est pas
    // importable seule. La faire entrer dans le modèle y ferait entrer le BLoC
    // entier — le modèle rend donc ce qu'il sait en types de domaine, et la page
    // porte la dépendance, là où elle appartient.
    final request = PaymentsCreateRequested(
      studentId: widget.intent.studentId,
      academicYearId: widget.intent.academicYearId,
      paidAt: draft.paidAt,
      amounts: draft.amounts,
      tenders: draft.tenders,
      // Les quatre partent en `null` quand rien n'a été saisi — jamais en `''`.
      // « Pas de payeur » est un fait, pas un nom de longueur zéro : c'est la
      // distinction que le serveur s'est donnée en V114, et une chaîne vide la
      // ferait disparaître dès la première écriture.
      payerFirstName: _payer.valueOf(_payer.firstName),
      payerLastName: _payer.valueOf(_payer.lastName),
      payerMiddleName: _payer.valueOf(_payer.middleName),
      payerPhoneNumber: _payer.valueOf(_payer.phone),
      allocations: draft.allocations,
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
      rateLabel: singleRateLabel(linesOf(settlement, _model.entries)),
      studentName: studentFullName(widget.intent, l10n),
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
    final allocations = settledBagOf(settlement, _model.entries);
    final canCollect =
        _payer.isValid &&
        !allocations.isAllZero &&
        !_collectInFlight &&
        !tenderInvariantBroken(settlement, _model.entries);
    // « Converti » n'est pas « une devise a été choisie » : régler en dollars
    // des créances en dollars n'est pas une conversion. Ce qui compte est qu'un
    // taux s'applique réellement quelque part — sinon la barre annoncerait « À
    // percevoir » sur un versement où rien n'a bougé d'unité.
    final converted = hasConversion(settlement, _model.entries);

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
          fullName: studentFullName(widget.intent, l10n),
          eyebrow:
              '${l10n.facturationCreatePaymentEyebrow} · '
              '${classLabel(widget.intent, l10n)}',
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
                    ? bagLabel(tenderBagOf(settlement, _model.entries))
                    : bagLabel(allocations),
                settledLabel: converted ? bagLabel(allocations) : null,
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
        // La date a sa propre section : elle ne dit rien de qui paie, et la
        // loger sous l'identité du payeur obligeait à expliquer en commentaire
        // pourquoi elle échappait à la mention « facultatif » qui la précédait.
        FinanceSectionCard(
          backgroundColor: AppColors.surfaceRaised,
          borderColor: AppColors.border,
          child: FacturationCreatePaymentDateSection(
            paidAt: _model.paidDay,
            firstPaidAt: _firstSelectableDay,
            lastPaidAt: _model.today,
            onPaidAtChanged: _collectInFlight
                ? null
                : (day) => _act(() => _model.paidDayChanged(day)),
            readOnly: _collectInFlight,
          ),
        ),
        const SizedBox(height: AppDimensions.detailSectionSpacing),
        FacturationCreatePaymentChargesSection(
          groups: _model.groups,
          schoolTitleOf: widget.sectionTitles.titleOf,
          onGroupToggle: _collectInFlight
              ? null
              : (group, value) => _act(() => _model.groupToggle(group, value)),
          onGroupSettleAll: _collectInFlight
              ? null
              : (group) => _act(() => _model.groupSettleAll(group)),
          onGroupAmountEdited: _collectInFlight
              ? null
              : (group) => _act(() => _model.groupAmountEdited(group)),
          onGroupTenderEdited: _collectInFlight
              ? null
              : (group) => _act(() => _model.groupTenderEdited(group)),
          onGroupToggleExpanded: _collectInFlight
              ? null
              : (group) => _act(() => _model.groupToggleExpanded(group)),
          onGroupTenderCurrencyChanged: _collectInFlight
              ? null
              : (group, currency) => _act(
                  () => _model.groupTenderCurrencyChanged(group, currency),
                ),
          groupCurrencyOptionsOf: (group) =>
              settlement.optionsFor(group.currency),
          groupRateLabelOf: (group) => _groupRateLabel(settlement, group),
          groupChangeLabelOf: (group) =>
              _groupChangeLabel(settlement, group, l10n),
          onToggle: _collectInFlight
              ? null
              : (entry, value) => _act(() => _model.toggle(entry, value)),
          onSettleAll: _collectInFlight
              ? null
              : (entry) => _act(() => _model.settleAll(entry)),
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
            explainWhenUnavailable: hasNoConvertibleCharge(
              settlement,
              _model.entries,
            ),
          ),
          currencyOptionsOf: (entry) =>
              settlement.optionsFor(entry.charge.currency),
          onTenderCurrencyChanged: _collectInFlight
              ? null
              : (entry, currency) =>
                    _act(() => _model.tenderCurrencyChanged(entry, currency)),
          onAllocationEdited: _collectInFlight
              ? null
              : (entry) => _act(() => _model.allocationEdited(entry)),
          onTenderEdited: _collectInFlight
              ? null
              : (entry) => _act(() => _model.tenderEdited(entry)),
          rateLabelOf: (entry) => lineRateLabel(lineOf(settlement, entry)),
          changeLabelOf: (entry) =>
              lineChangeLabel(lineOf(settlement, entry), l10n),
        ),
      ],
    );
  }
}
