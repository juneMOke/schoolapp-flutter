import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';

/// Issue de l'étape 2 (résultat) de l'encaissement.
enum CollectResultKind { processing, success, error }

/// En-tête sombre coiffé de l'indicateur 2 étapes (Confirmation → Résultat).
///
/// `resultActive=false` : étape 1 active (or-doux), étape 2 inerte.
/// `resultActive=true`  : étape 1 faite (vert + coche, trait vert), étape 2
/// active (or-doux).
class CollectStepHeader extends StatelessWidget {
  final bool resultActive;
  final String confirmLabel;
  final String resultLabel;
  final VoidCallback? onClose;

  const CollectStepHeader({
    super.key,
    required this.resultActive,
    required this.confirmLabel,
    required this.resultLabel,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Stack(
        children: [
          const KubaPatternLayer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              AppDimensions.spacingM,
              AppDimensions.spacingS,
              AppDimensions.spacingM,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _StepPill(
                        index: 1,
                        label: confirmLabel,
                        done: resultActive,
                        active: !resultActive,
                      ),
                      _StepConnector(active: resultActive),
                      _StepPill(
                        index: 2,
                        label: resultLabel,
                        done: false,
                        active: resultActive,
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textOnDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepConnector extends StatelessWidget {
  final bool active;

  const _StepConnector({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingS),
        color: active
            ? AppColors.vertSavane
            : AppColors.textOnDark.withValues(alpha: 0.25),
      ),
    );
  }
}

class _StepPill extends StatelessWidget {
  final int index;
  final String label;
  final bool done;
  final bool active;

  const _StepPill({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color contentColor;
    if (done) {
      circleColor = AppColors.vertSavane;
      contentColor = AppColors.textOnDark;
    } else if (active) {
      circleColor = AppColors.orDoux;
      contentColor = AppColors.bleuProfond;
    } else {
      circleColor = Colors.transparent;
      contentColor = AppColors.textOnDark.withValues(alpha: 0.55);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: active || done
                ? null
                : Border.all(
                    color: AppColors.textOnDark.withValues(alpha: 0.45),
                  ),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 16, color: contentColor)
              : Text(
                  '$index',
                  style: AppTypography.stepNumber.copyWith(color: contentColor),
                ),
        ),
        const SizedBox(width: AppDimensions.spacingS),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.badge.copyWith(
              color: active
                  ? AppColors.orDoux
                  : done
                  ? AppColors.textOnDark
                  : AppColors.textOnDark.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }
}

/// Médaillon animé de l'étape résultat : processing (spin), succès (pop + halo),
/// échec (statique rouge).
class CollectResultMedallion extends StatefulWidget {
  final CollectResultKind kind;

  const CollectResultMedallion({super.key, required this.kind});

  @override
  State<CollectResultMedallion> createState() => _CollectResultMedallionState();
}

class _CollectResultMedallionState extends State<CollectResultMedallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: AppMotion.spinnerCycle);
    _syncSpin();
  }

  @override
  void didUpdateWidget(covariant CollectResultMedallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _syncSpin();
    }
  }

  void _syncSpin() {
    if (widget.kind == CollectResultKind.processing) {
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
      CollectResultKind.processing => (
        AppColors.bleuArdoise,
        Icons.refresh_rounded,
      ),
      CollectResultKind.success => (
        AppColors.feeStatusPaid,
        Icons.check_rounded,
      ),
      CollectResultKind.error => (AppColors.danger, Icons.dns_outlined),
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
      child: widget.kind == CollectResultKind.processing
          ? (reduceMotion
                ? Icon(icon, size: 34, color: color)
                : RotationTransition(
                    turns: _spin,
                    child: Icon(icon, size: 34, color: color),
                  ))
          : Icon(icon, size: 36, color: color),
    );

    // Succès : halo en expansion + pop (sauf reduced-motion).
    if (widget.kind == CollectResultKind.success && !reduceMotion) {
      medallion = Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            key: const ValueKey('collect-halo'),
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
            key: const ValueKey('collect-pop'),
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
