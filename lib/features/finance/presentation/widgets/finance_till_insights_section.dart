import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Ce que les chiffres veulent dire** — et ce qu'il n'y a pas à en faire.
///
/// Quatre lectures. Trois sont toujours rendues, avec une formulation de repli
/// quand le cas est vide : une carte qui disparaît laisse croire qu'on a oublié
/// de regarder, alors qu'« aucun paiement croisé » est une information.
///
/// ## Aucune de ces cartes n'expose de bouton
///
/// Elles **expliquent** ; la décision se prend en Facturation. Un bouton ici
/// promettrait une action que cet écran n'a pas — il est en lecture seule, et
/// c'est le même refus que la ligne de reçu non cliquable.
class FinanceTillInsightsSection extends StatelessWidget {
  final FinanceTill till;

  /// La caisse détaillée — trois des quatre cartes parlent d'elle.
  final TillCurrencyBlock block;

  const FinanceTillInsightsSection({
    super.key,
    required this.till,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.financeTillInsightsHeading,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppDimensions.spacingM;
            // Deux colonnes dès que 260 dp tiennent deux fois : la spec donne
            // `flex 1 1 260` à chaque carte.
            final twoUp = constraints.maxWidth >= 260 * 2 + spacing;
            final width = twoUp
                ? (constraints.maxWidth - spacing) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in _cards(context, l10n))
                  SizedBox(width: width, child: card),
              ],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _cards(BuildContext context, AppLocalizations l10n) => [
    _crossedCard(l10n),
    if (block.bestBucket != null)
      _bestDayCard(context, l10n, block.bestBucket!),
    _boutiqueCard(l10n),
    if (block.summary.hasTrend) _trendCard(l10n, block.summary.trendPercent!),
  ];

  /// **Les paiements croisés — portée ÉCRAN, pas caisse.**
  ///
  /// ⚠️ Le serveur construit ce bloc une fois pour toute la fenêtre : `count`
  /// compte les lignes croisées **toutes caisses**, et `amounts` en donne une
  /// entrée **par devise reçue**. La carte reprend donc les deux à cette
  /// portée-là — mélanger un compte global et un montant de la seule caisse
  /// détaillée ferait une phrase dont les deux moitiés ne parlent pas du même
  /// périmètre.
  Widget _crossedCard(AppLocalizations l10n) {
    final crossed = till.crossed;

    if (crossed.isEmpty) {
      return _InsightCard(
        icon: Icons.repeat_rounded,
        accent: AppColors.financeCrossedAccent,
        surface: AppColors.financeCrossedSurface,
        title: l10n.financeTillInsightCrossedTitle,
        body: l10n.financeTillInsightCrossedEmpty,
      );
    }

    // Deux montants côte à côte, jamais une somme — la doctrine vaut ici comme
    // partout ailleurs.
    final amounts = crossed.amounts
        .map(
          (amount) =>
              MoneyFormat.format(Money.parse(amount.amount, amount.currency)),
        )
        .join(l10n.financeTillInsightAmountSeparator);

    return _InsightCard(
      icon: Icons.repeat_rounded,
      accent: AppColors.financeCrossedAccent,
      surface: AppColors.financeCrossedSurface,
      title: l10n.financeTillInsightCrossedTitle,
      body: l10n.financeTillInsightCrossedBody(
        crossed.count,
        amounts,
        _rateClause(crossed, l10n),
      ),
    );
  }

  /// « au taux de 2 850 » — ou la **fourchette** quand la fenêtre en a vu
  /// plusieurs.
  ///
  /// ⚠️ **Un seul taux ne peut pas être cité quand il y en a eu plusieurs** :
  /// c'est précisément le changement de taux en cours de fenêtre qui explique
  /// l'écart que cette carte éclaire. La fourchette le montre, et sa longueur
  /// ne dépend pas du nombre de taux.
  ///
  /// Le taux s'écrit **nu**, sans unité : c'est la convention de la spec
  /// partout où un taux apparaît (« taux 2 850 » dans la table des reçus). La
  /// doctrine « tout montant porte son symbole » vise les **montants** ; un
  /// taux n'en est pas un.
  String _rateClause(TillCrossed crossed, AppLocalizations l10n) {
    if (crossed.rateMicros.isEmpty) return '';
    if (!crossed.hasMultipleRates) {
      return l10n.financeTillInsightCrossedSingleRate(
        _formatRate(crossed.rateMicros.first),
      );
    }
    return l10n.financeTillInsightCrossedRateRange(
      _formatRate(crossed.rateMicros.first),
      _formatRate(crossed.rateMicros.last),
    );
  }

  Widget _bestDayCard(
    BuildContext context,
    AppLocalizations l10n,
    TillBestBucket best,
  ) {
    return _InsightCard(
      icon: Icons.event_outlined,
      accent: AppColors.bleuArdoise,
      surface: AppColors.bleuArdoiseSoft,
      title: l10n.financeTillInsightBestDayTitle,
      // La part est **lue**, jamais recalculée : le serveur la rapporte à ce
      // qui est DESSINÉ, et sur la journée les deux fenêtres diffèrent.
      body: l10n.financeTillInsightBestDayBody(
        _readableKey(context, best.key),
        MoneyFormat.format(Money.parse(best.amount, block.currency)),
        best.sharePercent,
      ),
    );
  }

  Widget _boutiqueCard(AppLocalizations l10n) {
    final boutique = block.summary.boutique;

    return _InsightCard(
      icon: Icons.storefront_outlined,
      accent: AppColors.terreCuite,
      surface: AppColors.terreCuiteSoft,
      title: l10n.financeTillInsightBoutiqueTitle,
      body: boutique == 0
          ? l10n.financeTillInsightBoutiqueEmpty
          : l10n.financeTillInsightBoutiqueBody(
              MoneyFormat.format(Money.parse(boutique, block.currency)),
            ),
    );
  }

  /// ⚠️ **Plus courte que la maquette, faute de données.**
  ///
  /// La spec veut « en hausse de 18 % par rapport aux 7 jours précédents
  /// (3 490 $) » — donc la **durée** de la période précédente et son **total**.
  /// Le contrat n'expose que le pourcentage : ni l'un ni l'autre ne descend.
  /// La phrase s'arrête donc à ce qui est su, plutôt que d'inventer un
  /// intervalle ou un montant.
  Widget _trendCard(AppLocalizations l10n, int percent) {
    final rising = percent >= 0;

    return _InsightCard(
      icon: Icons.trending_up_rounded,
      accent: rising ? AppColors.vertSavane : AppColors.error,
      surface: rising
          ? AppColors.feeStatusPaidSoft
          : AppColors.financeDetailDangerSoft,
      title: l10n.financeTillInsightTrendTitle,
      body: rising
          ? l10n.financeTillInsightTrendUp(
              tillCurrencyName(block.currency, l10n),
              percent,
            )
          // À la baisse, la spec ajoute une phrase d'action — la seule des
          // quatre cartes à en porter une, et elle renvoie ailleurs.
          : l10n.financeTillInsightTrendDown(
              tillCurrencyName(block.currency, l10n),
              percent.abs(),
            ),
    );
  }

  /// La clé d'un intervalle, rendue lisible — « samedi 5 septembre 2026 ».
  ///
  /// Le serveur donne `YYYY-MM-DD` (ou `YYYY-MM` sur l'axe annuel). Une clé
  /// illisible se rend **telle quelle** plutôt que de risquer une date fausse :
  /// l'encart nomme un jour au caissier, et un jour inventé serait pire que le
  /// code brut.
  static String _readableKey(BuildContext context, String key) {
    final parsed = DateTime.tryParse(key.length == 7 ? '$key-01' : key);
    if (parsed == null) return key;
    return key.length == 7
        ? MaterialLocalizations.of(context).formatMonthYear(parsed)
        : MaterialLocalizations.of(context).formatFullDate(parsed);
  }

  /// Le taux depuis les micro-unités, sans décimale superflue.
  static String _formatRate(int rateMicros) {
    final units = rateMicros / ExchangeRate.scale;
    return units == units.roundToDouble()
        ? units.round().toString()
        : units.toString();
  }
}

/// Une lecture : un médaillon, un titre, une phrase — **et aucun bouton**.
class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color surface;
  final String title;
  final String body;

  const _InsightCard({
    required this.icon,
    required this.accent,
    required this.surface,
    required this.title,
    required this.body,
  });

  /// ⚠️ **Écart de style connu, et ajourné.**
  ///
  /// La spec écrit le titre en `title-small` et le corps en `body-small`. Le
  /// socle ne porte ni l'un ni l'autre : `bodyStrong` et `caption` en sont les
  /// plus proches, et sont ce qui est utilisé ici.
  ///
  /// Les rapprocher exactement demanderait d'**ajouter deux styles au socle**,
  /// pour un écart que personne n'a signalé sur un appareil réel. C'est de la
  /// surface partagée en plus sans preuve de besoin ; à rouvrir si l'écart se
  /// voit, pas avant.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $body',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM + 2,
            vertical: AppDimensions.spacingM,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      body,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
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
