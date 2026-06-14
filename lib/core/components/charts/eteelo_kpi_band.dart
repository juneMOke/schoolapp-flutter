import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Bande de cartes KPI **responsive** : grille fluide (auto-fill) qui adapte le
/// nombre de colonnes à la largeur disponible. Toutes les cartes restent
/// visibles (aucun scroll horizontal) — d'une seule colonne sur mobile étroit
/// jusqu'à une ligne complète sur grand écran. Inspiré des bandes KPI Finance /
/// Classes (wrap au lieu d'un défilement).
class EteeloKpiBand extends StatelessWidget {
  final List<EteeloKpiCardData> cards;

  const EteeloKpiBand({super.key, required this.cards});

  /// Nombre de colonnes pour [count] cartes dans [width] (auto-fill borné par
  /// la largeur mini de carte). Pour une bande de 4 cartes, on évite le 3+1
  /// disgracieux (3 colonnes → 2×2) pour suivre la cascade 4 / 2×2 / 1.
  /// Exposé pour que le squelette de chargement reste iso-grille.
  static int columnsFor(double width, int count) {
    const spacing = AppDimensions.spacingM;
    const minCardWidth = AppDimensions.enrollmentStatsKpiCardMinWidth;
    var columns = ((width + spacing) / (minCardWidth + spacing)).floor().clamp(
      1,
      count,
    );
    if (count == 4 && columns == 3) columns = 2;
    return columns;
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppDimensions.spacingM;
        final available = constraints.maxWidth;

        // Auto-fill (sémantique CSS `minmax(min, 1fr)`), paliers harmonieux.
        final columns = columnsFor(available, cards.length);
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
                child: EteeloKpiCard(data: card),
              ),
          ],
        );
      },
    );
  }
}
