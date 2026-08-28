import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/wizard/wizard_step_progression.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Rail de progression de l'assistant : cinq pastilles reliées par des traits,
/// sur le fond sombre de la barre de titre.
///
/// La mécanique — franchi, courant, atteignable — vient de
/// [WizardStepProgression], partagée avec le parcours d'inscription. Ce widget
/// n'en est que l'habillage.
///
/// En dessous de 560 dp, les libellés disparaissent : il ne reste que les
/// pastilles, qui défilent horizontalement. Un libellé tronqué au tiers ne dit
/// rien de plus qu'un numéro, et prend la place du contenu.
class ConfigurationStepper extends StatelessWidget {
  final WizardStepProgression progression;
  final List<String> titles;
  final ValueChanged<int> onStepTap;

  /// Pastilles seules : sous 560 dp.
  final bool compact;

  const ConfigurationStepper({
    super.key,
    required this.progression,
    required this.titles,
    required this.onStepTap,
    this.compact = false,
  });

  static const double dotSize = 34;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final row = Row(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var index = 0; index < titles.length; index++) ...[
          _StepDot(
            status: progression.statusAt(index),
            title: titles[index],
            total: titles.length,
            compact: compact,
            reduceMotion: reduceMotion,
            onTap: () => onStepTap(index),
          ),
          if (index < titles.length - 1)
            _Connector(
              active: progression.connectorAfter(index),
              reduceMotion: reduceMotion,
              expand: !compact,
            ),
        ],
      ],
    );

    return Container(
      color: AppColors.bleuProfond,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: compact
          ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: row)
          : row,
    );
  }
}

class _StepDot extends StatelessWidget {
  final WizardStepStatus status;
  final String title;
  final int total;
  final bool compact;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _StepDot({
    required this.status,
    required this.title,
    required this.total,
    required this.compact,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = status.index + 1;

    final Color background;
    final Color border;
    if (status.isCurrent) {
      background = AppColors.terreCuite;
      border = AppColors.terreCuite;
    } else if (status.isDone) {
      background = AppColors.vertSavane;
      border = AppColors.vertSavane;
    } else {
      background = Colors.transparent;
      border = AppColors.textOnDark.withValues(alpha: 0.28);
    }

    final dot = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.medium,
      width: ConfigurationStepper.dotSize,
      height: ConfigurationStepper.dotSize,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: status.isCurrent && !reduceMotion
            ? [
                BoxShadow(
                  color: AppColors.terreCuite.withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: status.isDone
          ? const Icon(
              Icons.check_rounded,
              size: 17,
              color: AppColors.textOnDark,
            )
          : Text(
              '$number',
              style: AppTypography.labelMedium.copyWith(
                color: status.isCurrent
                    ? AppColors.textOnDark
                    : AppColors.textOnDark.withValues(alpha: 0.62),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
    );

    return Semantics(
      button: status.canTap,
      enabled: status.canTap,
      selected: status.isCurrent,
      label: l10n.configurationStepSemantics(number, total, title),
      child: ExcludeSemantics(
        child: Opacity(
          // .75 plutôt que masqué : une étape hors d'atteinte doit rester
          // lisible — c'est ce qui annonce le chemin restant.
          opacity: status.canTap ? 1 : 0.75,
          child: InkWell(
            onTap: status.canTap ? onTap : null,
            borderRadius: BorderRadius.circular(ConfigurationStepper.dotSize),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: compact
                  ? dot
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        dot,
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          title,
                          style: AppTypography.labelMedium.copyWith(
                            color: status.isCurrent
                                ? AppColors.textOnDark
                                : AppColors.textOnDark.withValues(alpha: 0.72),
                            fontWeight: status.isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool active;
  final bool reduceMotion;
  final bool expand;

  const _Connector({
    required this.active,
    required this.reduceMotion,
    required this.expand,
  });

  @override
  Widget build(BuildContext context) {
    final bar = AnimatedContainer(
      duration: reduceMotion ? Duration.zero : AppMotion.medium,
      height: 2,
      width: expand ? null : AppSpacing.lg,
      color: active
          ? AppColors.vertSavane
          : AppColors.textOnDark.withValues(alpha: 0.18),
    );

    return expand ? Expanded(child: bar) : bar;
  }
}
