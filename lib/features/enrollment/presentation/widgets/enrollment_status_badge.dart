import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/enrollment_theme.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentStatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const EnrollmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusColor = _getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getStatusText(l10n),
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    return switch (status) {
      EnrollmentStatus.preRegistered => EnrollmentTheme.pendingColor,
      EnrollmentStatus.inProgress => Colors.blue,
      EnrollmentStatus.adminCompleted => Colors.indigo,
      EnrollmentStatus.financialCompleted => Colors.teal,
      EnrollmentStatus.completed => EnrollmentTheme.validatedColor,
      EnrollmentStatus.cancelled => EnrollmentTheme.rejectedColor,
      EnrollmentStatus.validated => EnrollmentTheme.validatedColor,
      EnrollmentStatus.rejected => EnrollmentTheme.rejectedColor,
      EnrollmentStatus.pending => EnrollmentTheme.pendingColor,
    };
  }

  String _getStatusText(AppLocalizations l10n) {
    return switch (status) {
      EnrollmentStatus.preRegistered => l10n.statusPending,
      EnrollmentStatus.inProgress => l10n.enrollmentStatusInProgress,
      EnrollmentStatus.adminCompleted => l10n.enrollmentStatusAdminCompleted,
      EnrollmentStatus.financialCompleted =>
        l10n.enrollmentStatusFinancialCompleted,
      EnrollmentStatus.completed => l10n.enrollmentStatusCompleted,
      EnrollmentStatus.cancelled => l10n.enrollmentStatusCancelled,
      EnrollmentStatus.validated => l10n.statusValidated,
      EnrollmentStatus.rejected => l10n.statusRejected,
      EnrollmentStatus.pending => l10n.statusPending,
    };
  }
}
