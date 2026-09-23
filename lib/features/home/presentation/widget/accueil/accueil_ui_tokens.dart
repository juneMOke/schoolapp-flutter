import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Dimensions et durées propres à la page d'accueil.
///
/// Source unique des écarts, paddings et tailles de la page d'atterrissage —
/// aucune valeur en dur dans les widgets (règle projet : zéro dimension
/// hardcodée). 1 px CSS = 1 dp Flutter.
///
/// Deux specs se partagent le fichier : la spec **structurelle** (bandeau,
/// grille, rythme vertical, signature) et la spec **couleurs**, qui remplace
/// depuis la variante « blocs » l'anatomie des cartes par celle des pavés
/// pleins (§05 à §07).
class AccueilUiTokens {
  const AccueilUiTokens._();

  // ---- Rythme vertical inter-zones (spec structurelle §02 Anatomie) ----
  static const double bannerToModulesGap = 24; // sp
  static const double modulesToSignatureGap = 30; // sp + 6

  // ---- Animation d'entrée (spec structurelle §02, note micro-animation) ----
  /// Les pavés montent de 12 dp en fondu ; l'état final est la base, donc
  /// l'animation est purement décorative (désactivée sous `disableAnimations`).
  static const double entranceOffsetY = 12;
  static const Duration entranceDuration = AppMotion.entranceSlow;
  static const Duration entranceStagger = AppMotion.stagger;

  // ---- Bandeau de marque (spec couleurs §08) ----
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

  // ---- Pastille de contexte du bandeau (spec couleurs §08) ----
  static const double pillGap = 8;
  static const double pillPaddingH = 14;
  static const double pillPaddingV = 7;
  static const double pillIconSize = 14;
  static const double pillIconGap = 7;
  static const double pillFontSize = 13;
  static const double pillFillOpacity = 0.09;
  static const double pillBorderOpacity = 0.14;

  // ---- En-tête de la section modules (spec structurelle §02) ----
  static const double sectionEyebrowLetterSpacing = 1.4; // ~.12em sur 11sp
  static const double sectionTitleFontSize = 18;
  static const double sectionTitleGapTop = 6;
  static const double sectionTitleGapBottom = 4;
  static const double sectionHeaderToGridGap = 16;

  // ---- Grille de modules (auto-fill minmax(272,1fr)) ----
  static const double gridGap = 14;
  static const double gridMinItemWidth = 272;
  static const int gridMaxColumns = 3;

  // ---- Pavé module, variante « blocs » (spec couleurs §05) ----
  static const double blocRadius = 20;
  static const double blocPadding = 20;

  /// Halo : un disque de blanc cassé très faible, ancré hors du coin haut
  /// droit et posé SOUS le contenu. Il ne porte aucune information — il donne
  /// juste du relief à l'aplat.
  static const double blocHaloSize = 180;
  static const double blocHaloOffset = -60;
  static const double blocHaloVeil = 0.06;

  static const double blocMedaillonSize = 48;
  static const double blocMedaillonRadius = 14;
  static const double blocMedaillonIconSize = 24;
  static const double blocMedaillonVeil = 0.12;
  static const double blocMedaillonBorderVeil = 0.20;
  static const double blocMedaillonHoverScale = 1.06;

  static const double blocTitleFontSize = 20;
  static const double blocTitleHeight = 1.2;
  static const double blocMedaillonToTitleGap = 12;
  static const double blocMetaGapTop = 3;
  static const double blocMetaFontSize = 11;
  static const double blocArrowSize = 18;
  static const double blocArrowHoverShift = 3;
  static const double blocDescriptionGapTop = 14;
  static const double blocDescriptionFontSize = 13;
  static const double blocDescriptionHeight = 1.5;
  static const double blocPillsGapTop = 18;

  // Interaction (§07) : le pavé étant déjà plein, le survol ne change JAMAIS
  // la teinte — cela casserait l'association module → couleur. Il se signale
  // par l'élévation et le mouvement seuls.
  static const double blocHoverLift = -4;
  static const double blocShadowBlur = 18;
  static const double blocShadowOffsetY = 6;
  static const double blocShadowOpacity = 0.14;
  static const double blocShadowHoverBlur = 44;
  static const double blocShadowHoverOffsetY = 20;
  static const double blocShadowHoverOpacity = 0.28;

  /// Anneau de focus clavier : 2 dp d'or, à 2 dp du bord du pavé (§07).
  static const double blocFocusRingWidth = 2;
  static const double blocFocusRingGap = 2;

  // ---- Pastille de sous-module (spec couleurs §06) ----
  static const double blocPillGap = 7;
  static const double blocPillPaddingH = 12;
  static const double blocPillFontSize = 12;

  /// La spec dessine des pastilles de 32 dp sur desktop et impose 44 dp
  /// minimum sur mobile — « la couleur ne change pas, seule la géométrie
  /// s'adapte ». L'application vise la tablette tactile : c'est donc la cible
  /// tactile qui gagne, comme elle l'emportait déjà sur les lignes de 40 dp de
  /// l'ancienne variante « cartes ».
  static const double blocPillMinHeight = 44;

  /// Voile d'une pastille ordinaire au repos.
  static const double blocPillVeil = 0.07;

  /// Voile de la pastille « Tableau de bord » au repos.
  static const double blocPillDashboardVeil = 0.16;

  /// Voile des deux pastilles au survol.
  ///
  /// ⚠️ La spec §06 écrit `.24`, valeur que ce token **n'adopte pas**. Un voile
  /// clair éclaircit le fond, donc fait BAISSER le contraste de l'encre crème
  /// posée dessus : à `.24`, le libellé tombe à 4,26:1 sur `#1B4D6B` et 3,70:1
  /// sur la terre cuite de la spec — sous le seuil de 4,5:1 du §04. `.20`
  /// laisse toute la palette au-dessus, au pire à 4,73:1, et garde un palier de
  /// survol franc (.07 → .20 pour une pastille ordinaire).
  ///
  /// L'autre issue — assombrir `#1B4D6B` — a été écartée : elle le fait
  /// fusionner avec `#164760`, dont il n'est distant que de 1,10 de ratio.
  static const double blocPillHoverVeil = 0.20;

  /// Bord d'une pastille ordinaire. Non textuel, donc hors du seuil de 4,5:1.
  static const double blocPillBorderVeil = 0.34;

  // ---- Signature de marque (spec structurelle §06) ----
  static const double signatureFontSize = 13;
  static const double signatureHeight = 1.4;
}
