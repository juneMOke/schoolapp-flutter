import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

extension PaymentsErrorL10nX on PaymentsErrorType {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    PaymentsErrorType.network => l10n.facturationPaymentsNetworkError,
    PaymentsErrorType.notFound => l10n.facturationPaymentsNotFound,
    PaymentsErrorType.validation => l10n.facturationPaymentsValidationError,
    PaymentsErrorType.unauthorized => l10n.facturationPaymentsUnauthorizedError,
    PaymentsErrorType.invalidCredentials =>
      l10n.facturationPaymentsInvalidCredentialsError,
    PaymentsErrorType.server => l10n.facturationPaymentsServerError,
    PaymentsErrorType.storage => l10n.facturationPaymentsStorageError,
    PaymentsErrorType.auth => l10n.facturationPaymentsAuthError,
    PaymentsErrorType.unknown => l10n.facturationPaymentsUnknownError,
    PaymentsErrorType.none => l10n.facturationPaymentsUnknownError,
  };

  String localizedAllocationsMessage(AppLocalizations l10n) => switch (this) {
    PaymentsErrorType.network => l10n.facturationPaymentAllocationsNetworkError,
    PaymentsErrorType.notFound => l10n.facturationPaymentAllocationsNotFound,
    PaymentsErrorType.validation =>
      l10n.facturationPaymentAllocationsValidationError,
    PaymentsErrorType.unauthorized =>
      l10n.facturationPaymentAllocationsUnauthorizedError,
    PaymentsErrorType.invalidCredentials =>
      l10n.facturationPaymentAllocationsInvalidCredentialsError,
    PaymentsErrorType.server => l10n.facturationPaymentAllocationsServerError,
    PaymentsErrorType.storage => l10n.facturationPaymentAllocationsStorageError,
    PaymentsErrorType.auth => l10n.facturationPaymentAllocationsAuthError,
    PaymentsErrorType.unknown => l10n.facturationPaymentAllocationsUnknownError,
    PaymentsErrorType.none => l10n.facturationPaymentAllocationsUnknownError,
  };
}