import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les quatre totaux de l'étape 3 : cycles, niveaux, classes, cours.
///
/// **Ces chiffres ne sont jamais calculés localement.** Ils viennent de
/// `plan.counts`, rendu par la simulation. Un total local qui divergerait du
/// plan serait un engagement chiffré faux juste avant une écriture
/// irréversible — et le seul contrôle possible à l'œil, compter les cases
/// cochées, donnerait raison au chiffre faux.
///
/// La pastille « cours » est celle que la révision 1 de la spécification ne
/// pouvait pas porter : le volume pédagogique dérive des barèmes MINEDUC, que
/// seul le serveur connaît.
class ConfigurationTotalsBar extends StatelessWidget {
  final ProvisioningCounts counts;

  /// Masqué pendant le chargement et l'erreur : mieux vaut rien qu'un chiffre
  /// faux.
  final bool visible;

  const ConfigurationTotalsBar({
    super.key,
    required this.counts,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        _Total(
          icon: Icons.donut_large_rounded,
          value: counts.cycles,
          label: l10n.configurationTotalCycles(counts.cycles),
          color: AppColors.bleuArdoise,
        ),
        _Total(
          icon: Icons.stairs_rounded,
          value: counts.levels,
          label: l10n.configurationTotalLevels(counts.levels),
          color: AppColors.vertSavane,
        ),
        _Total(
          icon: Icons.meeting_room_rounded,
          value: counts.classrooms,
          label: l10n.configurationTotalClassrooms(counts.classrooms),
          color: AppColors.terreCuite,
        ),
        _Total(
          icon: Icons.menu_book_rounded,
          value: counts.courses,
          label: l10n.configurationTotalCourses(counts.courses),
          color: AppColors.orDoux,
        ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _Total({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowKpi,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$value',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
