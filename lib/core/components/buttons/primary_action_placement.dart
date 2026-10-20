import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Où vit l'action principale d'une page (« Nouveau chapitre », « Nouvelle
/// évaluation », « Nouvelle inscription »).
///
/// Sur téléphone et tablette portrait, un bouton flottant, sous le pouce.
/// Dès que le menu tient à l'écran (≥ 1 024), ou à la souris dès que la page
/// n'est plus un téléphone, un bouton dans la page : le flottant s'y collait
/// au bord de la fenêtre, loin du contenu, et masquait la pagination du bas de
/// tableau — une fenêtre de navigateur de 1 100 n'a pas de pouce.
bool primaryActionInPage(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.navigationCompactMax) return true;
  final pointer =
      Theme.of(context).materialTapTargetSize ==
      MaterialTapTargetSize.shrinkWrap;
  return pointer && width > AppBreakpoints.detailCompactMax;
}
