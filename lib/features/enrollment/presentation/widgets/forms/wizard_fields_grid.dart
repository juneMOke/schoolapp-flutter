import 'package:flutter/material.dart';

/// Un champ posé dans une [WizardFieldsGrid].
///
/// [fullWidth] force le champ à occuper toute la ligne (utile pour un champ
/// large : adresse complémentaire, tableau en lecture seule, etc.).
class WizardGridField {
  final Widget child;
  final bool fullWidth;

  const WizardGridField(this.child, {this.fullWidth = false});
}

/// Grille de champs responsive des étapes d'inscription.
///
/// Le nombre de colonnes s'adapte à la largeur disponible : 1 sur petit écran,
/// 2 en moyen, 3 en large. Les champs Eteelo (sans largeur propre) sont posés
/// dans des cases de largeur égale ; un champ [WizardGridField.fullWidth]
/// occupe toute la ligne.
class WizardFieldsGrid extends StatelessWidget {
  final List<WizardGridField> fields;
  final double spacing;
  final double runSpacing;

  const WizardFieldsGrid({
    super.key,
    required this.fields,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  /// Seuils de colonnes (sur la largeur disponible à l'intérieur de la carte).
  static int columnsForWidth(double width) {
    if (width >= 880) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = columnsForWidth(width);
        final itemWidth = (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final field in fields)
              SizedBox(
                width: field.fullWidth ? width : itemWidth,
                child: field.child,
              ),
          ],
        );
      },
    );
  }
}
