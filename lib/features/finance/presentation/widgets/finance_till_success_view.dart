import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_empty_state.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_imputation_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_freshness_caption.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_cash_boxes.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_classroom_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_currency_selector.dart';
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

  const FinanceTillSuccessView({
    super.key,
    required this.till,
    required this.selectedBlock,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = selectedBlock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WindowCaption(till: till, l10n: l10n),
        const SizedBox(height: AppDimensions.spacingM),
        if (till.encaisse.isEmpty)
          // Ni catalogue, ni grille, ni mouvement : le serveur ne renvoie aucun
          // bloc. C'est un état vide, pas une erreur — et surtout pas un zéro
          // dans une unité que personne n'a choisie.
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingXL,
            ),
            child: EteeloEmptyResult(
              label: l10n.financeStatsNoMovementLabel,
              description: l10n.financeStatsNoMovementDescription,
              medallionIcon: Icons.point_of_sale_outlined,
            ),
          )
        else ...[
          FinanceTillCashBoxes(
            till: till,
            windowLabel: _windowLabel(till, l10n),
          ),
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
            if (selected.hasNoMovement)
              _CurrencyNoMovement(l10n: l10n)
            else ...[
              FinanceTillBucketsSection(
                title: l10n.financeTillBucketsHeading(
                  tillCurrencyName(selected.currency, l10n),
                ),
                buckets: selected.buckets,
                // Le grain vient du serveur : une tranche hebdomadaire porte
                // une clé de la même forme qu'une journée.
                granularity: till.granularity,
                // La série déborde la fenêtre comptée sur la journée seulement.
                // La note vit à côté du graphique, là où l'écart se voit.
                windowNote: till.context.period == 'day'
                    ? l10n.financeTillBucketsWindowNote
                    : null,
              ),
              const SizedBox(height: AppDimensions.spacingL),
              // Deux lectures de la même somme : d'où vient l'argent, puis quelle
              // classe l'a versé. Toutes deux dans la devise de la caisse
              // détaillée — aucune conversion nulle part.
              FinanceTillSourceSection(block: selected),
              const SizedBox(height: AppDimensions.spacingL),
              FinanceTillClassroomSection(block: selected),
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
          // La ventilation par poste n'est plus une colonne du bloc de devise
          // reçue : elle se compte dans la devise des créances. Elle descend
          // donc sous son propre titre, qui nomme l'unité — la seule chose qui
          // empêche de lire un total commun là où il n'en existe aucun.
          if (till.impute.isNotEmpty || _hasFees(till)) ...[
            _ImputationHeading(l10n: l10n),
            const SizedBox(height: AppDimensions.spacingM),
            if (till.impute.isEmpty)
              // Des frais sont entrés sans qu'aucune imputation ne descende :
              // on le montre sous le titre, plutôt que d'escamoter la section,
              // où la lacune passerait pour une journée sans frais.
              FinanceStatsEmptyState(
                message: l10n.financeStatsNoData,
                hint: l10n.financeStatsNoDataHint,
                semanticLabel: l10n.financeStatsEmptyA11yLabel,
              )
            else
              for (final imputation in till.impute) ...[
                FinanceTillImputationSection(imputation: imputation),
                const SizedBox(height: AppDimensions.spacingL),
              ],
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

/// Sépare les deux unités de l'écran, et nomme celle qui commence.
///
/// Sans ce titre, les montants du bas se lisent dans la continuité de la bande
/// KPI — c'est-à-dire dans la mauvaise devise, et sur un total qui n'existe pas.
class _ImputationHeading extends StatelessWidget {
  final AppLocalizations l10n;

  const _ImputationHeading({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.financeTillImputationHeading,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          l10n.financeTillImputationHint,
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

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

/// Une devise dans laquelle l'école facture ou vend, sans qu'un franc y ait
/// circulé sur la fenêtre.
///
/// **Le cas le plus fréquent de l'onglet** : le serveur garde ces blocs à zéro
/// plutôt que de les omettre, et une journée creuse en rendrait autant que
/// l'école a de devises.
class _CurrencyNoMovement extends StatelessWidget {
  final AppLocalizations l10n;

  const _CurrencyNoMovement({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${l10n.financeStatsCurrencyNoMovement}. '
          '${l10n.financeStatsCurrencyNoMovementTill}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.point_of_sale_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.financeStatsCurrencyNoMovement,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.financeStatsCurrencyNoMovementTill,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
