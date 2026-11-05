import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// La prise de vue sur une fenêtre basse (téléphone couché) : le viseur à
/// gauche, à la hauteur de la page ; l'élève, la progression et les gestes
/// à droite. Empilés, le déclencheur passait sous le pli et il fallait
/// défiler avant chaque prise.
///
/// Le panneau prend exactement [height] : c'est la hauteur que la page
/// laisse, marges ôtées. La colonne des gestes garde au moins
/// [AppDimensions.photoSessionLandscapeControlsMin] de large, le viseur prend
/// le reste dans la limite de son 4:3. Si l'élève et les gestes dépassent
/// tout de même la hauteur (texte très agrandi), la colonne défile en
/// elle-même, le déclencheur en haut de ce qui défile — jamais la page.
class SessionShootLandscape extends StatelessWidget {
  /// Le viseur, porteur de sa `GlobalKey` : il vient tel quel de la
  /// disposition empilée.
  final Widget viewfinder;
  final double height;
  final Widget header;
  final Widget actions;

  const SessionShootLandscape({
    super.key,
    required this.viewfinder,
    required this.height,
    required this.header,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final room =
              box.maxWidth -
              AppSpacing.lg -
              AppDimensions.photoSessionLandscapeControlsMin;
          // Le viseur est au 4:3 : sa hauteur bornée borne sa largeur.
          final width = math.max(0.0, math.min(height * 4 / 3, room));
          return Row(
            children: [
              SizedBox(width: width, child: viewfinder),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        header,
                        const SizedBox(height: AppSpacing.sm),
                        actions,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
