import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';

extension EnrollmentStatusColorX on EnrollmentStatus {
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

  Color get tableBackgroundColor => switch (this) {
    EnrollmentStatus.pending => AppColors.textMuted.withValues(alpha: 0.12),
    _ => badgeColor.withValues(alpha: 0.12),
  };

  Color get tableForegroundColor => switch (this) {
    EnrollmentStatus.pending => AppColors.textSecondary,
    _ => badgeColor,
  };
}
