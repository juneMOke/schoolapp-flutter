import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une classe au choix : ce qui manque, et le taux de couverture.
class SessionClassTile extends StatelessWidget {
  final SessionClassSummary summary;
  final bool selected;
  final VoidCallback onTap;

  const SessionClassTile({
    super.key,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coverage = summary.total == 0
        ? 0.0
        : (summary.total - summary.missing) / summary.total;
    const radius = BorderRadius.all(
      Radius.circular(AppDimensions.photoSessionTileRadius),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.stateHover : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? AppColors.bleuArdoise : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.klass.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: AppDimensions.photoSessionCheck,
                        color: AppColors.bleuArdoise,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                summary.complete
                    ? Text(
                        l10n.photoSessionComplete(summary.total),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.photoDone,
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: l10n.photoSessionMissing(summary.missing),
                              style: const TextStyle(
                                color: AppColors.terreCuite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' · ${l10n.photoSessionStudents(summary.total)}',
                            ),
                          ],
                        ),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppRadius.brPill,
                  child: LinearProgressIndicator(
                    value: coverage,
                    minHeight: AppDimensions.photoSessionCoverageBar,
                    color: AppColors.photoDone,
                    backgroundColor: AppColors.surfaceAlt,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
