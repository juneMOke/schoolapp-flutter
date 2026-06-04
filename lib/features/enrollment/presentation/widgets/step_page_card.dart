import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceAlt,
                  accentColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: AppRadius.card),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor,
                        accentColor.withValues(alpha: 0.78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.textOnDark),
                ),
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
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: AppRadius.card),
              border: Border(
                left: BorderSide(
                  color: accentColor.withValues(alpha: 0.45),
                  width: 4,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
