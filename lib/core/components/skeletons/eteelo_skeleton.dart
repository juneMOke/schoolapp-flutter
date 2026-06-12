import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Brique de base partagee des etats de chargement : un bloc « squelette » au
/// pouls anime qui respecte la preference systeme « reduire les animations »
/// (reduced-motion).
///
/// Reutilise par tous les squelettes de l'application (cf. regle « Etats
/// partages » dans CLAUDE.md / AGENTS.md). Quand `disableAnimations` est actif,
/// le bloc reste statique (aucune animation), conformement a l'accessibilite.
class EteeloSkeletonBox extends StatefulWidget {
  /// Largeur fixe. `null` => occupe la largeur disponible (Expanded parent).
  final double? width;

  /// Hauteur du bloc.
  final double height;

  /// Rayon de bordure (defaut : petit rayon du design system).
  final BorderRadius borderRadius;

  /// Couleur basse du pouls (defaut : `AppColors.border`).
  final Color? baseColor;

  /// Couleur haute du pouls (defaut : `AppColors.surfaceRaised`).
  final Color? highlightColor;

  const EteeloSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.brSm,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<EteeloSkeletonBox> createState() => _EteeloSkeletonBoxState();
}

class _EteeloSkeletonBoxState extends State<EteeloSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeletonPulse,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // reduced-motion : on ne fait pas tourner le ticker inutilement quand
    // l'utilisateur a desactive les animations (le build rend alors statique).
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_controller.isAnimating) _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.border;
    final highlightColor = widget.highlightColor ?? AppColors.surfaceRaised;

    // Accessibilite : on n'anime pas quand l'utilisateur a demande la
    // reduction des animations -> bloc statique a la couleur basse.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color =
            Color.lerp(baseColor, highlightColor, _controller.value) ??
            baseColor;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
