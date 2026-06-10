import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

/// Format responsive du splash, dérivé de la plus petite dimension de l'écran
/// et de l'orientation (spec §02 « Architecture responsive »). Pilote la taille
/// du symbole, la taille du wordmark et la disposition (empilé ↔ en ligne).
enum SplashFormat { phonePortrait, phoneLandscape, tablet, desktop }

/// Mesures responsive du splash calculées une fois par build à partir du
/// `MediaQuery`. Classe pure (aucune dépendance widget) → testable directement.
///
/// Règle maîtresse (spec) : symbole = `min(38 % du petit côté, 200 dp)`, jamais
/// plus. La source de taille est `shortestSide` (et non la largeur) pour rester
/// stable en rotation.
@immutable
class SplashMetrics {
  const SplashMetrics({
    required this.format,
    required this.symbolDiameter,
    required this.wordmarkSize,
    required this.wordmarkLineGap,
    required this.progressWidth,
    required this.isRow,
    required this.showFooter,
  });

  /// Format responsive courant.
  final SplashFormat format;

  /// Diamètre du symbole en dp, déjà plafonné.
  final double symbolDiameter;

  /// Taille (fontSize) de la ligne principale du wordmark (« ETEELO »).
  final double wordmarkSize;

  /// Espace vertical entre les deux lignes du wordmark (« ETEELO » / « CONNECT »).
  final double wordmarkLineGap;

  /// Largeur de la barre de progression en dp (spec §03 : 96 → 130 → 150).
  final double progressWidth;

  /// `true` en téléphone paysage : symbole et wordmark en ligne (Row).
  final bool isRow;

  /// `false` sous une hauteur critique : le pied est masqué (spec : < 360 dp).
  final bool showFooter;

  // — Tokens design propres au splash (spec §02, tableau « Symbole Ø ») —
  static const double _symbolPhonePortrait = 112;
  static const double _symbolPhoneLandscape = 96;
  static const double _symbolTablet = 152;
  static const double _symbolDesktop = 180;

  /// Plafond absolu : empêche un logo géant sur grand écran.
  static const double symbolHardCap = 200;

  /// Le symbole ne dépasse jamais 38 % du petit côté.
  static const double symbolShortestSideRatio = 0.38;

  // — Wordmark (spec §02, colonne « Wordmark » : taille / interligne) —
  static const double _wordmarkPhonePortrait = 22;
  static const double _wordmarkPhoneLandscape = 20;
  static const double _wordmarkTablet = 28;
  static const double _wordmarkDesktop = 32;

  static const double _lineGapPhone = 8;
  static const double _lineGapTablet = 10;
  static const double _lineGapDesktop = 11;

  // — Largeur de la barre de progression (spec §03) —
  static const double _progressPhone = 96;
  static const double _progressTablet = 130;
  static const double _progressDesktop = 150;

  /// En deçà de cette hauteur, le pied est masqué (spec §02 « Très petit écran »).
  static const double footerMinHeight = 360;

  /// Construit les mesures à partir de la taille et de l'orientation courantes.
  factory SplashMetrics.fromMedia({
    required Size size,
    required Orientation orientation,
  }) {
    final double shortestSide = size.shortestSide;
    final bool isLandscape = orientation == Orientation.landscape;

    // Disposition (spec §02). La classe d'appareil téléphone/tablette s'appuie
    // sur shortestSide (stable en rotation) — sinon un téléphone en paysage
    // (largeur ≥ 600) serait classé « tablette ». Le bureau reste sur la
    // largeur (≥ 1024), conformément au seuil « maxWidth » du spec.
    final SplashFormat format;
    if (size.width >= AppBreakpoints.navigationCompactMax) {
      format = SplashFormat.desktop;
    } else if (shortestSide >= AppBreakpoints.dataTableCardsMax) {
      format = SplashFormat.tablet;
    } else if (isLandscape) {
      format = SplashFormat.phoneLandscape;
    } else {
      format = SplashFormat.phonePortrait;
    }

    final (
      double baseSymbol,
      double wordmark,
      double lineGap,
      double progress,
    ) = switch (format) {
      SplashFormat.phonePortrait => (
        _symbolPhonePortrait,
        _wordmarkPhonePortrait,
        _lineGapPhone,
        _progressPhone,
      ),
      SplashFormat.phoneLandscape => (
        _symbolPhoneLandscape,
        _wordmarkPhoneLandscape,
        _lineGapPhone,
        _progressPhone,
      ),
      SplashFormat.tablet => (
        _symbolTablet,
        _wordmarkTablet,
        _lineGapTablet,
        _progressTablet,
      ),
      SplashFormat.desktop => (
        _symbolDesktop,
        _wordmarkDesktop,
        _lineGapDesktop,
        _progressDesktop,
      ),
    };

    // Plafond : min(valeur du format, 38 % du petit côté, 200 dp).
    final double cappedSymbol = math.min(
      baseSymbol,
      math.min(symbolShortestSideRatio * shortestSide, symbolHardCap),
    );

    return SplashMetrics(
      format: format,
      symbolDiameter: cappedSymbol,
      wordmarkSize: wordmark,
      wordmarkLineGap: lineGap,
      progressWidth: progress,
      isRow: format == SplashFormat.phoneLandscape,
      showFooter: size.height >= footerMinHeight,
    );
  }
}
