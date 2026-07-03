import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Accès au bulletin officiel imprimable (spec §9) — **DORMANT en v1** : la
/// feature « bulletin officiel » n'a aucune couche data ici (spec séparée).
/// Rendue en carte grisée non cliquable avec un badge « Bientôt disponible ».
class ResultatBulletinOfficielCard extends StatelessWidget {
  const ResultatBulletinOfficielCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.resultatsOfficialBulletinTitle,
      enabled: false,
      child: Opacity(
        opacity: 0.6,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.brMd,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.resultatsOfficialBulletinTitle,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.bleuProfond,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.resultatsOfficialBulletinSubtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: AppRadius.brPill,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  l10n.resultatsComingSoon,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
