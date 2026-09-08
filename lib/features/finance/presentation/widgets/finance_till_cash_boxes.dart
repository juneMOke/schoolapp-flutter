import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Les deux seuls chiffres à retenir** — une caisse par devise, côte à côte,
/// et jamais un total combiné.
///
/// « Caisse » veut dire *ce qui a réellement été tendu au guichet*. Un frais
/// fixé en dollars peut être réglé en francs : il entre alors dans la caisse
/// **francs**, tout en soldant la créance en dollars. Les additionner
/// demanderait un taux de change — donc de fabriquer un montant que personne ne
/// peut recompter sur un tiroir de billets.
///
/// Une troisième tuile, **neutre**, compte les reçus émis toutes caisses. C'est
/// le seul agrégat inter-devises légitime de l'écran, parce que c'est un
/// **compteur** et non un montant.
///
/// ## Ce que cette bande remplace
///
/// Elle succède à une bande de trois cartes — total, frais, boutique — qui
/// empilait une ligne par devise dans chaque carte. La ventilation frais /
/// boutique n'a pas disparu : elle descend sous « Par source », où la spec la
/// place, parce qu'elle répond à « d'où vient l'argent » et non à « combien est
/// entré ».
class FinanceTillCashBoxes extends StatelessWidget {
  final FinanceTill till;

  /// Le libellé de la fenêtre — « aujourd'hui », « cette semaine ». Il suffixe
  /// chaque caisse : un montant de caisse sans sa fenêtre est illisible, et
  /// c'est la première chose qu'on cherche à vérifier après une bascule.
  final String windowLabel;

  const FinanceTillCashBoxes({
    super.key,
    required this.till,
    required this.windowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocks = tillBlocksInDisplayOrder(till.encaisse);

    return Semantics(
      container: true,
      label: l10n.financeTillCashBoxesA11yLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppDimensions.spacingM;
          final count = blocks.length + 1;
          final columns = EteeloKpiBand.columnsFor(constraints.maxWidth, count);
          final width =
              ((constraints.maxWidth - spacing * (columns - 1)) / columns)
                  .floorToDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final block in blocks)
                    SizedBox(
                      width: width,
                      child: _CashBox(
                        block: block,
                        windowLabel: windowLabel,
                        l10n: l10n,
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: _ReceiptsIssuedTile(till: till, l10n: l10n),
                  ),
                ],
              ),
              // ⚠️ **L'explication vit SOUS la rangée, pas dans la tuile.**
              // Portée par la carte « Reçus émis », elle la faisait gonfler
              // d'un tiers face aux deux tuiles de caisse : trois tuiles de
              // même rang cessaient d'avoir le même poids visuel, et la plus
              // haute attirait l'œil sur le chiffre le moins important. Sous la
              // rangée, elle commente les trois — ce qu'elle fait réellement,
              // puisqu'elle parle du rapport entre elles.
              if (_hasMixedBaskets(till)) ...[
                const SizedBox(height: AppDimensions.spacingS),
                _MixedBasketsNote(l10n: l10n),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// La somme des compteurs de caisse dépasse le nombre de reçus émis — donc au
/// moins un versement a été réglé dans les deux devises.
///
/// C'est **la condition d'affichage de la note** : sur une fenêtre sans panier
/// mixte les trois chiffres s'accordent, et une phrase qui explique un écart
/// absent en crée un.
bool _hasMixedBaskets(FinanceTill till) =>
    till.encaisse.fold<int>(
      0,
      (sum, block) => sum + block.summary.receiptCount,
    ) >
    till.receiptsIssued;

/// Ce que « 5 » et « 3 » au-dessus de « 7 » veulent dire.
///
/// Un reçu compte **une fois par caisse qu'il a alimentée** dans les tuiles de
/// gauche, et **une seule fois** dans le compteur : les trois ont raison, et
/// c'est leur rapport qui a besoin d'être dit — d'où sa place sous la rangée
/// entière plutôt que dans l'une des trois tuiles.
class _MixedBasketsNote extends StatelessWidget {
  final AppLocalizations l10n;

  const _MixedBasketsNote({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
        const SizedBox(width: AppDimensions.spacingXS),
        Expanded(
          child: Text(
            l10n.financeTillReceiptsIssuedMixedNote,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Une caisse : son montant, ce qui l'a produit, et son écart à la veille.
class _CashBox extends StatelessWidget {
  final TillCurrencyBlock block;
  final String windowLabel;
  final AppLocalizations l10n;

  const _CashBox({
    required this.block,
    required this.windowLabel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tillCurrencyAccent(block.currency);
    final summary = block.summary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border(
          // Bord **haut**, et non latéral comme les cartes KPI du socle : c'est
          // le seul marqueur chromatique de devise, et il est toujours doublé
          // du symbole dans le montant — la couleur ne porte jamais seule
          // l'information de devise.
          top: BorderSide(color: accent, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingL,
        AppDimensions.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Le médaillon de la maquette : la teinte de la caisse, doublée
              // partout du symbole dans le montant.
              _Medallion(
                icon: Icons.account_balance_wallet_outlined,
                accent: accent,
                surface: tillCurrencySoftAccent(block.currency),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.financeTillCashBoxLabel(
                    tillCurrencyName(block.currency, l10n),
                    windowLabel,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            MoneyFormat.format(Money.parse(summary.total, block.currency)),
            style: AppTextStyles.totalAmountLora.copyWith(
              fontSize: 34,
              height: 1.05,
              color: accent,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          // Le ticket moyen se tait sur une caisse sans reçu : « ticket moyen
          // 0 » se lirait comme une mesure, quand il n'y a rien à diviser.
          if (!summary.hasNoReceipts)
            Text(
              l10n.financeTillCashBoxSubline(
                summary.receiptCount,
                l10n.financeTillReceiptCount(summary.receiptCount),
                MoneyFormat.format(
                  Money.parse(summary.averageTicket, block.currency),
                ),
              ),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          if (summary.hasTrend) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            _Trend(percent: summary.trendPercent!, l10n: l10n),
          ]
          // Deux silences très différents. Ici la comparaison est IMPOSSIBLE —
          // la période antérieure tomberait avant la rentrée — et la tuile le
          // dit, sinon elle perd son delta tous les jours de septembre sans
          // raison visible. Une période précédente simplement vide, elle, ne
          // dit rien : l'absence se comprend d'elle-même.
          else if (summary.explainsMissingTrend) ...[
            const SizedBox(height: AppDimensions.spacingXS),
            Text(
              l10n.financeTillCashBoxNoComparablePeriod,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Le médaillon d'une tuile — 26 dp, comme la maquette le dessine.
class _Medallion extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color surface;

  const _Medallion({
    required this.icon,
    required this.accent,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Icon(icon, size: 15, color: accent),
    );
  }
}

/// L'écart à la période précédente de même durée.
///
/// **Rendu seulement quand il a été mesuré.** Un `trendPercent` nul veut dire
/// que la période précédente était vide — ou qu'elle sortait de l'année
/// scolaire, et le serveur refuse alors de comparer deux campagnes de frais.
/// Écrire « 0 % » annoncerait une stabilité que personne n'a observée ; la
/// ligne disparaît au lieu de mentir.
class _Trend extends StatelessWidget {
  final int percent;
  final AppLocalizations l10n;

  const _Trend({required this.percent, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final rising = percent >= 0;
    final color = rising ? AppColors.vertSavane : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Une seule icône, retournée à la baisse : deux glyphes distincts
        // divergeraient de graisse et d'inclinaison entre les deux sens.
        Transform.scale(
          scaleY: rising ? 1 : -1,
          child: Icon(Icons.trending_up_rounded, size: 14, color: color),
        ),
        const SizedBox(width: AppDimensions.spacingXS),
        Flexible(
          child: Text(
            l10n.financeTillCashBoxTrend(percent.abs()),
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Les reçus émis sur la fenêtre — **un compteur, pas un montant**.
///
/// Neutre de teinte, délibérément : lui donner une couleur de devise le rendrait
/// comparable aux deux caisses, alors qu'il ne compte pas dans la même unité.
///
/// ## Pourquoi la note sous le chiffre est nécessaire
///
/// Un reçu compte **une fois par caisse qu'il a alimentée** dans les tuiles de
/// gauche, et **une seule fois** ici. Un versement payé moitié en francs,
/// moitié en dollars entre donc dans les deux compteurs de caisse et une fois
/// dans celui-ci : « 5 reçus » et « 3 reçus » au-dessus de « 7 reçus émis » ont
/// raison tous les trois et paraissent faux. Sans la note, le lecteur cherche
/// l'erreur — et la seule qu'il puisse trouver serait d'additionner.
class _ReceiptsIssuedTile extends StatelessWidget {
  final FinanceTill till;
  final AppLocalizations l10n;

  const _ReceiptsIssuedTile({required this.till, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingL,
        AppDimensions.spacingM,
        AppDimensions.spacingL,
        AppDimensions.spacingM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Médaillon **neutre** : lui donner une teinte de devise le
              // rendrait comparable aux deux caisses, alors qu'il ne compte pas
              // dans la même unité.
              const _Medallion(
                icon: Icons.receipt_long_outlined,
                accent: AppColors.textSecondary,
                surface: AppColors.surfaceAlt,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.financeTillReceiptsIssuedLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.06 * 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            '${till.receiptsIssued}',
            style: AppTextStyles.totalAmountLora.copyWith(
              fontSize: 34,
              height: 1.05,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.financeTillReceiptsIssuedSubline,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
