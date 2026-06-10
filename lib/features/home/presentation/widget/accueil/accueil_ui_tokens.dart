/// Dimensions propres à la page d'accueil (spec Accueil, densité « aérée »).
///
/// Source unique des écarts, paddings et tailles de la page d'atterrissage —
/// aucune valeur en dur dans les widgets (règle projet : zéro dimension
/// hardcodée). Les valeurs reprennent la colonne « aérée (défaut) » de la spec
/// (§03 Variations de densité) ; 1 px CSS = 1 dp Flutter.
class AccueilUiTokens {
  const AccueilUiTokens._();

  // ---- Rythme vertical inter-zones (spec §02 Anatomie) ----
  static const double bannerToModulesGap = 24;
  static const double modulesToSignatureGap = 30;

  // ---- Bandeau de marque (spec §01) ----
  static const double bannerRadius = 20;
  static const double bannerPaddingH = 34;
  static const double bannerPaddingTop = 32;
  static const double bannerPaddingBottom = 34;
  static const double bannerStackThreshold = 620; // médaillon sous le texte
  static const double bannerTextMinWidth = 260;
  static const double bannerTextMedaillonGap = 16;
  static const double bannerEyebrowLetterSpacing = 1.6; // ~.14em sur 11sp
  static const double bannerGreetingFontSize = 32;
  static const double bannerGreetingHeight = 1.2;
  static const double bannerGreetingGapTop = 9;
  static const double bannerGreetingGapBottom = 7;
  static const double bannerContextHeight = 1.5;
  static const double bannerMedaillonSize = 84;
  static const double bannerMedaillonRadius = 20;
  static const double bannerSymbolSize = 52;
  static const double bannerMedaillonFillOpacity = 0.07;
  static const double bannerMedaillonBorderOpacity = 0.12;
  static const double bannerContextOpacity = 0.78;

  // ---- En-tête de la section modules (spec §02) ----
  static const double sectionEyebrowLetterSpacing = 1.4; // ~.12em sur 11sp
  static const double sectionTitleFontSize = 18;
  static const double sectionTitleGapTop = 6;
  static const double sectionTitleGapBottom = 4;
  static const double sectionHeaderToGridGap = 16;

  // ---- Grille de modules (spec §01 responsive : auto-fill minmax(248,1fr)) ----
  static const double gridGap = 14;
  static const double gridMinItemWidth = 248;
  static const int gridMaxColumns = 4;

  // ---- Carte module (spec §03) ----
  static const double cardPadding = 22;
  static const double cardRadius = 20;
  static const double cardTitleGap = 12;
  static const double cardDescriptionGapTop = 12;
  static const double cardMedaillonSize = 44;
  static const double cardMedaillonRadius = 12;
  static const double cardMedaillonIconSize = 22;
  static const double cardArrowSize = 18;
  static const double cardArrowHoverShift = 2;
  static const double cardHoverLift = -2;
  static const double cardBorderHoverOpacity = 0.45;
  static const double cardFooterGapTop = 16;
  static const double cardFooterPaddingTop = 12;
  static const double cardShadowBlur = 14;
  static const double cardShadowOffsetY = 6;
  static const double cardShadowOpacity = 0.05;
  static const double cardShadowHoverBlur = 18;
  static const double cardShadowHoverOffsetY = 6;
  static const double cardShadowHoverOpacity = 0.10;

  // ---- Puce lien rapide (spec §04) ----
  static const double chipGap = 6;
  static const double chipPaddingH = 10;
  static const double chipPaddingV = 5;
  static const double chipIconSize = 12;
  static const double chipIconGap = 4;
  static const double chipHoverOpacity = 0.08; // bleu-ardoise ~8 %

  // ---- Signature de marque (spec §05) ----
  static const double signatureFontSize = 13;
  static const double signatureHeight = 1.4;
}
