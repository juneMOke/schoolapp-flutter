import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

extension ClassroomStatsErrorL10nX on ClassroomStatsErrorType {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    ClassroomStatsErrorType.network => l10n.classesStatsNetworkError,
    ClassroomStatsErrorType.notFound => l10n.classesStatsNotFoundError,
    ClassroomStatsErrorType.validation => l10n.classesStatsValidationError,
    ClassroomStatsErrorType.unauthorized => l10n.classesStatsUnauthorizedError,
    ClassroomStatsErrorType.invalidCredentials =>
      l10n.classesStatsInvalidCredentialsError,
    ClassroomStatsErrorType.server => l10n.classesStatsServerError,
    ClassroomStatsErrorType.storage => l10n.classesStatsStorageError,
    ClassroomStatsErrorType.auth => l10n.classesStatsAuthError,
    ClassroomStatsErrorType.unknown => l10n.classesStatsUnknownError,
    ClassroomStatsErrorType.none => l10n.classesStatsUnknownError,
  };
}
