import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Un chiffre d'un `KubaBanner` : son libellé, une valeur par ligne (une
/// devise par ligne), et une ligne de détail facultative.
class KubaBannerTile extends StatelessWidget {
  final String label;
  final List<String> values;

  /// `null` : pas de ligne de détail.
  final String? detail;
  final Color valueColor;

  /// Une tuile de texte plutôt que de chiffre (le calendrier scolaire :
  /// « P4 · 2e semestre », « Examens du 2e semestre ») : libellé en
  /// petites capitales, valeur à 14 qui passe à la ligne, détail en petit.
  /// Faux par défaut.
  final bool dense;

  const KubaBannerTile({
    super.key,
    required this.label,
    required this.values,
    this.detail,
    this.valueColor = AppColors.kubaBannerOn,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dense) return _dense();
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.kubaBannerOnMuted,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.kubaBannerTile,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.kubaBannerOnFaint),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: muted,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final value in values)
            // Un montant ne se coupe jamais : il rétrécit plutôt.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          if (detail case final detail?)
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
        ],
      ),
    );
  }

  Widget _dense() => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.md - AppSpacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: AppColors.kubaBannerTile,
      borderRadius: AppRadius.brMd,
      border: Border.all(color: AppColors.kubaBannerOnFaint),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.kubaBannerOnMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final value in values)
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(color: valueColor),
          ),
        if (detail case final detail?) ...[
          const SizedBox(height: AppSpacing.xs / 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.kubaBannerOnMuted,
            ),
          ),
        ],
      ],
    ),
  );
}
