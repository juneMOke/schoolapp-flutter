import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/eteelo_animated_symbol.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_metrics.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Identité ETEELO CONNECT du splash : symbole animé + wordmark texte.
///
/// La disposition s'adapte au format (spec §02) : empilée (Column) en portrait /
/// tablette / bureau, en ligne (Row) en téléphone paysage. Le symbole porte la
/// sémantique de marque ; le wordmark est décoratif (exclu des lecteurs d'écran).
class EteeloSplashBrand extends StatelessWidget {
  const EteeloSplashBrand({
    super.key,
    required this.metrics,
    required this.reveal,
    required this.wordmarkEntrance,
    this.spinning = true,
  });

  final SplashMetrics metrics;

  /// Révélation du symbole (0→1).
  final Animation<double> reveal;

  /// Entrée du wordmark (0→1) : fondu + remontée, déclenchée après le symbole.
  final Animation<double> wordmarkEntrance;

  /// Rotation de l'arc tant que le bootstrap charge.
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final symbol = EteeloAnimatedSymbol(
      diameter: metrics.symbolDiameter,
      reveal: reveal,
      spinning: spinning,
      semanticsLabel: l10n.splashSemanticsLabel,
    );

    final wordmark = ExcludeSemantics(
      child: _WordmarkEntrance(
        animation: wordmarkEntrance,
        child: _SplashWordmark(metrics: metrics, l10n: l10n),
      ),
    );

    if (metrics.isRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          symbol,
          const SizedBox(width: AppSpacing.xl),
          wordmark,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        symbol,
        const SizedBox(height: AppSpacing.lg),
        wordmark,
      ],
    );
  }
}

/// Applique l'entrée « fondu + remontée 8 dp » (spec §02) au wordmark.
class _WordmarkEntrance extends StatelessWidget {
  const _WordmarkEntrance({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  /// Amplitude de la remontée à l'entrée (spec : 8 dp).
  static const double _riseFrom = 8;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double v = animation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * _riseFrom),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Wordmark « ETEELO » + « CONNECT » rendu en texte (pas en SVG) pour permettre
/// le dimensionnement et le reflow indépendants exigés par le spec responsive.
class _SplashWordmark extends StatelessWidget {
  const _SplashWordmark({required this.metrics, required this.l10n});

  final SplashMetrics metrics;
  final AppLocalizations l10n;

  /// Rapport taille « CONNECT » / « ETEELO ».
  static const double _secondaryRatio = 0.62;

  /// Interlettrage (spec §02) exprimé en em (× fontSize).
  static const double _primaryTrackingEm = 0.06;
  static const double _secondaryTrackingEm = 0.42;

  @override
  Widget build(BuildContext context) {
    final double primarySize = metrics.wordmarkSize;
    final double secondarySize = primarySize * _secondaryRatio;

    final primaryStyle = AppTypography.headlineLarge.copyWith(
      fontSize: primarySize,
      fontWeight: FontWeight.w800,
      letterSpacing: primarySize * _primaryTrackingEm,
      color: AppColors.textOnDark,
      height: 1.0,
    );
    final secondaryStyle = AppTypography.titleMedium.copyWith(
      fontSize: secondarySize,
      fontWeight: FontWeight.w600,
      letterSpacing: secondarySize * _secondaryTrackingEm,
      color: AppColors.orDoux,
      height: 1.0,
    );

    // En ligne (paysage) le wordmark est gauche-aligné ; sinon centré.
    final crossAxis = metrics.isRow
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxis,
      children: [
        Text(l10n.splashBrandPrimary, style: primaryStyle),
        SizedBox(height: metrics.wordmarkLineGap),
        Text(l10n.splashBrandSecondary, style: secondaryStyle),
      ],
    );
  }
}
