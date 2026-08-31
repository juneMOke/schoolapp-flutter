import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Grille de champs de l'assistant, avec les deux seules bascules du module.
///
/// Au-dessus de 900 dp, le nombre de colonnes demandé ; entre 560 et 900, deux ;
/// en dessous, une seule et les champs prennent toute la largeur.
///
/// Un `Wrap` plutôt qu'un `GridView` : les champs n'ont pas tous la même
/// hauteur — un champ en erreur porte son message — et une grille à cellules
/// égales alignerait tout sur le plus haut.
class ConfigurationFieldGrid extends StatelessWidget {
  final List<Widget> children;

  /// Colonnes au-dessus de 900 dp.
  final int wideColumns;

  const ConfigurationFieldGrid({
    super.key,
    required this.children,
    this.wideColumns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width < AppBreakpoints.configurationCompactMax
        ? 1
        : width < AppBreakpoints.configurationGridMax
        ? 2
        : wideColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final gaps = AppSpacing.md * (columns - 1);
        final itemWidth = columns == 1
            ? available
            : (available - gaps) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
