import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Helpers partagés pour les widgets disciplinaires.
abstract final class DisciplinaryCaseHelpers {
  /// Traduit un [DisciplinaryCaseErrorType] en message lisible par l'utilisateur.
  ///
  /// Utilisé dans [DisciplinaryCasesTab] et [DisciplinaryCaseCreateDialog].
  static String mapErrorType(
    AppLocalizations l10n,
    DisciplinaryCaseErrorType errorType,
  ) => switch (errorType) {
    DisciplinaryCaseErrorType.network => l10n.disciplinaryCasesNetworkError,
    DisciplinaryCaseErrorType.notFound => l10n.disciplinaryCasesNotFound,
    DisciplinaryCaseErrorType.validation =>
      l10n.disciplinaryCasesValidationError,
    DisciplinaryCaseErrorType.unauthorized ||
    DisciplinaryCaseErrorType.forbidden =>
      l10n.disciplinaryCasesUnauthorizedError,
    DisciplinaryCaseErrorType.invalidCredentials =>
      l10n.disciplinaryCasesInvalidCredentialsError,
    DisciplinaryCaseErrorType.server => l10n.disciplinaryCasesServerError,
    DisciplinaryCaseErrorType.storage => l10n.disciplinaryCasesStorageError,
    DisciplinaryCaseErrorType.auth => l10n.disciplinaryCasesAuthError,
    DisciplinaryCaseErrorType.none ||
    DisciplinaryCaseErrorType.unknown => l10n.disciplinaryCasesUnknownError,
  };
}
