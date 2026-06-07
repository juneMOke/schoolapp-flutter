import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Carte d'invitation « avant recherche » du design-system Eteelo.
///
/// Médaillon d'icône + titre + message, centrée et plafonnée en largeur pour
/// occuper l'espace de façon cohérente quelle que soit la page (Facturation,
/// Réinscription…) ou la taille d'écran : pleine largeur sous [maxWidth],
/// centrée au-delà.
class SearchInvitationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final double maxWidth;

  const SearchInvitationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.maxWidth = AppDimensions.searchInvitationMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.brCard,
            border: Border.all(color: AppColors.border),
            boxShadow: AppElevation.shadowCard,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bleuArdoise.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(36),
                ),
                child: Icon(icon, size: 34, color: AppColors.bleuArdoise),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
