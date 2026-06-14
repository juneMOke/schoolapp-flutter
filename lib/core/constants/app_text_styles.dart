import 'package:flutter/widgets.dart';

class AppTextStyles {
  static final sidebarTitle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  );

  static final pageTitle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  );

  static final sectionTitle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  static final body = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );

  static final bodyStrong = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  );

  static final caption = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.none,
  );

  static final action = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.none,
  );

  static final detailHeroTitle = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.none,
  );

  static final detailHeroSubtitle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    decoration: TextDecoration.none,
  );

  static final tableHeader = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );

  static final badge = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );

  static final codeMuted = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    fontFamily: 'monospace',
    decoration: TextDecoration.none,
  );

  /// Initiales d'avatar. La taille de police est dynamique (0.36 × diamètre)
  /// et la couleur dépend de la variante : le widget les applique via copyWith.
  static final avatarInitials = const TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    height: 1,
    decoration: TextDecoration.none,
  );

  static final moneyTabular = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    decoration: TextDecoration.none,
  );

  static final totalAmountLora = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: 'Lora',
    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
    decoration: TextDecoration.none,
  );

  /// Chiffres tabulaires (largeur de glyphe fixe) à appliquer via `copyWith`
  /// sur les styles porteurs de nombres (valeurs KPI, taux, axes…) pour un
  /// alignement stable colonne par colonne et entre périodes.
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];
}
