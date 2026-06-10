import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';

/// Issue d'une sur-couche de résultat (traitement asynchrone).
enum EteeloResultKind { processing, success, error }

/// Médaillon animé du design-system pour les sur-couches de résultat :
/// processing (spin), succès (pop + halo), échec (statique rouge).
///
/// Vocabulaire partagé entre l'encaissement (Finances) et la répartition des
/// classes : respecte `reduced-motion`.
class EteeloResultMedallion extends StatefulWidget {
  final EteeloResultKind kind;

  const EteeloResultMedallion({super.key, required this.kind});

  @override
  State<EteeloResultMedallion> createState() => _EteeloResultMedallionState();
}

class _EteeloResultMedallionState extends State<EteeloResultMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: AppMotion.spinnerCycle);
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant EteeloResultMedallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _syncSpin();
    }
  }

  void _syncSpin() {
    if (widget.kind == EteeloResultKind.processing) {
      _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final (color, icon) = switch (widget.kind) {
      EteeloResultKind.processing => (
        AppColors.bleuArdoise,
        Icons.refresh_rounded,
      ),
      EteeloResultKind.success => (
        AppColors.feeStatusPaid,
        Icons.check_rounded,
      ),
      EteeloResultKind.error => (AppColors.danger, Icons.dns_outlined),
    };

    Widget medallion = Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: widget.kind == EteeloResultKind.processing
          ? (reduceMotion
                ? Icon(icon, size: 34, color: color)
                : RotationTransition(
                    turns: _spin,
                    child: Icon(icon, size: 34, color: color),
                  ))
          : Icon(icon, size: 36, color: color),
    );

    // Succès : halo en expansion + pop (sauf reduced-motion).
    if (widget.kind == EteeloResultKind.success && !reduceMotion) {
      medallion = Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: const ValueKey('result-halo'),
            tween: Tween<double>(begin: 0, end: 1),
            duration: AppMotion.pop,
            curve: Curves.easeOut,
            builder: (context, t, _) => Container(
              width: 72 + 36 * t,
              height: 72 + 36 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18 * (1 - t)),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            key: const ValueKey('result-pop'),
            tween: Tween<double>(begin: 0.85, end: 1),
            duration: AppMotion.pop,
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: medallion,
          ),
        ],
      );
    }

    return medallion;
  }
}
