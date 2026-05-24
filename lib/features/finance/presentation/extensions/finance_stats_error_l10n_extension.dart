import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

extension FinanceStatsErrorL10nX on FinanceStatsErrorType {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    FinanceStatsErrorType.network => l10n.financeStatsNetworkError,
    FinanceStatsErrorType.notFound => l10n.financeStatsNotFoundError,
    FinanceStatsErrorType.validation => l10n.financeStatsValidationError,
    FinanceStatsErrorType.unauthorized => l10n.financeStatsUnauthorizedError,
    FinanceStatsErrorType.invalidCredentials =>
      l10n.financeStatsInvalidCredentialsError,
    FinanceStatsErrorType.server => l10n.financeStatsServerError,
    FinanceStatsErrorType.storage => l10n.financeStatsStorageError,
    FinanceStatsErrorType.auth => l10n.financeStatsAuthError,
    FinanceStatsErrorType.unknown => l10n.financeStatsUnknownError,
    FinanceStatsErrorType.none => l10n.financeStatsUnknownError,
  };
}
