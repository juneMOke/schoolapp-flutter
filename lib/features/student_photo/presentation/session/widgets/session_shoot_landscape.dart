import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La prise de vue sur une fenêtre basse (téléphone couché) : le viseur à
/// gauche, à la hauteur de la page ; l'élève, la progression et les gestes
/// à droite. Empilés, le déclencheur passait sous le pli et il fallait
/// défiler avant chaque prise.
///
/// Le viseur prend au plus la moitié de la largeur — les gestes gardent la
/// leur sur une fenêtre à la fois basse et étroite — et sa hauteur se borne
/// à [viewfinderMaxHeight].
class SessionShootLandscape extends StatelessWidget {
  /// Le viseur, porteur de sa `GlobalKey` : il vient tel quel de la
  /// disposition empilée.
  final Widget viewfinder;
  final double? viewfinderMaxHeight;
  final Widget header;
  final Widget actions;

  const SessionShootLandscape({
    super.key,
    required this.viewfinder,
    required this.viewfinderMaxHeight,
    required this.header,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = viewfinderMaxHeight;
    return Row(
      children: [
        Flexible(
          child: maxHeight == null
              ? viewfinder
              : ConstrainedBox(
                  // Le viseur est au 4:3 : sa hauteur bornée borne sa largeur.
                  constraints: BoxConstraints(maxWidth: maxHeight * 4 / 3),
                  child: viewfinder,
                ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.md),
              actions,
            ],
          ),
        ),
      ],
    );
  }
}
