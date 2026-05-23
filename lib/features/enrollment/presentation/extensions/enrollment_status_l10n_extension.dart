// @Deprecated — Le libellé localisé est désormais géré par StatusBadge/EnrollmentStatusBadge.
// À supprimer lors du prochain audit du module Inscription.
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ignore: deprecated_member_use_from_same_package
@Deprecated(
  'Utiliser EnrollmentStatusBadge ou StatusBadge.enrollmentXxx(label: l10n.xxx) à la place. '
  'Sera supprimé lors du prochain audit du module Inscription.',
)
extension EnrollmentStatusL10nX on EnrollmentStatus {
  // ignore: deprecated_member_use_from_same_package
  @Deprecated(
    'Utiliser EnrollmentStatusBadge ou StatusBadge.enrollmentXxx(label: l10n.xxx) à la place.',
  )
  String localizedLabel(AppLocalizations l10n) {
    return switch (this) {
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
