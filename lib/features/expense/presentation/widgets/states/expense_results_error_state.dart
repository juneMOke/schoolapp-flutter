import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur d'une zone de résultats du module (règle n°10) : une anatomie,
/// quatre tonalités.
///
/// Le registre est **local** : sa seule panne réelle est une base illisible,
/// rangée avec le serveur (réessayer, puis appeler à l'aide). Les trois autres
/// tonalités restent câblées pour que le jour où une lecture passerait par le
/// réseau, le 403 ne propose toujours pas « Réessayer » — le refus est
/// probablement volontaire sur un registre sensible.
class ExpenseResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  const ExpenseResultsErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = typeOf(failure);
    final incident = failure is ApiErrorDetails
        ? (failure as ApiErrorDetails).incidentId
        : null;
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.expenseErrorNetworkTitle,
        EteeloErrorType.unauthorized => l10n.expenseErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.expenseErrorForbiddenTitle,
        _ => l10n.expenseErrorStorageTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.expenseErrorNetwork,
        EteeloErrorType.unauthorized => l10n.expenseErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.expenseErrorForbidden,
        _ => l10n.expenseErrorStorage,
      },
      primaryAction: switch (type) {
        EteeloErrorType.forbidden => null,
        EteeloErrorType.unauthorized =>
          onReconnect == null
              ? null
              : EteeloButton.primary(
                  label: l10n.expenseErrorReconnect,
                  icon: Icons.login,
                  onPressed: onReconnect,
                  fullWidth: false,
                ),
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.expenseErrorRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      },
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incident != null &&
              incident.trim().isNotEmpty
          ? l10n.expenseErrorIncidentCode(incident)
          : null,
    );
  }

  static EteeloErrorType typeOf(Failure failure) => switch (failure) {
    NetworkFailure() => EteeloErrorType.network,
    InvalidCredentialsFailure() ||
    AuthFailure() => EteeloErrorType.unauthorized,
    UnauthorizedFailure() => EteeloErrorType.forbidden,
    ServerFailure() || StorageFailure() => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };
}
