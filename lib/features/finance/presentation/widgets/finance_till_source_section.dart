import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_split_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **D'où vient l'argent** — frais facturés contre ventes boutique, dans la
/// caisse détaillée.
///
/// La distinction n'est pas décorative : la boutique est de la **trésorerie sur
/// des achats facultatifs**, non facturés. Elle entre dans le même tiroir, le
/// même jour, au même guichet — et elle ne solde aucune créance. Confondre les
/// deux ferait lire un règlement de frais là où un parent a acheté un uniforme.
///
/// C'est la moitié de l'ancienne bande KPI qui atterrit ici, à sa vraie place :
/// elle répond à « d'où vient l'argent », pas à « combien est entré ».
class FinanceTillSourceSection extends StatelessWidget {
  final TillCurrencyBlock block;

  const FinanceTillSourceSection({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = block.summary;

    String money(int cents) =>
        MoneyFormat.format(Money.parse(cents, block.currency));

    final fees = money(summary.fees);
    final boutique = money(summary.boutique);

    return FinanceStatsChartCard(
      title: l10n.financeTillSourceHeading,
      // **La pastille de la table, promue en repère de carte.** C'est déjà
      // l'icône de la source « facturation » dans « Reçus de la caisse » ; en
      // reprendre une autre ici ferait de la ventilation et de ses lignes deux
      // sujets sans rapport.
      icon: Icons.account_balance,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.financeTillSourceHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          EteeloSplitBar(
            // **L'ordre ne suit jamais les montants** : facturation puis
            // boutique, toujours. Un ordre qui bascule avec l'activité oblige à
            // relire la légende à chaque fois pour savoir ce qu'on regarde.
            segments: [
              EteeloSplitBarSegment(
                label: l10n.financeTillSourceFees,
                valueLabel: fees,
                value: summary.fees,
                color: AppColors.bleuArdoise,
              ),
              EteeloSplitBarSegment(
                label: l10n.financeTillSourceBoutique,
                valueLabel: boutique,
                value: summary.boutique,
                color: AppColors.terreCuite,
              ),
            ],
            semanticsLabel: l10n.financeTillSourceA11yLabel(fees, boutique),
          ),
          // La note ne s'affiche que si la boutique a effectivement vendu :
          // rappeler le statut non facturé d'un montant nul expliquerait une
          // ligne que personne ne voit.
          if (summary.boutique > 0) ...[
            const SizedBox(height: AppDimensions.spacingM),
            _BoutiqueNote(l10n: l10n),
          ],
        ],
      ),
    );
  }
}

/// Ce que la part boutique veut dire — et ce qu'elle ne veut pas dire.
///
/// Une part à zéro **garde sa ligne de légende** dans la barre : l'absence de
/// vente est une information, pas un vide. Mais cette note-ci, qui explique le
/// statut non facturé, n'a d'objet que lorsqu'il y a une part à expliquer.
class _BoutiqueNote extends StatelessWidget {
  final AppLocalizations l10n;

  const _BoutiqueNote({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.terreCuiteSoft,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 16,
            color: AppColors.terreCuite,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.financeTillSourceBoutiqueNote,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
