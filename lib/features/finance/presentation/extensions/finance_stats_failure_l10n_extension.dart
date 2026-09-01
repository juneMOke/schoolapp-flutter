import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que dit le tableau de bord financier quand la lecture échoue.
///
/// Branchée sur le [Failure] lui-même, et non sur un enum maison reprojeté :
/// deux taxonomies de la même chose finissent par diverger, et celle qui perd
/// est toujours la seconde.
extension FinanceStatsFailureL10nX on Failure {
  String financeStatsMessage(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.financeStatsNetworkError,
    NotFoundFailure() => l10n.financeStatsNotFoundError,
    ValidationFailure() => l10n.financeStatsValidationError,
    // 403 : un droit qu'on n'a pas ne s'obtient pas en réessayant. Le message
    // le dit ; l'anatomie d'erreur partagée retirera aussi le bouton (FS-7).
    UnauthorizedFailure() => l10n.financeStatsUnauthorizedError,
    InvalidCredentialsFailure() => l10n.financeStatsInvalidCredentialsError,
    ServerFailure() => l10n.financeStatsServerError,
    StorageFailure() => l10n.financeStatsStorageError,
    AuthFailure() => l10n.financeStatsAuthError,
    _ => l10n.financeStatsUnknownError,
  };
}
