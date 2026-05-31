import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Façade rétro-compatible vers [StatusBadge].
///
/// Couvre l'ensemble des 9 valeurs de [EnrollmentStatus].
/// Les écrans existants continuent à compiler sans modification.
///
/// Migration progressive : à terme, les écrans pourront appeler
/// [StatusBadge.enrollmentXxx] directement.
class EnrollmentStatusBadge extends StatelessWidget {
  final EnrollmentStatus status;

  const EnrollmentStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (status) {
      EnrollmentStatus.preRegistered => StatusBadge.enrollmentPreRegistered(
        label: l10n.enrollmentStatusPreRegistered,
      ),
      EnrollmentStatus.inProgress => StatusBadge.enrollmentInProgress(
        label: l10n.enrollmentStatusInProgress,
      ),
      EnrollmentStatus.adminCompleted => StatusBadge.enrollmentAdminCompleted(
        label: l10n.enrollmentStatusAdminCompleted,
      ),
      EnrollmentStatus.financialCompleted =>
        StatusBadge.enrollmentFinancialCompleted(
          label: l10n.enrollmentStatusFinancialCompleted,
        ),
      EnrollmentStatus.completed => StatusBadge.enrollmentCompleted(
        label: l10n.enrollmentStatusCompleted,
      ),
      EnrollmentStatus.cancelled => StatusBadge.enrollmentCancelled(
        label: l10n.enrollmentStatusCancelled,
      ),
      EnrollmentStatus.validated => StatusBadge.enrollmentValidated(
        label: l10n.enrollmentStatusValidated,
      ),
      EnrollmentStatus.rejected => StatusBadge.enrollmentRejected(
        label: l10n.enrollmentStatusRejected,
      ),
      EnrollmentStatus.pending => StatusBadge.enrollmentPending(
        label: l10n.statusPending,
      ),
    };
  }
}
