import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Un [InkWell] posé sur une surface sombre (bandeau dégradé, barre d'en-tête).
///
/// Deux défauts d'un `InkWell` nu à cet endroit :
/// - l'encre se peint sur le `Material` ancêtre, SOUS le dégradé opaque du
///   bandeau : survol, appui et focus restent invisibles. D'où le `Material`
///   transparent, posé entre le fond et la zone d'appui ;
/// - les voiles par défaut sont bleu ardoise, fondus dans le bleu profond.
///   D'où les voiles blanc cassé ([AppColors.stateFocusOnDark] et ses
///   voisins).
class OnDarkInkWell extends StatelessWidget {
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Widget child;

  const OnDarkInkWell({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      focusColor: AppColors.stateFocusOnDark,
      hoverColor: AppColors.stateHoverOnDark,
      highlightColor: AppColors.statePressedOnDark,
      splashColor: AppColors.statePressedOnDark,
      child: child,
    ),
  );
}
