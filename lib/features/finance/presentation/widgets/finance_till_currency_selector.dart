import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Quelle caisse on détaille** — un titre de section, pas un filtre discret.
///
/// Tout ce qui suit à l'écran décrit **une seule** caisse. Le sélecteur porte
/// donc le compteur de reçus de chaque devise : on voit **avant de cliquer** si
/// l'autre caisse a travaillé, plutôt que de basculer pour découvrir un écran
/// vide et revenir.
///
/// ## Un segment à zéro reste cliquable
///
/// Il mène à l'état vide de caisse, qui chiffre l'autre et propose la bascule
/// inverse. Le griser ferait disparaître l'information « rien n'est entré en
/// francs aujourd'hui » — qui est précisément ce que le caissier vient
/// vérifier.
///
/// ## Pourquoi ce widget ne lit pas le bloc
///
/// Il reçoit sa sélection et rend son geste. Brancher le BLoC ici obligerait
/// tout test de la vue à monter un bloc pour afficher un graphique, et la
/// sémantique de ce segment — celle que l'accessibilité lit — deviendrait
/// dépendante d'un état asynchrone.
class FinanceTillCurrencySelector extends StatelessWidget {
  final List<TillCurrencyBlock> blocks;
  final String selectedCurrency;
  final ValueChanged<String> onSelected;

  const FinanceTillCurrencySelector({
    super.key,
    required this.blocks,
    required this.selectedCurrency,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordered = tillBlocksInDisplayOrder(blocks);

    // Une seule caisse : le sélecteur n'offre aucun choix, et un segment unique
    // se lit comme un bouton mort. Le titre de la section suffit alors.
    if (ordered.length < 2) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.financeTillDetailHeading,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Semantics(
          container: true,
          label: l10n.financeTillCurrencySelectorA11yLabel(
            tillCurrencyName(selectedCurrency, l10n),
          ),
          child: SegmentedTabFilter<String>(
            options: [
              for (final block in ordered)
                SegmentedTabOption(
                  // « $ dollars (17) » : le symbole double la teinte, le
                  // compteur dit si la caisse a travaillé.
                  label: l10n.financeTillCurrencySegment(
                    MoneyFormat.symbolOf(block.currency),
                    tillCurrencyName(block.currency, l10n),
                    block.summary.receiptCount,
                  ),
                  value: block.currency,
                  semanticLabel: l10n.financeTillCurrencySegmentA11yLabel(
                    tillCurrencyName(block.currency, l10n),
                    block.summary.receiptCount,
                    l10n.financeTillReceiptCount(block.summary.receiptCount),
                  ),
                ),
            ],
            selected: selectedCurrency,
            onSelected: onSelected,
          ),
        ),
      ],
    );
  }
}
