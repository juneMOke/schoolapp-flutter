import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/eteelo_splash_brand.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_error_view.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_footer.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_metrics.dart';
import 'package:school_app_flutter/features/splash/presentation/widgets/splash_progress_bar.dart';

/// Couche B du splash (spec §01) : premier widget Dart rendu par l'app. Reprend
/// le visuel de la couche native / du loader web (fond Bleu Profond, symbole
/// centré) sans rupture, puis ajoute la vie : arc en rotation, wordmark,
/// progression discrète, pied.
///
/// Écran d'attente passif : la décision de route reste pilotée par le redirect
/// du GoRouter (auth + bootstrap). Aucune logique de navigation ici.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  /// Contrôleur d'entrée orchestrant l'arrivée du wordmark (+120 ms) puis
  /// l'apparition de la progression et du pied (~+400 ms, anti-clignotement).
  late final AnimationController _controller;

  late final Animation<double> _wordmarkEntrance;
  late final Animation<double> _chromeFade;

  /// Le symbole est rendu plein immédiatement (pas de fondu depuis le vide) :
  /// raccord sans saut avec la couche native / le loader web (spec §01), et un
  /// passage éclair vers /login montre le logo plutôt qu'un flash bleu. L'arc
  /// tourne de lui-même ([EteeloAnimatedSymbol]).
  static const Animation<double> _symbolShown = AlwaysStoppedAnimation<double>(
    1.0,
  );

  /// Durée totale de la chorégraphie d'entrée.
  static const Duration _entranceDuration = Duration(milliseconds: 900);

  /// Marge basse du pied (spec §02 : « marge 18–20 »).
  static const double _footerBottomMargin = AppSpacing.sectionGap;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _entranceDuration);

    // Wordmark : fondu + remontée, peu après l'affichage du symbole.
    _wordmarkEntrance = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.13, 0.42, curve: Curves.easeOut),
    );
    // Progression + pied : apparition après ~400 ms.
    _chromeFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced-motion : pas de chorégraphie, on affiche l'état final d'emblée.
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && _controller.value == 0.0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Abonnement ciblé : seuls la taille et l'orientation pilotent le layout.
    final size = MediaQuery.sizeOf(context);
    final orientation = MediaQuery.orientationOf(context);
    final metrics = SplashMetrics.fromMedia(
      size: size,
      orientation: orientation,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Fond sombre → icônes système claires (spec §02 « Barres système »).
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.surfaceDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surfaceDark,
        body: SafeArea(
          // En cas d'échec du bootstrap distant, le splash bascule sur
          // l'ErrorView (+ Réessayer) au lieu du chargement. buildWhen évite de
          // reconstruire l'animation à chaque tick du bootstrap.
          child: BlocBuilder<BootstrapBloc, BootstrapState>(
            buildWhen: (previous, current) =>
                previous.hasBlockingFailure != current.hasBlockingFailure,
            builder: (context, state) {
              if (state.hasBlockingFailure) {
                return const SplashErrorView();
              }
              return _buildLoading(metrics);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(SplashMetrics metrics) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reflow doux empilé ↔ en ligne (spec : 220 ms ease-out).
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: EteeloSplashBrand(
                  metrics: metrics,
                  reveal: _symbolShown,
                  wordmarkEntrance: _wordmarkEntrance,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _chromeFade,
                child: SplashProgressBar(width: metrics.progressWidth),
              ),
            ],
          ),
        ),
        if (metrics.showFooter)
          Positioned(
            left: 0,
            right: 0,
            bottom: _footerBottomMargin,
            child: FadeTransition(
              opacity: _chromeFade,
              child: const SplashFooter(),
            ),
          ),
      ],
    );
  }
}
