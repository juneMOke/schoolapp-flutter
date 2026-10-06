import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

/// Barre collante en bas des pages d'une évaluation, placée dans le
/// `bottomNavigationBar` du Scaffold : enregistrement des notes, barre
/// d'actions du détail, enregistrement du sujet. Centrée et bornée à la
/// largeur du contenu.
class EvalStickyBottomBar extends StatelessWidget {
  final Widget child;

  const EvalStickyBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        // heightFactor: 1.0 → la barre s'ajuste à sa hauteur intrinsèque.
        // Sans lui, l'Align remplirait la contrainte lâche du
        // bottomNavigationBar (toute la hauteur d'écran) et masquerait le
        // corps + pousserait les toasts flottants hors écran.
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailContentMaxWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
