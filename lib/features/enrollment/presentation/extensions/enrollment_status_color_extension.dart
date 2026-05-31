import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

/// @Deprecated Le mapping couleur est désormais centralisé dans
/// [StatusBadge] via ses factories nommées.
/// À supprimer quand aucun import ne pointe plus sur cette extension.
extension EnrollmentStatusColorX on EnrollmentStatus {
  @Deprecated(
    'Utiliser StatusBadge.enrollmentXxx(label: ...) à la place. '
    'Cette extension sera supprimée lors du prochain audit du module Inscription.',
  )
  Color get badgeColor {
    return switch (this) {
      EnrollmentStatus.preRegistered => AppColors.warning,
      EnrollmentStatus.inProgress => AppColors.info,
      EnrollmentStatus.adminCompleted => AppColors.bleuArdoise,
      EnrollmentStatus.financialCompleted => AppColors.orDoux,
      EnrollmentStatus.completed => AppColors.success,
      EnrollmentStatus.cancelled => AppColors.error,
      EnrollmentStatus.validated => AppColors.success,
      EnrollmentStatus.rejected => AppColors.error,
      EnrollmentStatus.pending => AppColors.textMuted,
    };
  }

  @Deprecated('Sera supprimé lors du prochain audit du module Inscription.')
  Color get tableBackgroundColor => switch (this) {
    EnrollmentStatus.pending => AppColors.textMuted.withValues(alpha: 0.12),
    EnrollmentStatus.preRegistered => AppColors.warning.withValues(alpha: 0.12),
    EnrollmentStatus.inProgress => AppColors.info.withValues(alpha: 0.12),
    EnrollmentStatus.adminCompleted => AppColors.bleuArdoise.withValues(
      alpha: 0.12,
    ),
    EnrollmentStatus.financialCompleted => AppColors.orDoux.withValues(
      alpha: 0.12,
    ),
    EnrollmentStatus.completed => AppColors.success.withValues(alpha: 0.12),
    EnrollmentStatus.cancelled => AppColors.error.withValues(alpha: 0.12),
    EnrollmentStatus.validated => AppColors.success.withValues(alpha: 0.12),
    EnrollmentStatus.rejected => AppColors.error.withValues(alpha: 0.12),
  };

  @Deprecated('Sera supprimé lors du prochain audit du module Inscription.')
  Color get tableForegroundColor => switch (this) {
    EnrollmentStatus.pending => AppColors.textSecondary,
    EnrollmentStatus.preRegistered => AppColors.warning,
    EnrollmentStatus.inProgress => AppColors.info,
    EnrollmentStatus.adminCompleted => AppColors.bleuArdoise,
    EnrollmentStatus.financialCompleted => AppColors.orDoux,
    EnrollmentStatus.completed => AppColors.success,
    EnrollmentStatus.cancelled => AppColors.error,
    EnrollmentStatus.validated => AppColors.success,
    EnrollmentStatus.rejected => AppColors.error,
  };
}
