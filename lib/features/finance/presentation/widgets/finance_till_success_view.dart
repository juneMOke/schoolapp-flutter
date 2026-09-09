import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_imputation_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_freshness_caption.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_cash_boxes.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_classroom_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_currency_selector.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_empty_states.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_insights_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_receipts_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_source_section.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui est entré dans le tiroir sur la fenêtre — **puis ce que ça a
/// éteint**.
///
/// Même composition que le recouvrement — bande KPI commune, puis un jeu de
/// sections par devise — parce que c'est le même écran et qu'il se lit de la
/// même façon. Ce qui diffère est ce qu'on y compte : ici rien n'est dû, rien
/// n'est attendu, et la moitié boutique existe.
///
/// **L'écran porte deux unités, et il le dit.** Le haut compte en devise
/// **reçue** : c'est ce que le caissier rapproche de ses billets. Le bas compte
/// en devise de **créance** : c'est ce que la direction lit. Les deux ne
/// s'additionnent pas — un même versement de 115 000 FC qui solde 50 USD pèse
/// en haut dans le bloc CDF et en bas dans le bloc USD — d'où la séparation
/// franche, un titre qui nomme l'unité, et aucun total commun nulle part.
class FinanceTillSuccessView extends StatelessWidget {
  final FinanceTill till;

  /// La caisse détaillée sous les tuiles. `null` quand la réponse ne porte aucun
  /// bloc — l'état vide global parle alors à sa place.
  final TillCurrencyBlock? selectedBlock;

  /// Le geste de bascule. Remonté plutôt que traité ici : la sélection vit dans
  /// le BLoC, avec la réponse qu'elle découpe.
  final ValueChanged<String> onCurrencySelected;

  /// L'élargissement de fenêtre offert par le vide global — remonté pour la
  /// même raison que la bascule.
  ///
  /// Il passe par le **même événement** que le sélecteur de période, si bien
  /// que le segment suit : celui-ci se lit sur `state.selectedWindow`, et une
  /// requête posée d'ici bougerait la donnée sans bouger le contrôle si elle
  /// empruntait un autre chemin.
  final ValueChanged<TillWindow> onWindowRequested;

  const FinanceTillSuccessView({
    super.key,
    required this.till,
    required this.selectedBlock,
    required this.onCurrencySelected,
    required this.onWindowRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = selectedBlock;

    final windowLabel = _windowLabel(till, l10n);
    // **Le vide global se lit sur les blocs, pas sur le compteur.** Le contrat
    // porte bien un `receiptsIssued` toutes caisses, mais s'y fier ferait
    // dépendre l'affichage d'un agrégat : un compteur à zéro en désaccord avec
    // des blocs pleins **cacherait des caisses qui ont travaillé**. Dérivé de
    // ce qui est affiché, ce test-ci ne peut pas mentir dans ce sens-là.
    //
    // `every` sur une liste vide vaut vrai : le cas « le serveur ne renvoie
    // aucun bloc » tombe dans la même branche, sans condition supplémentaire.
    final globallyEmpty = till.encaisse.every(
      (block) => block.summary.hasNoReceipts,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WindowCaption(till: till, l10n: l10n),
        const SizedBox(height: AppDimensions.spacingM),
        if (globallyEmpty) ...[
          // ⚠️ **Les tuiles restent, à zéro** — « le repère de lecture ne
          // disparaît pas ». Un écran qui les retirerait ferait perdre au
          // lecteur les deux devises de son école au moment précis où il se
          // demande s'il regarde le bon endroit.
          //
          // Elles n'existent que si le serveur a rendu des blocs : sans bloc,
          // on ne connaît même pas les devises, et une tuile inventée serait
          // pire que pas de tuile.
          if (till.encaisse.isNotEmpty) ...[
            FinanceTillCashBoxes(till: till, windowLabel: windowLabel),
            const SizedBox(height: AppDimensions.spacingS),
            const FinanceTillFreshnessCaption(),
            const SizedBox(height: AppDimensions.spacingXL),
          ],
          // Le sélecteur et tout le détail ne sont pas rendus : il n'y a pas de
          // caisse à détailler, et un sélecteur à deux segments vides
          // proposerait de choisir entre deux riens.
          FinanceTillGlobalEmpty(
            windowLabel: windowLabel,
            period: till.context.period,
            onWindowRequested: onWindowRequested,
          ),
          const SizedBox(height: AppDimensions.spacingXL),
        ] else ...[
          FinanceTillCashBoxes(till: till, windowLabel: windowLabel),
          const SizedBox(height: AppDimensions.spacingS),
          const FinanceTillFreshnessCaption(),
          const SizedBox(height: AppDimensions.spacingXL),
          // Tout ce qui suit décrit **une seule** caisse — d'où la coupure de
          // lecture marquée, et un sélecteur qui se lit comme un titre.
          FinanceTillCurrencySelector(
            blocks: till.encaisse,
            selectedCurrency: selected?.currency ?? '',
            onSelected: onCurrencySelected,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          if (selected != null) ...[
            // ⚠️ **Le compte de reçus, et non le total.** Une caisse qui a
            // encaissé puis remboursé le même montant a bien travaillé ; lui
            // écrire « aucun paiement n'a été tendu » serait faux, et c'est ce
            // que disait le total à zéro.
            if (selected.summary.hasNoReceipts)
              FinanceTillCurrencyEmpty(
                selected: selected,
                others: [
                  for (final block in tillBlocksInDisplayOrder(till.encaisse))
                    if (block.currency != selected.currency &&
                        !block.summary.hasNoReceipts)
                      block,
                ],
                windowLabel: windowLabel,
                onCurrencySelected: onCurrencySelected,
              )
            else ...[
              FinanceTillBucketsSection(
                title: l10n.financeTillBucketsHeading(
                  tillCurrencyName(selected.currency, l10n),
                ),
                buckets: selected.buckets,
                // Le grain vient du serveur : une tranche hebdomadaire porte
                // une clé de la même forme qu'une journée.
                granularity: till.granularity,
                currency: selected.currency,
                // La série déborde la fenêtre comptée sur la journée seulement.
                // La note vit à côté du graphique, là où l'écart se voit.
                windowNote: till.context.period == 'day'
                    ? l10n.financeTillBucketsWindowNote
                    : null,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // **D'où vient l'argent, sur toute la largeur.**
              //
              // Elle occupait auparavant la moitié d'une ligne, l'imputation
              // tenant l'autre. Les deux ne comptent pas dans la même unité —
              // celle-ci en devise **reçue**, l'imputation en devise de
              // **créance** — et leur voisinage invitait à lire un total commun
              // qui n'existe pas. Empilées, chacune garde sa ligne et son
              // unité ; elle suit ici le graphique et les tuiles, qui comptent
              // comme elle.
              //
              // Ce qu'on y perd, et qu'il faut savoir : le rapprochement d'un
              // coup d'œil entre « d'où ça vient » et « ce que ça a éteint »
              // demande maintenant de descendre d'une carte.
              FinanceTillSourceSection(block: selected),
              const SizedBox(height: AppDimensions.spacingL),
              if (_showsImputation(till)) ...[
                _ImputationRow(till: till),
                const SizedBox(height: AppDimensions.spacingL),
              ],
              FinanceTillClassroomSection(block: selected),
              const SizedBox(height: AppDimensions.spacingL),
              // Ce que les chiffres veulent dire — et ce qu'il n'y a pas à en
              // faire : aucune de ces cartes n'expose de bouton, la décision se
              // prend en Facturation.
              FinanceTillInsightsSection(till: till, block: selected),
              const SizedBox(height: AppDimensions.spacingL),
              // La preuve, en dernier. Son BLoC est distinct : un 403 ici —
              // droit de pilotage sans droit nominatif — laisse tout ce qui
              // précède à l'écran.
              FinanceTillReceiptsSection(
                tillTotal: MoneyFormat.format(
                  Money.parse(selected.summary.total, selected.currency),
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.spacingXL),
          ],
        ],
      ],
    );
  }
}

/// Des frais sont entrés dans le tiroir sur la fenêtre — donc quelque chose a
/// été imputé, et l'absence de bloc d'imputation est une lacune, pas un état.
bool _hasFees(FinanceTill till) =>
    till.encaisse.any((block) => block.summary.fees > 0);

/// La rangée des créances a-t-elle quelque chose à dire ?
///
/// Elle existe soit parce que le serveur a rendu des imputations, soit parce
/// qu'il n'en a rendu aucune **alors que des frais sont entrés** — auquel cas
/// c'est la lacune qui s'affiche. Une journée sans frais, elle, n'a rien à
/// montrer : la rangée disparaît, plutôt que d'annoncer un vide qui n'en est
/// pas un.
bool _showsImputation(FinanceTill till) =>
    till.impute.isNotEmpty || _hasFees(till);

/// **Les créances éteintes, une carte par devise**, côte à côte.
///
/// Le serveur rend une carte par devise de **créance** : une école qui facture
/// en dollars et en francs en a deux, et elles se lisent l'une contre l'autre —
/// « ce que la journée a éteint, ici et là ». Empilées, la comparaison
/// demandait de faire défiler ; côte à côte, elle se fait d'un coup d'œil.
///
/// ⚠️ **Aucune des deux ne s'additionne à l'autre**, et rien n'affiche leur
/// somme : ce sont deux monnaies de créance, pas deux moitiés d'un total. C'est
/// le titre de chaque carte qui porte cette garde — il nomme sa devise — et
/// c'est pourquoi il n'est jamais escamoté.
///
/// En dessous de deux minima, les cartes retombent l'une sous l'autre : une
/// comparaison illisible ne vaut pas mieux qu'un empilement.
class _ImputationRow extends StatelessWidget {
  final FinanceTill till;

  const _ImputationRow({required this.till});

  /// Le minimum de la spec pour une carte d'imputation. En dessous, les libellés
  /// de poste et leur montant se marchent dessus.
  static const double _minCardWidth = 380;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Des frais sont entrés sans qu'aucune imputation ne descende : on le
    // montre, plutôt que d'escamoter la carte — où la lacune passerait pour une
    // journée sans frais. Le cas « ni frais ni imputation » ne parvient pas
    // jusqu'ici : [_showsImputation] a déjà retiré la rangée.
    if (till.impute.isEmpty) {
      return FinanceStatsEmptyState(
        message: l10n.financeStatsNoData,
        hint: l10n.financeStatsNoDataHint,
        semanticLabel: l10n.financeStatsEmptyA11yLabel,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gutter = AppDimensions.spacingL;
        final sideBySide =
            till.impute.length > 1 &&
            constraints.maxWidth >= _minCardWidth * 2 + gutter;
        final width = sideBySide
            ? (constraints.maxWidth - gutter) / 2
            : constraints.maxWidth;

        // Un [Wrap] plutôt qu'une [Row] : une troisième devise de créance —
        // improbable, mais le contrat ne l'interdit pas — passe à la ligne au
        // lieu de comprimer les deux premières.
        return Wrap(
          spacing: gutter,
          runSpacing: gutter,
          children: [
            for (final imputation in till.impute)
              SizedBox(
                width: width,
                child: FinanceTillImputationSection(imputation: imputation),
              ),
          ],
        );
      },
    );
  }
}

/// Le libellé de la fenêtre, **lu sur la réponse et non sur le sélecteur**.
///
/// Pendant un changement de grain, l'onglet a déjà bougé alors que les chiffres
/// affichés sont encore ceux d'avant : suffixer les caisses avec le grain
/// *demandé* daterait le montant d'une fenêtre qui ne l'a pas produit.
/// `context.period` vient du serveur, avec les totaux qu'il décrit.
///
/// Une valeur inconnue retombe sur la chaîne du serveur plutôt que sur un
/// générique : mieux vaut afficher `custom` que « période », qui ne désigne
/// rien.
String _windowLabel(FinanceTill till, AppLocalizations l10n) =>
    switch (till.context.period) {
      'day' => l10n.financeTillPeriodDayCurrent,
      'week' => l10n.financeStatsPeriodWeekCurrent,
      'month' => l10n.financeStatsPeriodMonthCurrent,
      'year' => l10n.financeStatsPeriodYearCurrent,
      final other => other,
    };

/// De quelle fenêtre parle le total, et dans quel fuseau elle se découpe.
///
/// **Les bornes viennent du serveur** (`context.periodStart` / `periodEnd`),
/// jamais d'un `DateTime.now()` local : une journée de caisse commence et finit
/// dans le fuseau de l'école, et un encaissement sonné à 00 h 20 au guichet
/// porte un instant serveur de 23 h 20 Z la veille. Refaire la borne côté
/// tablette ferait diverger le total affiché de celui du serveur les nuits de
/// fin de journée.
class _WindowCaption extends StatelessWidget {
  final FinanceTill till;
  final AppLocalizations l10n;

  const _WindowCaption({required this.till, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);
    final start = materialL10n.formatMediumDate(till.context.periodStart);
    final end = materialL10n.formatMediumDate(till.context.periodEnd);
    final window = till.context.periodStart == till.context.periodEnd
        ? l10n.financeTillWindowDay(start)
        : l10n.financeTillWindow(start, end);

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          window,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (till.hasTimeZone)
          Text(
            l10n.financeTillTimeZoneHint(till.timeZone),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}
