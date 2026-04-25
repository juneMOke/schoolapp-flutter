import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

extension StudentChargesErrorL10nX on StudentChargesErrorType {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    StudentChargesErrorType.network => l10n.studentChargesNetworkError,
    StudentChargesErrorType.notFound => l10n.studentChargesNotFound,
    StudentChargesErrorType.validation => l10n.studentChargesValidationError,
    StudentChargesErrorType.unauthorized =>
      l10n.studentChargesUnauthorizedError,
    StudentChargesErrorType.invalidCredentials =>
      l10n.studentChargesInvalidCredentialsError,
    StudentChargesErrorType.server => l10n.studentChargesServerError,
    StudentChargesErrorType.storage => l10n.studentChargesStorageError,
    StudentChargesErrorType.auth => l10n.studentChargesAuthError,
    StudentChargesErrorType.unknown => l10n.studentChargesUnknownError,
    StudentChargesErrorType.none => l10n.studentChargesUnknownError,
  };
}
