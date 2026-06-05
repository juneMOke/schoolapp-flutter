import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Grille responsive « fit hauteur » : chaque cellule prend la hauteur de son
/// contenu (pas de tuile à hauteur uniforme).
///
/// Le nombre de colonnes suit la sémantique CSS `auto-fill minmax(min, 1fr)` :
/// on place autant de colonnes que possible sans qu'une carte descende sous
/// [minItemWidth], puis chaque carte remplit sa colonne (1fr). Le rendu
/// s'appuie sur un [Wrap] pour autoriser des hauteurs de carte variables
/// (fit contenu).
///
/// Destiné aux grilles non défilantes intégrées dans un parent scrollable
/// (résultats paginés) : les enfants sont construits en une passe.
class EteeloGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry padding;
  final double minItemWidth;
  final double spacing;

  const EteeloGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(AppSpacing.gridGap),
    this.minItemWidth = AppDimensions.gridMinItemWidth,
    this.spacing = AppSpacing.gridGap,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth;
          // floor : autant de colonnes que possible sans passer sous
          // [minItemWidth] (sémantique `minmax(min, 1fr)`).
          final columns = ((available + spacing) / (minItemWidth + spacing))
              .floor()
              .clamp(1, itemCount);
          final itemWidth = (available - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: List.generate(
              itemCount,
              (index) => SizedBox(
                width: itemWidth,
                child: itemBuilder(context, index),
              ),
            ),
          );
        },
      ),
    );
  }
}
