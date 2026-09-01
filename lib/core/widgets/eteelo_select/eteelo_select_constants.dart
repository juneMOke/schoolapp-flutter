import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';

class EteeloSelectConstants {
  const EteeloSelectConstants._();

  // --- Champ fermé -----------------------------------------------------------
  static const double fieldHeight = AppDimensions.minTouchTarget - 2;

  /// Gabarit compact : hauteur d'une puce, pas d'une cible de saisie. Réservé
  /// aux sélecteurs enchâssés dans une rangée déjà dense (cf.
  /// `EteeloSelectDensity.compact`), jamais à un champ de formulaire.
  static const double fieldHeightCompact = 36;

  static const double restBorderWidth = 1;
  static const double focusBorderWidth = 2;
  static const double restHorizontalPadding = AppSpacing.md;
  static const double focusHorizontalPadding = AppSpacing.md - 1;
  static const double compactRestHorizontalPadding = AppSpacing.sm + 2;
  static const double compactFocusHorizontalPadding = AppSpacing.sm + 1;
  static const double labelGap = AppSpacing.sm - 2;
  static const double chevronSize = 18;

  // --- Panneau ---------------------------------------------------------------

  /// Au-delà de ce nombre d'options, le panneau ouvre avec sa recherche.
  ///
  /// En deçà, la liste tient sous l'œil et une barre de recherche au-dessus de
  /// trois lignes ne fait qu'ajouter un obstacle entre l'intention et le clic.
  /// Au-delà (195 nationalités, les quartiers d'une commune), la faire défiler
  /// à l'aveugle est le vrai coût.
  static const int searchThreshold = 8;

  static const double panelMaxHeight = 320;
  static const double panelMinWidth = 240;

  /// Écart entre le champ et son panneau ancré : assez pour que l'ombre du
  /// panneau ne se confonde pas avec la bordure du champ.
  static const double panelAnchorGap = 6;

  /// Marge minimale gardée contre les bords de l'écran.
  static const double panelScreenMargin = 12;

  static const double panelPadding = AppSpacing.sm - 2;
  static const double optionMinHeight = 40;
  static const double optionGap = 2;
  static const double optionIconSize = 18;
  static const double checkSize = 18;

  // --- Feuille modale --------------------------------------------------------

  /// Part de la hauteur d'écran que la feuille ne dépasse pas : ce qui reste
  /// du formulaire au-dessus rappelle **ce qu'on est en train de remplir**.
  static const double sheetMaxHeightFactor = 0.72;
  static const double sheetMaxWidth = 640;

  // --- Recherche -------------------------------------------------------------
  static const double searchFieldHeight = 40;
  static const double searchIconSize = 18;
}
