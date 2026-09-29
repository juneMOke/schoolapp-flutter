import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Erreur de la zone de résultats du fichier (règle n°10) : une anatomie,
/// quatre tonalités. Le 403 ne propose jamais « Réessayer » : le refus est
/// volontaire sur des dossiers sensibles.
///
/// [neverSynced] : le fichier n'a jamais été téléchargé et le réseau manque —
/// la tonalité réseau, avec « Réessayer ».
class StaffResultsErrorState extends StatelessWidget {
  final Failure? failure;
  final bool neverSynced;
  final VoidCallback? onRetry;
  final VoidCallback? onReconnect;

  const StaffResultsErrorState({
    super.key,
    this.failure,
    this.neverSynced = false,
    this.onRetry,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = neverSynced ? EteeloErrorType.network : typeOf(failure);
    final incident = failure is ApiErrorDetails
        ? (failure! as ApiErrorDetails).incidentId
        : null;
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.staffErrorNeverSyncedTitle,
        EteeloErrorType.unauthorized => l10n.staffErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.staffErrorForbiddenTitle,
        _ => l10n.staffErrorStorageTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.staffErrorNeverSynced,
        EteeloErrorType.unauthorized => l10n.staffErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.staffErrorForbidden,
        _ => l10n.staffErrorStorage,
      },
      primaryAction: switch (type) {
        EteeloErrorType.forbidden => null,
        EteeloErrorType.unauthorized =>
          onReconnect == null
              ? null
              : EteeloButton.primary(
                  label: l10n.staffErrorReconnect,
                  icon: Icons.login,
                  onPressed: onReconnect,
                  fullWidth: false,
                ),
        _ =>
          onRetry == null
              ? null
              : EteeloButton.primary(
                  label: l10n.staffErrorRetry,
                  icon: Icons.refresh,
                  onPressed: onRetry,
                  fullWidth: false,
                ),
      },
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incident != null &&
              incident.trim().isNotEmpty
          ? l10n.staffErrorIncidentCode(incident)
          : null,
    );
  }

  static EteeloErrorType typeOf(Failure? failure) => switch (failure) {
    NetworkFailure() => EteeloErrorType.network,
    InvalidCredentialsFailure() ||
    AuthFailure() => EteeloErrorType.unauthorized,
    UnauthorizedFailure() => EteeloErrorType.forbidden,
    ServerFailure() || StorageFailure() => EteeloErrorType.server,
    _ => EteeloErrorType.unknown,
  };
}
