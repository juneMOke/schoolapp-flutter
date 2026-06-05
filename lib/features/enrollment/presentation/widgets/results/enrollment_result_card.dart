import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_chip.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_result_card.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentResultCard extends StatelessWidget {
  final EnrollmentSummary enrollment;
  final VoidCallback onTap;

  const EnrollmentResultCard({
    super.key,
    required this.enrollment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = EnrollmentStatus.fromString(enrollment.status);
    final fullName =
        '${enrollment.student.lastName} ${enrollment.student.firstName}';
    final statusLabel = _statusLabel(status, l10n);

    return EteeloResultCard(
      onTap: onTap,
      accentColor: _statusColor(status),
      semanticLabel: l10n.enrollmentResultCardOpenLabel(fullName, statusLabel),
      avatar: core_avatar.StudentAvatar(
        firstName: enrollment.student.firstName,
        lastName: enrollment.student.lastName,
        studentId: enrollment.student.id,
        size: core_avatar.AvatarSize.lg,
        variant: _avatarVariantForStatus(status),
      ),
      title: Text(
        enrollment.student.lastName,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          enrollment.student.firstName,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      statusPill: EnrollmentStatusBadge(
        status: status,
        style: StatusBadgeStyle.filled,
      ),
      chips: [
        EteeloChip(
          icon: Icons.cake_outlined,
          label: _formatDate(enrollment.student.dateOfBirth),
        ),
      ],
    );
  }

  core_avatar.AvatarVariant _avatarVariantForStatus(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.completed ||
      EnrollmentStatus.validated => core_avatar.AvatarVariant.solid,
      _ => core_avatar.AvatarVariant.outlined,
    };
  }

  Color _statusColor(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.preRegistered => AppColors.warning,
      EnrollmentStatus.inProgress => AppColors.bleuArdoise,
      EnrollmentStatus.adminCompleted => AppColors.info,
      EnrollmentStatus.financialCompleted => AppColors.orDoux,
      EnrollmentStatus.completed ||
      EnrollmentStatus.validated => AppColors.success,
      EnrollmentStatus.cancelled ||
      EnrollmentStatus.pending => AppColors.textMuted,
      EnrollmentStatus.rejected => AppColors.error,
    };
  }

  String _statusLabel(EnrollmentStatus status, AppLocalizations l10n) {
    return switch (status) {
      EnrollmentStatus.preRegistered => l10n.enrollmentStatusPreRegistered,
      EnrollmentStatus.inProgress => l10n.enrollmentStatusInProgress,
      EnrollmentStatus.adminCompleted => l10n.enrollmentStatusAdminCompleted,
      EnrollmentStatus.financialCompleted =>
        l10n.enrollmentStatusFinancialCompleted,
      EnrollmentStatus.completed => l10n.enrollmentStatusCompleted,
      EnrollmentStatus.cancelled => l10n.enrollmentStatusCancelled,
      EnrollmentStatus.validated => l10n.enrollmentStatusValidated,
      EnrollmentStatus.rejected => l10n.enrollmentStatusRejected,
      EnrollmentStatus.pending => l10n.statusPending,
    };
  }

  String _formatDate(String raw) {
    final parts = raw.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return raw;
  }
}
