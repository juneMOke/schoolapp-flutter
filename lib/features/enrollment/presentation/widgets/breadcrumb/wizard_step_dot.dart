import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Step du stepper d'inscription (PARCOURS 18) : chip numéroté centré, encadré
/// par des connecteurs (vert-savane si franchi, neutre sinon), avec « ÉTAPE N »
/// (teinte neutre) au-dessus de la description (terre-cuite si courante,
/// vert-savane si faite, neutre sinon), centrées sous le chip.
///
/// Chip animé (pop rejoué au changement d'état), accessibilité et reduced-motion.
class WizardStepDot extends StatelessWidget {
  final int index;
  final String title;
  final bool isCurrent;
  final bool isDone;
  final bool canTap;
  final bool reduceMotion;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;
  final bool leftConnectorActive;
  final bool rightConnectorActive;

  const WizardStepDot({
    super.key,
    required this.index,
    required this.title,
    required this.isCurrent,
    required this.isDone,
    required this.canTap,
    required this.reduceMotion,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
    required this.leftConnectorActive,
    required this.rightConnectorActive,
  });

  static const double diameter = 34;

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
        child: MouseRegion(
          cursor: canTap
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: InkWell(
            onTap: canTap ? onTap : null,
            borderRadius: AppRadius.brSm,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chip centré, encadré par les connecteurs (pleine largeur).
                SizedBox(
                  height: diameter,
                  child: Row(
                    children: [
                      Expanded(
                        child: _connector(
                          active: leftConnectorActive,
                          visible: !isFirst,
                        ),
                      ),
                      _buildDot(stepNumber),
                      Expanded(
                        child: _connector(
                          active: rightConnectorActive,
                          visible: !isLast,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildLabel(stepLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _connector({required bool active, required bool visible}) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Center(
      child: Container(
        height: 2,
        color: active ? AppColors.vertSavane : AppColors.border,
      ),
    );
  }

  Widget _buildLabel(String stepLabel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // « ÉTAPE N » — toujours en teinte neutre (non sélectionné).
          Text(
            stepLabel.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          // Description — couleur selon l'état.
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: _descriptionColor,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
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

  Color get _descriptionColor => isCurrent
      ? AppColors.terreCuite
      : isDone
      ? AppColors.vertSavane
      : AppColors.textMuted;

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
