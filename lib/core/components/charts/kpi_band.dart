import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Bande de cartes KPI **responsive** : grille fluide (auto-fill) qui adapte le
/// nombre de colonnes à la largeur disponible. Toutes les cartes restent
/// visibles (aucun scroll horizontal) — d'une seule colonne sur mobile étroit
/// jusqu'à une ligne complète sur grand écran. Inspiré des bandes KPI Finance /
/// Classes (wrap au lieu d'un défilement).
class KpiBand extends StatelessWidget {
  final List<KpiCardData> cards;

  const KpiBand({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppDimensions.spacingM;
        const minCardWidth = AppDimensions.enrollmentStatsKpiCardMinWidth;
        final available = constraints.maxWidth;

        // Auto-fill (sémantique CSS `minmax(min, 1fr)`) : autant de colonnes que
        // possible sans qu'une carte passe sous sa largeur minimale. Garantit
        // `cardWidth >= minCardWidth`, donc aucun débordement de carte.
        final columns = ((available + spacing) / (minCardWidth + spacing))
            .floor()
            .clamp(1, cards.length);
        // Arrondi à l'inférieur : évite qu'un sur-pixel flottant fasse passer la
        // dernière carte à la ligne suivante quand elles tiennent juste.
        final cardWidth = ((available - spacing * (columns - 1)) / columns)
            .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: KpiCard(data: card),
              ),
          ],
        );
      },
    );
  }
}
