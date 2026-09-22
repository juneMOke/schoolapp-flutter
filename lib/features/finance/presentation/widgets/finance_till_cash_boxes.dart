import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/finance_till_tones.dart';
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

  /// Les largeurs de base de la spec : une caisse contre le compteur.
  /// Gabarit d'une tuile de caisse — `flex 1 1 260` dans la spec.
  ///
  /// Public parce que le squelette s'en sert : il doit occuper **les mêmes
  /// places**, et deux copies du gabarit se décaleraient au premier ajustement.
  static const double cashBoxBasis = 260;

  /// Gabarit de la tuile « Reçus émis » — `flex 1 1 190`, plus étroite parce
  /// qu'elle ne porte pas un montant.
  static const double counterBasis = 190;

  /// Quand la rangée ne tient pas, les tuiles s'enroulent **à largeur égale** :
  /// un rapport de largeurs n'a plus de sens sur plusieurs rangs, où les tuiles
  /// ne se comparent plus du regard.
  static double _wrappedWidth(double maxWidth, int count, double spacing) {
    final columns = EteeloKpiBand.columnsFor(maxWidth, count);
    return ((maxWidth - spacing * (columns - 1)) / columns).floorToDouble();
  }

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

          // **La tuile du compteur est plus étroite que les caisses** — la spec
          // leur donne `flex 1 1 260` et `1 1 190`. Ce n'est pas cosmétique :
          // trois tuiles de largeur égale se lisent comme trois chiffres de
          // même rang, alors que le compteur n'est pas un montant.
          final gutters = spacing * (count - 1);
          final fitsOneRow =
              constraints.maxWidth >=
              cashBoxBasis * blocks.length + counterBasis + gutters;

          final available = constraints.maxWidth - gutters;
          final basisTotal = cashBoxBasis * blocks.length + counterBasis;
          final cashWidth = fitsOneRow
              ? (available * cashBoxBasis / basisTotal).floorToDouble()
              : _wrappedWidth(constraints.maxWidth, count, spacing);
          final counterWidth = fitsOneRow
              ? (available * counterBasis / basisTotal).floorToDouble()
              : cashWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final block in blocks)
                    SizedBox(
                      width: cashWidth,
                      child: _CashBox(
                        block: block,
                        windowLabel: windowLabel,
                        l10n: l10n,
                      ),
                    ),
                  SizedBox(
                    width: counterWidth,
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
    final summary = block.summary;

    return Container(
      decoration: BoxDecoration(
        // **Le pavé entier porte la devise**, là où un liseré haut de 3 dp la
        // portait seul. Ce liseré disparaît donc : de la couleur de l'accent
        // sur un fond qui est ce même accent assombri, il ne se verrait plus.
        //
        // La doctrine de l'écran ne change pas — la teinte repère, elle
        // n'informe pas : le symbole de la devise reste dans le montant, et le
        // libellé la nomme en toutes lettres.
        color: FinanceTillTones.paveDeCaisse(block.currency),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        boxShadow: DashboardTones.paveShadow,
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
              // Sur un pavé, le médaillon devient un voile clair et son glyphe
              // l'or **clair** : `orDoux` tomberait à 3,00 sur le pavé dollars
              // et 2,33 sur le pavé francs, sous le seuil des objets
              // graphiques.
              _Medallion(
                icon: Icons.account_balance_wallet_outlined,
                accent: AppColors.orSurPave,
                surface: AppColors.insInkMain.withValues(
                  alpha: FinanceTillTones.voileMedaillon,
                ),
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
                    color: DashboardTones.inkLibelle,
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
              color: DashboardTones.inkValeur,
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
              // Deux tuiles côte à côte, deux sous-lignes de même forme : sans
              // chiffres tabulaires, « 5 reçus · ticket moyen 246,90 $ » et
              // « 17 reçus · ticket moyen 1 118,00 FC » ne se comparent pas
              // d'un coup d'œil — c'est pourtant le geste que la bande invite
              // à faire.
              style: AppTextStyles.caption.copyWith(
                color: DashboardTones.inkSousLigne,
                fontFeatures: AppTextStyles.tabularFigures,
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
              style: AppTextStyles.caption.copyWith(
                color: DashboardTones.inkSousLigne,
              ),
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
    // ⚠️ **Pas `vertSavane` / `error`.** Ces deux teintes disaient la hausse et
    // la baisse sur une tuile blanche ; sur le pavé elles tombent à 1,63 et
    // 1,85 (dollars), 1,21 et 1,38 (francs) — la ligne devient invisible, pas
    // seulement difficile. Les deux nuances claires tiennent de 5,43 à 7,95.
    final color = rising
        ? FinanceTillTones.inkTendanceHausse
        : FinanceTillTones.inkTendanceBaisse;

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
        // L'ocre, et non le neutre d'avant ni une teinte de devise. Ce que la
        // neutralité disait — « ce n'est pas un montant, ne le comparez pas
        // aux deux caisses » — l'ocre le dit aussi, en étant la seule des trois
        // teintes qui n'appartient à aucune devise.
        color: FinanceTillTones.paveDesRecus,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        boxShadow: DashboardTones.paveShadow,
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
              // Même voile et même or que les deux caisses : ce qui distingue
              // cette tuile est la teinte de son pavé, pas son médaillon.
              _Medallion(
                icon: Icons.receipt_long_outlined,
                accent: AppColors.orSurPave,
                surface: AppColors.insInkMain.withValues(
                  alpha: FinanceTillTones.voileMedaillon,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.financeTillReceiptsIssuedLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: DashboardTones.inkLibelle,
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
              color: DashboardTones.inkValeur,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Text(
            l10n.financeTillReceiptsIssuedSubline,
            style: AppTextStyles.caption.copyWith(
              color: DashboardTones.inkSousLigne,
            ),
          ),
        ],
      ),
    );
  }
}
