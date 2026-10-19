import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Où vit l'action principale d'une page (« Nouveau chapitre », « Nouvelle
/// évaluation », « Nouvelle inscription »).
///
/// Sur tablette et téléphone, un bouton flottant, sous le pouce. Sur grand
/// écran, un bouton dans la page : le flottant s'y collait au bord de la
/// fenêtre, à plusieurs centaines de dp du contenu centré, et masquait la
/// pagination du bas de tableau.
bool primaryActionInPage(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= AppBreakpoints.formWideMin;
