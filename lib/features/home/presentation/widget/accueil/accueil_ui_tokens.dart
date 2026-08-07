import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Dimensions et durées propres à la page d'accueil (spec Accueil, densité
/// « aérée »).
///
/// Source unique des écarts, paddings et tailles de la page d'atterrissage —
/// aucune valeur en dur dans les widgets (règle projet : zéro dimension
/// hardcodée). Les valeurs reprennent la colonne « aérée (défaut) » de la spec
/// (§03 Variations de densité) ; 1 px CSS = 1 dp Flutter.
class AccueilUiTokens {
  const AccueilUiTokens._();

  // ---- Rythme vertical inter-zones (spec §02 Anatomie) ----
  static const double bannerToModulesGap = 24; // sp
  static const double modulesToSignatureGap = 30; // sp + 6

  // ---- Animation d'entrée (spec §02, note micro-animation) ----
  /// Les cartes montent de 12 dp en fondu ; l'état final est la base, donc
  /// l'animation est purement décorative (désactivée sous `disableAnimations`).
  static const double entranceOffsetY = 12;
  static const Duration entranceDuration = AppMotion.entranceSlow;
  static const Duration entranceStagger = AppMotion.stagger;

  // ---- Bandeau de marque (spec §01) ----
  static const double bannerRadius = 24;
  static const double bannerPaddingH = 34;
  static const double bannerPaddingTop = 30;
  static const double bannerPaddingBottom = 30;
  static const double bannerAccentBarHeight = 3; // liseré or en tête
  static const double bannerAccentBarFadeStop = 0.62;
  static const double bannerStackThreshold = 620; // médaillon sous le texte
  static const double bannerTextMedaillonGap = 18;
  static const double bannerEyebrowLetterSpacing = 1.6; // ~.14em sur 11sp
  static const double bannerGreetingFontSize = 33;
  static const double bannerGreetingHeight = 1.2;
  static const double bannerGreetingGapTop = 10;
  static const double bannerGreetingGapBottom = 16;
  static const double bannerMedaillonSize = 84;
  static const double bannerMedaillonRadius = 22;
  static const double bannerSymbolSize = 52;
  static const double bannerMedaillonFillOpacity = 0.07;
  static const double bannerMedaillonBorderOpacity = 0.14;
  static const double bannerMedaillonHaloWidth = 6;
  static const double bannerMedaillonHaloOpacity = 0.03;

  // ---- Pastille de contexte du bandeau (spec §02 composant) ----
  static const double pillGap = 8;
  static const double pillPaddingH = 14;
  static const double pillPaddingV = 7;
  static const double pillIconSize = 14;
  static const double pillIconGap = 7;
  static const double pillFontSize = 13;
  static const double pillFillOpacity = 0.09;
  static const double pillBorderOpacity = 0.14;
  static const double pillTextOpacity = 0.88;

  // ---- En-tête de la section modules (spec §02) ----
  static const double sectionEyebrowLetterSpacing = 1.4; // ~.12em sur 11sp
  static const double sectionTitleFontSize = 18;
  static const double sectionTitleGapTop = 6;
  static const double sectionTitleGapBottom = 4;
  static const double sectionHeaderToGridGap = 16;

  // ---- Grille de modules (spec §01 responsive : auto-fill minmax(272,1fr)) ----
  static const double gridGap = 14;
  static const double gridMinItemWidth = 272;
  static const int gridMaxColumns = 3;

  // ---- Carte module, variante « cartes » (spec §03) ----
  static const double cardPadding = 18;
  static const double cardRadius = 22;

  /// Hauteur sur laquelle le fond doux du module se fond dans la surface
  /// blanche — équivalent Flutter de `linear-gradient(180deg,{soft}66,
  /// surface-raised 64px)`.
  static const double cardTintHeight = 64;
  static const double cardTintOpacity = 0.40; // {soft}66
  static const double cardAccentBarHeight = 3;
  static const double cardAccentBarRestScaleX = 0.3;
  static const double cardMedaillonSize = 46;
  static const double cardMedaillonRadius = 14;
  static const double cardMedaillonIconSize = 23;
  static const double cardMedaillonRingOpacity = 0.13; // {accent}22
  static const double cardMedaillonHoverScale = 1.07;
  static const double cardMedaillonHoverTurns = -3 / 360; // -3deg
  static const double cardTitleGap = 12;
  static const double cardSubtitleGapTop = 2;
  static const double cardArrowSize = 18;
  static const double cardArrowHoverShift = 2;
  static const double cardDescriptionGapTop = 12;
  static const double cardFooterGapTop = 16;
  static const double cardFooterPaddingTop = 10;
  static const double cardHoverLift = -4;
  static const double cardBorderHoverOpacity = 0.40;
  static const double cardShadowBlur = 24;
  static const double cardShadowOffsetY = 8;
  static const double cardShadowOpacity = 0.07;
  static const double cardShadowContactBlur = 3;
  static const double cardShadowContactOffsetY = 1;
  static const double cardShadowContactOpacity = 0.05;
  static const double cardShadowHoverBlur = 40;
  static const double cardShadowHoverOffsetY = 18;
  static const double cardShadowHoverOpacity = 0.16;

  // ---- Ligne sous-module (spec §04) ----
  static const double subRowGap = 2;

  /// La spec dessine des lignes de 40 dp mais impose 44 dp de cible tactile
  /// côté Flutter (§04 « Cible tactile ») : c'est cette dernière qui gagne.
  static const double subRowMinHeight = 44;
  static const double subRowRadius = 10;
  static const double subRowPaddingH = 10;
  static const double subRowLeadGap = 10;
  static const double subRowLeadSize = 22;
  static const double subRowLeadRadius = 6;
  static const double subRowLeadIconSize = 13;
  static const double subRowDotSize = 6;
  static const double subRowDotOpacity = 0.5;
  static const double subRowDashboardFontSize = 13;
  static const double subRowChevronSize = 14;
  static const double subRowChevronHoverShift = 2;

  // ---- Signature de marque (spec §06) ----
  static const double signatureFontSize = 13;
  static const double signatureHeight = 1.4;
}
