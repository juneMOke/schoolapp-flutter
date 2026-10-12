import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Erreur d'une zone de résultats du module (règle n° 10) : une anatomie,
/// quatre tonalités. Le module est en ligne : réseau (Réessayer), 401 (se
/// reconnecter), 403 (contacter l'administrateur — jamais « Réessayer »),
/// 500 (Réessayer, avec le code d'incident).
class CommunicationResultsErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;

  const CommunicationResultsErrorState({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = EteeloErrorType.fromFailure(failure);
    final incident = failure is ApiErrorDetails
        ? (failure as ApiErrorDetails).incidentId
        : null;
    return EteeloErrorResult(
      type: type,
      title: switch (type) {
        EteeloErrorType.network => l10n.communicationErrorNetworkTitle,
        EteeloErrorType.unauthorized =>
          l10n.communicationErrorUnauthorizedTitle,
        EteeloErrorType.forbidden => l10n.communicationErrorForbiddenTitle,
        _ => l10n.communicationErrorServerTitle,
      },
      message: switch (type) {
        EteeloErrorType.network => l10n.communicationErrorNetwork,
        EteeloErrorType.unauthorized => l10n.communicationErrorUnauthorized,
        EteeloErrorType.forbidden => l10n.communicationErrorForbidden,
        _ => l10n.communicationErrorServer,
      },
      primaryAction: switch (type) {
        EteeloErrorType.forbidden => EteeloButton.secondary(
          label: l10n.communicationErrorContactAdmin,
          icon: Icons.mail_outline,
          onPressed: () =>
              launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail)),
          fullWidth: false,
        ),
        EteeloErrorType.unauthorized => EteeloButton.primary(
          label: l10n.communicationErrorReconnect,
          icon: Icons.login,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          fullWidth: false,
        ),
        _ => EteeloButton.primary(
          label: l10n.communicationRetry,
          icon: Icons.refresh,
          onPressed: onRetry,
          fullWidth: false,
        ),
      },
      incidentCodeLabel:
          type == EteeloErrorType.server &&
              incident != null &&
              incident.trim().isNotEmpty
          ? l10n.communicationErrorIncident(incident)
          : null,
    );
  }
}
