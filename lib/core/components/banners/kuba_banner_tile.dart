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

  const KubaBannerTile({
    super.key,
    required this.label,
    required this.values,
    this.detail,
    this.valueColor = AppColors.presenceMarkOnBanner,
  });

  @override
  Widget build(BuildContext context) {
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.presenceMarkOnBannerMuted,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.payrollAgentBannerTile,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.presenceMarkOnBannerFaint),
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
}
