import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget buildSearchFormStatusMenuItem({
  required String statusValue,
  required String label,
  required AppLocalizations l10n,
  required bool isSelected,
}) {
  return AnimatedContainer(
    duration: AppMotion.fast,
    curve: AppMotion.outCurve,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs + 2,
      vertical: AppSpacing.xs + 2,
    ),
    decoration: BoxDecoration(
      color: isSelected
          ? AppColors.bleuArdoise.withValues(alpha: 0.08)
          : AppColors.surface,
      borderRadius: AppRadius.brSm,
      border: Border.all(
        color: isSelected
            ? AppColors.bleuArdoise.withValues(alpha: 0.25)
            : AppColors.border,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildEnrollmentStatusBadge(
            statusValue: statusValue,
            label: label,
            l10n: l10n,
            size: StatusBadgeSize.small,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        AnimatedOpacity(
          duration: AppMotion.fast,
          curve: AppMotion.outCurve,
          opacity: isSelected ? 1 : 0,
          child: const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.bleuArdoise,
          ),
        ),
      ],
    ),
  );
}

Widget buildSearchFormSelectedStatusItem({
  required String statusValue,
  required String label,
  required AppLocalizations l10n,
}) {
  return Align(
    alignment: Alignment.centerLeft,
    child: _buildEnrollmentStatusBadge(
      statusValue: statusValue,
      label: label,
      l10n: l10n,
      size: StatusBadgeSize.medium,
    ),
  );
}

StatusBadge _buildEnrollmentStatusBadge({
  required String statusValue,
  required String label,
  required AppLocalizations l10n,
  required StatusBadgeSize size,
}) {
  final status = EnrollmentStatus.fromString(statusValue);
  return switch (status) {
    EnrollmentStatus.preRegistered => StatusBadge.enrollmentPreRegistered(
      label: label,
      size: size,
    ),
    EnrollmentStatus.inProgress => StatusBadge.enrollmentInProgress(
      label: label,
      size: size,
    ),
    EnrollmentStatus.adminCompleted => StatusBadge.enrollmentAdminCompleted(
      label: label,
      size: size,
    ),
    EnrollmentStatus.financialCompleted =>
      StatusBadge.enrollmentFinancialCompleted(label: label, size: size),
    EnrollmentStatus.completed => StatusBadge.enrollmentCompleted(
      label: label,
      size: size,
    ),
    EnrollmentStatus.cancelled => StatusBadge.enrollmentCancelled(
      label: label,
      size: size,
    ),
    EnrollmentStatus.validated => StatusBadge.enrollmentValidated(
      label: label,
      size: size,
    ),
    EnrollmentStatus.rejected => StatusBadge.enrollmentRejected(
      label: label,
      size: size,
    ),
    EnrollmentStatus.pending => StatusBadge.enrollmentPending(
      label: l10n.statusPending,
      size: size,
    ),
  };
}
