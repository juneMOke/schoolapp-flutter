import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Pastille numérotée du stepper d'inscription (PARCOURS 18).
///
/// États : courante (terre-cuite + halo), faite (vert-savane + coche + ombre),
/// à venir (surface-alt, non cliquable). Animation « pop » rejouée au passage
/// d'état, accessibilité (rôle bouton + état sélectionné) et reduced-motion.
class WizardStepDot extends StatelessWidget {
  final int index;
  final String title;
  final bool isCurrent;
  final bool isDone;
  final bool canTap;
  final bool reduceMotion;
  final VoidCallback onTap;

  const WizardStepDot({
    super.key,
    required this.index,
    required this.title,
    required this.isCurrent,
    required this.isDone,
    required this.canTap,
    required this.reduceMotion,
    required this.onTap,
  });

  static const double diameter = 34;
  static const double _labelWidth = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stepNumber = index + 1;
    final stepLabel = l10n.wizardStepNumberShort(stepNumber);

    return Semantics(
      button: canTap,
      enabled: canTap,
      selected: isCurrent,
      label: '$stepLabel · $title',
      onTap: canTap ? onTap : null,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: canTap
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              child: InkWell(
                onTap: canTap ? onTap : null,
                customBorder: const CircleBorder(),
                child: _buildDot(stepNumber),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(width: _labelWidth, child: _buildLabel(stepLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int stepNumber) {
    final dot = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.fast,
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _circleColor,
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 2),
        boxShadow: _shadow,
      ),
      child: isDone
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.textOnDark,
            )
          : Text(
              '$stepNumber',
              style: AppTypography.stepNumber.copyWith(
                color: isCurrent ? AppColors.textOnDark : AppColors.textMuted,
              ),
            ),
    );

    // Le pop est rejoué quand l'état (courante/faite) change : la clé varie
    // alors, ce qui recrée le TweenAnimationBuilder et relance l'animation.
    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('pop-$index-$isCurrent-$isDone'),
      tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.85, end: 1.0),
      duration: reduceMotion ? Duration.zero : AppMotion.pop,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: dot,
    );
  }

  Widget _buildLabel(String stepLabel) {
    return Column(
      children: [
        Text(
          stepLabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: isCurrent ? AppColors.terreCuite : AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelSmall.copyWith(
            color: isCurrent
                ? AppColors.terreCuite
                : isDone
                ? AppColors.vertSavane
                : AppColors.textMuted,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color get _circleColor => isCurrent
      ? AppColors.terreCuite
      : isDone
      ? AppColors.vertSavane
      : AppColors.surfaceAlt;

  Color get _borderColor => isCurrent
      ? AppColors.terreCuite
      : isDone
      ? AppColors.vertSavane
      : AppColors.border;

  List<BoxShadow>? get _shadow {
    if (isCurrent) {
      return [
        BoxShadow(
          color: AppColors.terreCuite.withValues(alpha: 0.40),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
    }
    if (isDone) {
      return [
        BoxShadow(
          color: AppColors.vertSavane.withValues(alpha: 0.30),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return null;
  }
}
