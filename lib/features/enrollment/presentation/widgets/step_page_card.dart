import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Carte d'étape du parcours d'inscription (PARCOURS 19).
///
/// Carte surélevée à en-tête bi-ton, rail d'accent pleine hauteur à gauche et
/// médaillon dégradé à la teinte de l'étape. Terre cuite reste réservé à
/// l'action ; la teinte d'accent vient de l'identité de l'étape.
class StepPageCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final Widget child;

  const StepPageCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.child,
  });

  static const double _railWidth = 4;
  static const double _medallionSize = 46;
  static const double _medallionRadius = 14;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brCard,
        boxShadow: AppElevation.shadowStepCard,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brCard,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail d'accent pleine hauteur, opacité pleine.
            Container(width: _railWidth, color: accentColor),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  // Liseré clair interne (simule l'inset blanc 70 %).
                  border: Border(
                    top: BorderSide(
                      color: AppColors.surfaceRaised.withValues(alpha: 0.70),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.stepCardBody),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.stepCardHeaderH,
        vertical: AppSpacing.stepCardHeaderV,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceAlt, accentColor.withValues(alpha: 0.08)],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedallion(),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: accentColor,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    fontFamily: 'Lora',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedallion() {
    return Container(
      width: _medallionSize,
      height: _medallionSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withValues(alpha: 0.80)],
        ),
        borderRadius: BorderRadius.circular(_medallionRadius),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.55),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.textOnDark),
    );
  }
}
