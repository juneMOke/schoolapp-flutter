import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Afficher les désactivés (N) » — un interrupteur en pilule, éteint par
/// défaut et non persisté. À ne montrer que si [count] ≥ 1.
class ShowSuspendedToggle extends StatelessWidget {
  final bool value;
  final int count;
  final ValueChanged<bool> onChanged;

  const ShowSuspendedToggle({
    super.key,
    required this.value,
    required this.count,
    required this.onChanged,
  });

  static const double _height = 34;
  static const double _trackWidth = 30;
  static const double _trackHeight = 18;
  static const double _thumb = 14;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.fast;
    return Semantics(
      toggled: value,
      button: true,
      label: '${l10n.suspensionToggleLabel} ($count)',
      excludeSemantics: true,
      child: Material(
        color: value ? AppColors.suspendedSurface : AppColors.surfaceRaised,
        shape: StadiumBorder(
          side: BorderSide(
            color: value ? AppColors.suspendedBorder : AppColors.border,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => onChanged(!value),
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs + 2,
                right: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: duration,
                    width: _trackWidth,
                    height: _trackHeight,
                    padding: const EdgeInsets.all(2),
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.brPill,
                      color: value
                          ? AppColors.bleuArdoise
                          : AppColors.borderStrong,
                    ),
                    child: const SizedBox.square(
                      dimension: _thumb,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceRaised,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.suspensionToggleLabel,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Count(count: count, on: value),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final int count;
  final bool on;

  const _Count({required this.count, required this.on});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: AppRadius.brPill,
      color: on ? AppColors.surfaceRaised : AppColors.surfaceAlt,
    ),
    child: Text(
      '$count',
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
