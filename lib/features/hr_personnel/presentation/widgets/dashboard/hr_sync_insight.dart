import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 4 modifications encore sur la tablette » — et qu'elles sont déjà
/// comptées. Aucune action : la synchronisation est automatique.
///
/// L'appelant ne la pose que s'il y a quelque chose en attente : pas d'espace
/// réservé quand tout est parti.
class HrSyncInsight extends StatelessWidget {
  final int pending;

  const HrSyncInsight({super.key, required this.pending})
    : assert(pending > 0, 'Rien en attente : ne pas poser l\'alerte.');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.hrSyncInsightBackground,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.hrSyncInsightBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: AppDimensions.hrInsightIconSize,
              color: AppColors.hrSyncInsightAccent,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.hrSyncPendingTitle(pending),
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.hrSyncInsightTitle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.hrSyncPendingBody,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
