import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que dit le tableau de bord des inscriptions quand la lecture échoue.
///
/// Branchée sur le [Failure] lui-même, et non sur un enum maison reprojeté :
/// deux taxonomies de la même chose finissent par diverger, et celle qui perd
/// est toujours la seconde. C'est précisément ce qui arrivait ici — le bloc
/// tenait un `EnrollmentStatsErrorType` à neuf valeurs **et** une table de
/// messages français écrits en dur, hors de toute traduction.
extension EnrollmentDashboardFailureL10nX on Failure {
  String enrollmentDashboardMessage(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.enrollmentDashboardNetworkError,
    NotFoundFailure() => l10n.enrollmentDashboardNotFoundError,
    ValidationFailure() => l10n.enrollmentDashboardValidationError,
    // 403 : un droit qu'on n'a pas ne s'obtient pas en réessayant. Le message
    // le dit, et l'anatomie partagée retire aussi le bouton.
    UnauthorizedFailure() => l10n.enrollmentDashboardUnauthorizedError,
    InvalidCredentialsFailure() =>
      l10n.enrollmentDashboardInvalidCredentialsError,
    ServerFailure() => l10n.enrollmentDashboardServerError,
    StorageFailure() => l10n.enrollmentDashboardStorageError,
    AuthFailure() => l10n.enrollmentDashboardAuthError,
    _ => l10n.enrollmentDashboardUnknownError,
  };
}
